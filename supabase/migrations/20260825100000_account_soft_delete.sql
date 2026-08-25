-- 탈퇴 30일 소프트딜리트 + 유예 내 복구 + 만료분 완전 purge.
-- ⚠️ 이 파일은 브랜치 리뷰/머지 후 프로덕션에 적용한다(직접 적용 금지).

-- 1) 소프트 삭제 표시
alter table public.users add column if not exists deleted_at timestamptz;
create index if not exists idx_users_deleted_at on public.users(deleted_at) where deleted_at is not null;

-- 2) 본인 계정 소프트 삭제(재로그인 복구 가능하게 데이터는 보존, 표시만 숨김)
create or replace function public.soft_delete_account()
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.users set deleted_at = now(), updated_at = now()
    where id = auth.uid() and deleted_at is null;
end; $$;
grant execute on function public.soft_delete_account() to authenticated;

-- 3) 재로그인 시 복구(유예 내면 삭제 취소). 인스타/디스코드식: 로그인=복구.
create or replace function public.restore_account()
returns boolean language plpgsql security definer set search_path = public as $$
declare cnt int;
begin
  update public.users set deleted_at = null, updated_at = now()
    where id = auth.uid() and deleted_at is not null;
  get diagnostics cnt = row_count;
  return cnt > 0;
end; $$;
grant execute on function public.restore_account() to authenticated;

-- 4) 30일 지난 소프트삭제 계정 완전 삭제(스케줄러가 호출). memos/user_books는 NO ACTION이라
--    수동 삭제, 나머지는 CASCADE. auth.users까지 제거해 재가입 재부착 원천 차단.
create or replace function public.purge_expired_deleted_accounts()
returns integer language plpgsql security definer set search_path = public as $$
declare uid uuid; n int := 0;
begin
  for uid in select id from public.users
             where deleted_at is not null and deleted_at < now() - interval '30 days' loop
    delete from public.memos where user_id = uid;
    delete from public.user_books where user_id = uid;
    begin
      -- 프로필 이미지 경로는 항상 uid 로 시작(<uid>/... 또는 <uid>_...). 접두 매칭으로
      -- 오삭제 방지 + 인덱스 친화(양쪽 와일드카드 %uid% 금지).
      delete from storage.objects where bucket_id = 'profile_images'
        and name like uid::text || '%';
    exception when others then null; -- 스토리지 정리는 best-effort
    end;
    delete from public.users where id = uid;   -- comments/embeddings 등 CASCADE
    delete from auth.users where id = uid;      -- auth 세션/identity CASCADE
    n := n + 1;
  end loop;
  return n;
end; $$;

-- 4-1) 콘텐츠 숨김의 단일 지점: 소프트삭제 유저의 공개 메모를 memos RLS에서 제외.
--     edge function(service_role)은 RLS 우회라 JS 필터로 별도 처리(belt-and-suspenders),
--     여기선 클라이언트 직접 읽기(getBookMemos·discovery 카운트 등) 전부를 한 번에 막는다.
create or replace function public.is_user_active(uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.users where id = uid and deleted_at is not null);
$$;
grant execute on function public.is_user_active(uuid) to authenticated, anon;

-- 기존 정책의 USING 만 교체(DROP 없이 원자적). 본인 메모는 그대로, 공개 메모는 활성 작성자만.
alter policy "사용자는 자신의 메모와 공개 메모를 볼 수 있" on public.memos
  using (
    (auth.uid() = user_id)
    or (visibility = 'public'::visibility_type and public.is_user_active(user_id))
  );

-- 4-2) 카드 댓글수: 숨김 + 소프트삭제 작성자 제외(목록 기준과 일치). service/client 무관하게
--      동일 결과가 나오도록 security definer.
create or replace function public.comment_count(m memos)
returns bigint language sql stable security definer set search_path = public as $$
  select count(*)::bigint
  from public.comments c
  join public.users u on u.id = c.user_id
  where c.memo_id = m.id and c.is_hidden = false and u.deleted_at is null;
$$;

-- 5) 댓글 조회 RPC: 숨김 + 소프트삭제 작성자 제외(유예 중 콘텐츠 숨김)
--    ⚠️ 이 파일이 get_memo_comments 최종 정의(is_hidden + deleted_at). 090000의 정의를 대체.
create or replace function public.get_memo_comments(p_memo_id uuid)
returns setof jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', c.id,
    'memo_id', c.memo_id,
    'user_id', c.user_id,
    'content', c.content,
    'created_at', c.created_at,
    'updated_at', c.updated_at,
    'users', jsonb_build_object('nickname', u.nickname, 'picture_url', u.picture_url)
  )
  from public.comments c
  join public.users u on u.id = c.user_id
  where c.memo_id = p_memo_id and c.is_hidden = false and u.deleted_at is null
  order by c.created_at asc;
$$;

-- 6) 만료 계정 자동 purge 스케줄(pg_cron). 확장 미설치 환경이면 이 블록은 실패할 수 있으니
--    별도 적용/대시보드 설정. 매일 03:00 KST(18:00 UTC) 실행.
-- create extension if not exists pg_cron;
-- select cron.schedule('purge-expired-accounts', '0 18 * * *',
--   $$select public.purge_expired_deleted_accounts()$$);

-- ─────────────────────────────────────────────────────────────
-- ROLLBACK (수동 적용용. Supabase는 forward-only라 자동 down 없음)
-- ─────────────────────────────────────────────────────────────
-- alter policy "사용자는 자신의 메모와 공개 메모를 볼 수 있" on public.memos
--   using ((auth.uid() = user_id) or (visibility = 'public'::visibility_type));
-- create or replace function public.comment_count(m memos) returns bigint
--   language sql stable set search_path to '' as $$
--   select count(*)::bigint from public.comments c where c.memo_id = m.id and c.is_hidden = false; $$;
-- create or replace function public.get_memo_comments(p_memo_id uuid) returns setof jsonb
--   language sql stable security definer set search_path = public as $$
--   select jsonb_build_object('id',c.id,'memo_id',c.memo_id,'user_id',c.user_id,'content',c.content,
--     'created_at',c.created_at,'updated_at',c.updated_at,
--     'users',jsonb_build_object('nickname',u.nickname,'picture_url',u.picture_url))
--   from public.comments c join public.users u on u.id=c.user_id
--   where c.memo_id=p_memo_id and c.is_hidden=false order by c.created_at asc; $$;
-- drop function if exists public.is_user_active(uuid);
-- drop function if exists public.soft_delete_account();
-- drop function if exists public.restore_account();
-- drop function if exists public.purge_expired_deleted_accounts();
-- drop index if exists public.idx_users_deleted_at;
-- alter table public.users drop column if exists deleted_at;
