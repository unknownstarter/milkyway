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
// 임계값. connect-memo 의 연결 임계값(0.55~0.68)보다 낮게 잡는다. 연결은 단언이고
// 검색은 후보 제시라 회수율을 더 사도 된다.
//
// 0.5 는 아직 측정으로 뒷받침된 값이 아니다. 실측(2026-09-27)에서 닮은 한국어 메모쌍이
// 0.51~0.52 에 몰려 있어 이 근처를 잡았을 뿐이고, 그건 document 임베딩끼리 비교한
// 값이라 query 임베딩의 분포와 다를 수 있다. 재배포 없이 돌려볼 수 있게 환경변수로 뺀다.
const THRESHOLD = Number(Deno.env.get('SEMANTIC_THRESHOLD')) || 0.5;
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
