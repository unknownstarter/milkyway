-- Memos 탭 하단 네비 빨간 점용: 내 관점에서 "새로운 상호작용" 최신 시각.
--  feed_last_at    = 타 유저의 마지막 공개 메모 시각(피드에 새 공개 메모)
--  comment_last_at = 내 메모에 달린 타 유저의 마지막 댓글 시각
-- 클라이언트가 max(둘) > lastSeen(memos 탭) 이면 점 표시. (좋아요는 미구현 - 생기면 추가)
-- SECURITY INVOKER: memos/comments RLS 적용(공개 메모/내 메모 댓글만 읽힘).

CREATE OR REPLACE FUNCTION public.get_memos_badge_activity(p_user_id uuid)
RETURNS TABLE (
  feed_last_at    timestamptz,
  comment_last_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    (SELECT MAX(m.created_at)
       FROM public.memos m
      WHERE m.user_id <> p_user_id
        AND m.visibility = 'public') AS feed_last_at,
    (SELECT MAX(c.created_at)
       FROM public.comments c
       JOIN public.memos m ON m.id = c.memo_id
      WHERE m.user_id = p_user_id
        AND c.user_id <> p_user_id) AS comment_last_at;
$$;

GRANT EXECUTE ON FUNCTION public.get_memos_badge_activity(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_memos_badge_activity(uuid) IS
  'Memos tab badge activity: latest others-public-memo time and latest comment-on-my-memos time. Client compares max vs local last-seen.';
