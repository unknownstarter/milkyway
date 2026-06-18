-- Migration: Add RPC to fetch user books ordered by last memo activity
-- Description: Returns the user's books sorted by most recent memo creation time.
--              Books without memos fall back to user_books.created_at and appear
--              after books that have memos. Used by the Home screen only.
-- Date: 2026-05-29

CREATE OR REPLACE FUNCTION public.get_home_books_by_last_activity(p_user_id uuid)
RETURNS TABLE (
  id          uuid,
  title       text,
  author      text,
  isbn        text,
  cover_url   text,
  description text,
  publisher   text,
  pubdate     text,
  status      text,
  created_at  timestamptz,
  updated_at  timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    b.id,
    b.title,
    b.author,
    b.isbn,
    b.cover_url,
    b.description,
    b.publisher,
    b.pubdate,
    ub.status,
    b.created_at,
    b.updated_at
  FROM public.user_books ub
  JOIN public.books b ON b.id = ub.book_id
  LEFT JOIN LATERAL (
    SELECT MAX(m.created_at) AS last_memo_at
    FROM public.memos m
    WHERE m.book_id = b.id
      AND m.user_id = p_user_id
  ) latest ON true
  WHERE ub.user_id = p_user_id
  ORDER BY
    latest.last_memo_at DESC NULLS LAST,
    ub.created_at DESC;
$$;

-- Allow authenticated users to invoke the function. RLS on the underlying
-- user_books / memos / books tables still applies because we use SECURITY INVOKER.
GRANT EXECUTE ON FUNCTION public.get_home_books_by_last_activity(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_home_books_by_last_activity(uuid) IS
  'Returns the caller''s books sorted by the most recent memo activity. Books without memos are placed after books with memos, ordered by user_books.created_at. Used by the Home screen only.';
