-- 홈 "다른 사람이 담은 책" + 사회적 증거(N명이 담음).
-- user_books/memos는 RLS상 본인 것만 보여 클라에서 savers를 셀 수 없다.
-- SECURITY DEFINER로 RLS를 우회해 집계만 안전하게 반환한다(개별 행 노출 없음).
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
    count(distinct m.id) filter (where m.visibility = 'public') as public_memo_count
  from books b
  join user_books ub on ub.book_id = b.id
  left join memos m on m.book_id = b.id
  group by b.id
  order by savers_count desc, public_memo_count desc, b.created_at desc
  limit p_limit;
$$;

grant execute on function public.get_recommended_books(int) to authenticated;
