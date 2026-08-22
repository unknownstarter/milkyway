import { createClient } from 'npm:@supabase/supabase-js@2';

// 사유의 커넥톰 파이프라인: 메모 1개 -> 임베딩(Voyage) -> 유저 내 유사 메모 검색
// -> Lyra(Claude)가 관계 4종 분류 + 근거 -> memo_edges 저장.
// 클라이언트가 메모 저장 직후 fire-and-forget으로 호출. 결과를 기다리지 않음.

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const VOYAGE_API_KEY = Deno.env.get('VOYAGE_API_KEY');
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY');
const EMBED_MODEL = 'voyage-3';
const CLAUDE_MODEL = 'claude-opus-4-8';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
const ok = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { headers: { 'Content-Type': 'application/json' }, status: s });

async function sha256(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function embed(text: string): Promise<number[]> {
  const res = await fetch('https://api.voyageai.com/v1/embeddings', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${VOYAGE_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ input: [text], model: EMBED_MODEL, input_type: 'document' }),
  });
  if (!res.ok) throw new Error(`voyage ${res.status}: ${await res.text()}`);
  return (await res.json()).data[0].embedding;
}

// 유저 메모 수에 따른 동적 임계값(콜드스타트 완화)
function threshold(n: number): number {
  if (n < 10) return 0.55;
  if (n < 50) return 0.62;
  return 0.68;
}

const CLASSIFY_SYS = `너는 Lyra야. 한 사람이 쓴 두 독서 메모가 어떻게 이어지는지 딱 한 유형으로 분류하고, 왜 이어지는지 짧게 말해줘.
유형은 넷 중 하나:
- similar: 닮음(같은 결의 생각을 반복)
- extends: 확장(과거 생각을 지금 더 밀고 나감)
- reverses: 뒤집힘(과거의 자신과 반대되거나 반박)
- echo: 메아리(책/맥락은 다른데 밑바닥 정서가 같음)
각 쌍에서 a는 과거 메모, b는 지금 메모야. rationale은 과거에서 지금으로의 변화를 담아.
말투: 반말, 다정, 2문장 이내, 마지막에 물음 하나. '당신' 금지. 엠대시 엔대시 가운뎃점 곡선따옴표 말줄임표 금지. 이모지 0개나 1개.
출력은 JSON 배열만. 각 원소 {"pair_id": 정수, "rel_type": "similar|extends|reverses|echo", "rationale": "문장"}. 다른 말 없이 JSON만.`;

async function classify(pairs: { pair_id: number; a_text: string; b_text: string }[]) {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      system: CLASSIFY_SYS,
      messages: [{ role: 'user', content: `메모쌍들을 분류해:\n${JSON.stringify(pairs)}` }],
    }),
  });
  if (!res.ok) throw new Error(`anthropic ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const block = Array.isArray(data.content) ? data.content.find((b: any) => b.type === 'text') : null;
  let txt = (block?.text ?? '').trim();
  const s = txt.indexOf('['), e = txt.lastIndexOf(']');
  if (s >= 0 && e > s) txt = txt.slice(s, e + 1);
  try { return JSON.parse(txt) as { pair_id: number; rel_type: string; rationale: string }[]; }
  catch { return []; }
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return ok({ error: 'POST only' }, 405);
    if (!VOYAGE_API_KEY) return ok({ error: 'VOYAGE_API_KEY 미설정' }, 500);

    const { memo_id: memoId } = await req.json();
    if (!memoId || typeof memoId !== 'string') return ok({ error: 'memo_id 필요' }, 400);

    // 호출자 검증: 본인 메모만 처리(그리핑 방지). service role = 백필/관리자 바이패스.
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '');
    const isAdmin = token === SERVICE_KEY;
    let callerId: string | null = null;
    if (!isAdmin) {
      const { data: userData } = await supabase.auth.getUser(token);
      callerId = userData?.user?.id ?? null;
      if (!callerId) return ok({ error: '인증 필요' }, 401);
    }

    const { data: memo } = await supabase
      .from('memos').select('id, user_id, content').eq('id', memoId).single();
    if (!memo) return ok({ error: '메모 없음' }, 404);
    if (!isAdmin && memo.user_id !== callerId) return ok({ error: '권한 없음' }, 403);
    if (!memo.content || memo.content.trim().length < 4) return ok({ message: '내용 너무 짧음' });

    // 1) 임베딩 (동일 내용 이미 있으면 skip)
    const hash = await sha256(memo.content);
    const { data: existing } = await supabase
      .from('memo_embeddings').select('content_hash').eq('memo_id', memoId).maybeSingle();
    if (!existing || existing.content_hash !== hash) {
      const vec = await embed(memo.content);
      await supabase.from('memo_embeddings').upsert({
        memo_id: memoId, user_id: memo.user_id, embedding: `[${vec.join(',')}]`,
        model: EMBED_MODEL, dim: vec.length, content_hash: hash,
      });
    }

    // 2) 임계값 결정용 유저 메모 수
    const { count } = await supabase
      .from('memo_embeddings').select('memo_id', { count: 'exact', head: true })
      .eq('user_id', memo.user_id);

    // 3) 유사 후보 검색 (관대 구간은 상위 3개만)
    const k = (count ?? 0) < 10 ? 3 : 5;
    const { data: rawCands } = await supabase.rpc('match_memos', {
      p_memo_id: memoId, p_k: k, p_threshold: threshold(count ?? 0),
    });
    // 유사도 0.985 이상은 사실상 같은 메모(중복)라 연결에서 제외
    const cands = ((rawCands ?? []) as any[]).filter((c) => c.strength < 0.985);
    if (cands.length === 0) return ok({ message: '아직 이을 별이 없음', edges: 0 });

    // 후보 메모 내용
    const candIds = cands.map((c: any) => c.memo_b);
    const { data: candMemos } = await supabase
      .from('memos').select('id, content').in('id', candIds);
    const textById: Record<string, string> = {};
    (candMemos ?? []).forEach((m: any) => (textById[m.id] = m.content));

    // 4) Lyra 분류 (a=과거 후보, b=지금 메모)
    const pairs = cands.map((c: any, i: number) => ({
      pair_id: i, a_text: textById[c.memo_b] ?? '', b_text: memo.content,
    }));
    let classified: { pair_id: number; rel_type: string; rationale: string }[] = [];
    try { classified = await classify(pairs); } catch (_) { /* 분류 실패해도 선은 남김 */ }
    const byPair: Record<number, { rel_type: string; rationale: string }> = {};
    classified.forEach((c) => {
      if (['similar', 'extends', 'reverses', 'echo'].includes(c.rel_type)) {
        byPair[c.pair_id] = { rel_type: c.rel_type, rationale: c.rationale };
      }
    });

    // 5) 엣지 저장 (memo_a < memo_b 정규화, 중복은 무시)
    let created = 0;
    for (let i = 0; i < cands.length; i++) {
      const other = cands[i].memo_b as string;
      const [a, b] = [memoId, other].sort();
      const cls = byPair[i];
      const { error } = await supabase.from('memo_edges').upsert({
        user_id: memo.user_id, memo_a: a, memo_b: b,
        rel_type: cls?.rel_type ?? null, strength: cands[i].strength,
        rationale: cls?.rationale ?? null,
      }, { onConflict: 'memo_a,memo_b', ignoreDuplicates: true });
      if (!error) created++;
    }

    return ok({ success: true, edges: created });
  } catch (e) {
    console.error('connect-memo error:', e);
    return ok({ error: (e as Error).message }, 500);
  }
});
