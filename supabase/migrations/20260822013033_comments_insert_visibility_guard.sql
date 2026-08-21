-- 권한 보강: 댓글은 공개 메모 또는 내 메모에만.
-- (기존 comments_insert는 책 저장만 검사해 남의 '비공개' 메모에도 댓글이 달렸음)
drop policy if exists "comments_insert" on public.comments;
create policy "comments_insert" on public.comments for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.memos m
    join public.user_books ub on ub.book_id = m.book_id
    where m.id = comments.memo_id
      and ub.user_id = auth.uid()
      and (m.visibility = 'public' or m.user_id = auth.uid())
  )
);
