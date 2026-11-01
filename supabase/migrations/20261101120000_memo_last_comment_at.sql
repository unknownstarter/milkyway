-- 메모 카드 새 댓글 표시용 computed field.
--   last_comment_at(memos) = 메모 주인이 아닌 사람이 단 댓글 중 가장 늦은 created_at.
--   숨김/소프트삭제 작성자 제외 기준과 security definer 는 comment_count(memos) 와 동일
--   (20260825100000_account_soft_delete.sql). 기존 테이블 변경 없음.
--   PostgREST select 에서 `last_comment_at` 으로 고른다. 클라이언트는 seen_state(scope='memo')
--   의 본 시각과 비교해 점을 켠다.
create or replace function public.last_comment_at(m memos)
returns timestamptz language sql stable security definer set search_path = public as $$
  select max(c.created_at)
  from public.comments c
  join public.users u on u.id = c.user_id
  where c.memo_id = m.id
    and c.user_id <> m.user_id
    and c.is_hidden = false
    and u.deleted_at is null;
$$;

-- ROLLBACK (수동): drop function public.last_comment_at(memos);
