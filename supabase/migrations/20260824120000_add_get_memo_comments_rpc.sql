-- 댓글 목록을 작성자 공개필드(nickname, picture_url)와 함께 반환.
-- users RLS(auth.uid()=id, 본인 행만)로 클라이언트 조인이 남의 댓글 작성자를 못 읽어
-- 현재 유저로 폴백되던 버그 해결(남의 댓글이 전부 내 이름/사진으로 보이던 문제).
-- SECURITY DEFINER지만 공개 표시용 필드만 노출(email/fcm_token 등 미포함).
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
  where c.memo_id = p_memo_id
  order by c.created_at asc;
$$;

grant execute on function public.get_memo_comments(uuid) to authenticated;
