-- 댓글 누적 신고 임계치 자동 숨김.
-- 서로 다른 신고자 3명 이상이면 전체에서 숨김(is_hidden). 조회 RPC/카운트에서 제외.
-- (개인 숨김 user_hidden_comments 는 별개로 유지 - 신고자 본인 즉시 숨김용)

-- 1) 전체 숨김 플래그
alter table public.comments add column if not exists is_hidden boolean not null default false;

-- 2) 신고 누적 트리거: comment_reports 는 (comment_id,reporter_id) 유니크라 행수=고유 신고자수
create or replace function public.hide_comment_on_reports()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select count(*) from public.comment_reports r where r.comment_id = new.comment_id) >= 3 then
    update public.comments set is_hidden = true
      where id = new.comment_id and is_hidden = false;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_hide_comment_on_reports on public.comment_reports;
create trigger trg_hide_comment_on_reports
  after insert on public.comment_reports
  for each row execute function public.hide_comment_on_reports();

-- 3) 카드 댓글수: 숨김 제외
create or replace function public.comment_count(m memos)
returns bigint language sql stable set search_path to '' as $$
  select count(*)::bigint from public.comments c
  where c.memo_id = m.id and c.is_hidden = false;
$$;

-- 4) 댓글 조회 RPC: 숨김 제외
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
  where c.memo_id = p_memo_id and c.is_hidden = false
  order by c.created_at asc;
$$;
