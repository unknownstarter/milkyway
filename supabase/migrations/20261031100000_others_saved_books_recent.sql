-- 홈 "다른 사람이 담은 책" 을 이름 그대로 만든다 (2026-10-31).
--
-- 전에는 전체 기간 담은 사람 수 순 상위 12권이라, 다른 사람이 새로 담은 책 (담은 사람 1명) 은
-- 절대 순위에 못 들었다. 부르는 사람 자신이 담은 것도 같이 셌다.
-- 이제 부른 사람을 뺀 다른 사람이 마지막으로 담은 시각 순이다. 탈퇴한 사람의 담기는 세지 않는다.
-- 반환 모양은 그대로라 앱 배포 없이 바뀐다. 부르는 곳은 홈 한 곳 (DiscoveryRepository.getBooksSavedByOthers).

create or replace function public.get_recommended_books(p_limit int default 12)
returns table (
  id uuid,
  title text,
  author text,
  cover_url text,
  savers_count bigint,
  public_memo_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    b.id,
    b.title,
    b.author,
    b.cover_url,
    count(distinct ub.user_id) as savers_count,
    (select count(*) from memos m where m.book_id = b.id and m.visibility = 'public') as public_memo_count
  from books b
  join user_books ub on ub.book_id = b.id
  join users u on u.id = ub.user_id and u.deleted_at is null
  where auth.uid() is null or ub.user_id <> auth.uid()
  group by b.id
  order by max(ub.created_at) desc, count(distinct ub.user_id) desc
  limit p_limit;
$$;

grant execute on function public.get_recommended_books(int) to authenticated;
