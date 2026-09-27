-- 의미 검색(PRD v2 §10 / MVP 2순위): 쿼리 -> 내 메모 벡터 검색.
-- 기존 스키마 불변. 신규 테이블 없음. 이미 있는 memo_embeddings 를 읽을 RPC 하나만 추가한다.
--
-- match_memos 와 헷갈리지 말 것.
--   match_memos                 메모 -> 메모   (별자리 연결 판정. 출발점이 저장된 메모)
--   search_memos_by_embedding   쿼리 -> 메모   (검색. 출발점이 방금 임베딩한 검색어)
--
-- 쿼리 임베딩은 서버만 만들 수 있다(VOYAGE_API_KEY). 그래서 이 함수의 호출자는
-- 항상 search-memos-semantic 엣지 함수(service_role)다. auth.uid() 를 쓸 수 없어
-- match_memos 와 같이 security definer + 명시적 p_user_id 로 간다.
create or replace function public.search_memos_by_embedding(
  p_user_id uuid,
  p_embedding public.vector(1024),
  p_k int default 20,
  p_threshold real default 0.5
) returns table(memo_id uuid, score real)
language sql stable security definer set search_path = '' as $$
  select me.memo_id,
         (1 - (me.embedding OPERATOR(public.<=>) p_embedding))::real
  from public.memo_embeddings me
  where me.user_id = p_user_id
    and (1 - (me.embedding OPERATOR(public.<=>) p_embedding)) >= p_threshold
  order by me.embedding OPERATOR(public.<=>) p_embedding
  limit p_k;
$$;

-- 남의 임베딩을 훔쳐볼 수 있는 함수라 클라이언트에 절대 열지 않는다.
-- p_user_id 를 인자로 받는 security definer 이므로 authenticated 에 열리면 곧 유출이다.
revoke execute on function public.search_memos_by_embedding(uuid, public.vector, int, real)
  from public, anon, authenticated;
grant execute on function public.search_memos_by_embedding(uuid, public.vector, int, real)
  to service_role;
