-- 첫 선 인라인 리빌: memo_edges insert를 Realtime으로 구독(RLS로 본인 것만 수신)
alter publication supabase_realtime add table public.memo_edges;
