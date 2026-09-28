import { createClient } from 'npm:@supabase/supabase-js@2';

// 의미 검색(PRD v2 §10 / MVP 2순위): 검색어 -> Voyage 쿼리 임베딩 -> 내 메모 벡터 검색.
// LLM 호출 없음. 메모 쪽 임베딩은 connect-memo 가 저장 시점에 이미 만들어 둔 것을 읽는다.
//
// 엣지 함수를 경유하는 이유는 하나다. VOYAGE_API_KEY 는 서버에만 둔다.
// 클라이언트가 임베딩을 만들면 키가 앱 번들에 실린다.
//
// 모델은 connect-memo 와 반드시 같아야 한다(voyage-3 / 1024차원).
// 다르면 좌표계가 달라져 유사도 점수가 조용히 무의미해진다. 에러도 안 난다.
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const VOYAGE_API_KEY = Deno.env.get('VOYAGE_API_KEY');
const EMBED_MODEL = 'voyage-3';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;
// 임계값. 실제 쿼리로 측정해서 정했다(2026-09-29).
//
// 메모 "생각해보니까 없음에서 나오는 불안감이 더 컸네" 에 대고 검색어를 바꿔가며 잰 점수:
//   없는 게 더 무서웠다  0.598   결핍이 주는 두려움  0.497
//   불안감              0.459   마음이 불안하다     0.451
//   돈 걱정             0.323   행복  0.268   부와 행운  0.234
// 무관한 메모("어쩌고 저쩌고")는 어떤 검색어에도 최대 0.354.
// 관련 최저 0.451 과 무관 최고 0.354 사이가 비어 있어 그 사이를 잡는다.
//
// 처음엔 0.5 로 뒀다가 갈아엎었다. 0.5 는 메모끼리(document-document) 비교한 분포에서
// 뽑은 값이라 쿼리에는 안 맞았다. 짧은 검색어는 긴 문서와의 코사인이 원래 낮아서,
// 0.5 에서는 메모를 통째로 쳐야만 걸렸다. 검색어 쪽(input_type='query') 점수대가
// 문서끼리보다 0.1 쯤 아래에 있다는 뜻이다.
//
// 표본이 메모 1개 / 검색어 7개다. 메모가 많은 계정에서 다시 재볼 것.
// 재배포 없이 돌려볼 수 있게 환경변수로 뺀다.
const THRESHOLD = Number(Deno.env.get('SEMANTIC_THRESHOLD')) || 0.42;
const MAX_QUERY_CHARS = 500;

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
const ok = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { headers: { 'Content-Type': 'application/json' }, status: s });

const MEMO_SELECT = `
  *,
  comment_count,
  lyra_question,
  books (
    id,
    title,
    author,
    cover_url
  ),
  users!user_id (
    nickname,
    picture_url
  )
`;

async function embedQuery(text: string): Promise<number[]> {
  const res = await fetch('https://api.voyageai.com/v1/embeddings', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${VOYAGE_API_KEY}`, 'Content-Type': 'application/json' },
    // input_type 이 'document' 가 아니라 'query' 다. voyage 는 비대칭 임베딩이라
    // 검색어를 document 로 넣으면 회수율이 떨어진다.
    body: JSON.stringify({ input: [text], model: EMBED_MODEL, input_type: 'query' }),
  });
  if (!res.ok) throw new Error(`voyage ${res.status}: ${await res.text()}`);
  return (await res.json()).data[0].embedding;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return ok({ error: 'POST only' }, 405);
    if (!VOYAGE_API_KEY) return ok({ error: 'VOYAGE_API_KEY 미설정' }, 500);

    const body = await req.json().catch(() => ({}));
    const raw = typeof body.query === 'string' ? body.query.trim() : '';
    if (!raw) return ok({ error: 'query 필요' }, 400);
    const query = raw.slice(0, MAX_QUERY_CHARS);
    const limit = Math.min(Math.max(Number(body.limit) || DEFAULT_LIMIT, 1), MAX_LIMIT);

    // 본인 메모만 검색한다. p_user_id 를 클라이언트가 보내게 하면 남의 메모가 열린다.
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '');
    const { data: userData } = await supabase.auth.getUser(token);
    const userId = userData?.user?.id ?? null;
    if (!userId) return ok({ error: '인증 필요' }, 401);

    const embedding = await embedQuery(query);

    const { data: hits, error: rpcError } = await supabase.rpc('search_memos_by_embedding', {
      p_user_id: userId,
      p_embedding: `[${embedding.join(',')}]`,
      p_k: limit,
      p_threshold: THRESHOLD,
    });
    if (rpcError) {
      console.error('벡터 검색 실패:', rpcError);
      return ok({ error: rpcError.message }, 500);
    }

    const ranked = (hits ?? []) as { memo_id: string; score: number }[];
    if (ranked.length === 0) return ok({ memos: [], model: EMBED_MODEL });

    // memo_embeddings 는 사이드카라 본문이 없다. 메모를 따로 채워 온다.
    // user_id 를 한 번 더 거는 건 중복이 아니라 방어다(RPC 가 바뀌어도 남이 안 샌다).
    const { data: memos, error: memoError } = await supabase
      .from('memos')
      .select(MEMO_SELECT)
      .eq('user_id', userId)
      .in('id', ranked.map((r) => r.memo_id));
    if (memoError) {
      console.error('메모 조회 실패:', memoError);
      return ok({ error: memoError.message }, 500);
    }

    // in() 은 순서를 보장하지 않는다. 유사도 순서를 여기서 되살린다.
    // 이 순서가 검색 결과의 전부이므로 클라이언트에서 다시 정렬하지 않는다.
    const byId = new Map((memos ?? []).map((m: { id: string }) => [m.id, m]));
    const ordered = ranked
      .map((r) => {
        const memo = byId.get(r.memo_id);
        return memo ? { ...memo, similarity: r.score } : null;
      })
      .filter((m) => m !== null);

    return ok({ memos: ordered, model: EMBED_MODEL });
  } catch (e) {
    console.error('의미 검색 중 오류:', e);
    return ok({ error: String(e) }, 500);
  }
});
