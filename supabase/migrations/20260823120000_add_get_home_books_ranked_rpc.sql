-- 홈 스토리 원 랭킹용 RPC.
-- 기존 get_home_books_by_last_activity 를 확장: 책별로
--  (1) 내 마지막 메모 시각(my_last_memo_at)
--  (2) 남(타 유저)의 마지막 "공개" 메모 시각(others_last_public_memo_at)
-- 둘 다 반환. 최종 순서/링(안 봤음 판정)은 클라이언트가 로컬 '마지막 본 시각'으로 결정.
-- SECURITY INVOKER: memos RLS(공개 메모 or 본인) 적용 → 남의 공개 메모만 읽힘, 숨김 메모 제외.

CREATE OR REPLACE FUNCTION public.get_home_books_ranked(p_user_id uuid)
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
  updated_at  timestamptz,
  my_last_memo_at            timestamptz,
  others_last_public_memo_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    b.id, b.title, b.author, b.isbn, b.cover_url, b.description,
    b.publisher, b.pubdate, ub.status, b.created_at, b.updated_at,
    mine.last_at   AS my_last_memo_at,
    others.last_at AS others_last_public_memo_at
  FROM public.user_books ub
  JOIN public.books b ON b.id = ub.book_id
  LEFT JOIN LATERAL (
    SELECT MAX(m.created_at) AS last_at
    FROM public.memos m
    WHERE m.book_id = b.id AND m.user_id = p_user_id
  ) mine ON true
  LEFT JOIN LATERAL (
    SELECT MAX(m.created_at) AS last_at
    FROM public.memos m
    WHERE m.book_id = b.id
      AND m.user_id <> p_user_id
      AND m.visibility = 'public'
  ) others ON true
  WHERE ub.user_id = p_user_id
  ORDER BY
    mine.last_at   DESC NULLS LAST,
    others.last_at DESC NULLS LAST,
    ub.created_at  DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_home_books_ranked(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_home_books_ranked(uuid) IS
  'Home story-circle ranking. Returns caller books with my_last_memo_at and others_last_public_memo_at. Client decides final order/ring using local last-viewed.';
