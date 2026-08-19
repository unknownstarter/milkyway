import { createClient } from 'npm:@supabase/supabase-js@2';

// N3 Lyra 물음 엔진
// 책 소개를 바탕으로 사유 확장 물음 1개를 생성 -> book_questions에 저장.
// verify_jwt=false로 배포하고 Authorization 헤더로 자체 인가한다.
//   - service role 키: 전체/재생성 포함 모든 작업
//   - 인증 사용자 JWT: 단일 book_id 생성만(신규 책 등록 직후 클라이언트가 호출)
//   POST { book_id }            -> 해당 책 1권 (활성 물음 있으면 skip)
//   POST { all: true }          -> 활성 물음 없는 책 전부 (service role 전용)
//   POST { book_id, regenerate } -> 재생성 (service role 전용)

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const MODEL = 'claude-opus-4-8';

// AI 금지 기호: em/en dash, 중간점, 말줄임표. (곡선따옴표는 아래서 곧은 따옴표로 치환)
const FORBIDDEN = /[—–·…]/;

const SYSTEM_PROMPT = `너는 Lyra야. 독서 메모 앱에서 책 한 권을 읽는 사람에게 사유를 넓혀줄 물음 하나를 건네는 친구 같은 존재야.

말투와 규칙:
- 반말로. 다정한 친구가 곁에서 툭 건네듯이. 고상한 척, 철학자인 척, 겉멋 금지.
- 결은 따뜻하고 진중하게. 가끔 가볍게 툭 던져도 좋지만 남발하지 마.
- 2~4문장. 마지막 문장이 물음 하나. 물음은 딱 하나만.
- 책 소개에 실제로 나온 내용에만 근거해서 물어. 없는 내용 지어내지 마.
- 빈 칭찬이나 교훈 설교 금지. 정답을 요구하지 말고 자기 삶을 돌아보게 하는 열린 물음.
- 이모지는 0개나 1개까지만. 남발 금지. 느낌표는 되도록 쓰지 마.
- '당신'이라는 호칭 절대 금지.
- 다음 기호 절대 쓰지 마: 엠대시, 엔대시, 가운뎃점, 말줄임표(...). 따옴표는 곧은 따옴표만.
- 물음 텍스트만 출력해. 다른 설명, 머리말, 따옴표 감싸기 없이.`;

interface BookRow {
  id: string;
  title: string;
  author: string;
  description: string | null;
}

function buildUserPrompt(book: BookRow): string {
  const desc = (book.description ?? '').trim();
  return [
    `책 제목: ${book.title}`,
    `저자: ${book.author}`,
    desc ? `책 소개: ${desc}` : `책 소개: (제공되지 않음. 제목과 저자만으로 물어. 무리면 일반적인 독서 물음으로.)`,
    '',
    '이 책을 지금 막 담은 사람에게 건넬 물음 하나를 위 규칙대로 써줘.',
  ].join('\n');
}

// 곡선따옴표 -> 곧은따옴표 치환(안전). 나머지 금지기호는 치환하지 않고 검증에서 걸러 재생성.
function sanitize(text: string): string {
  return text
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .trim();
}

function validate(text: string): { ok: boolean; reason?: string } {
  if (!text || text.length < 15) return { ok: false, reason: 'too_short' };
  if (text.length > 400) return { ok: false, reason: 'too_long' };
  if (FORBIDDEN.test(text)) return { ok: false, reason: 'forbidden_symbol' };
  if (text.includes('당신')) return { ok: false, reason: 'forbidden_word_dangsin' };
  return { ok: true };
}

async function callAnthropic(book: BookRow): Promise<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 400,
      temperature: 1.0,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: buildUserPrompt(book) }],
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Anthropic API 실패 (${res.status}): ${err}`);
  }
  const data = await res.json();
  const block = Array.isArray(data.content)
    ? data.content.find((b: { type: string }) => b.type === 'text')
    : null;
  return sanitize(block?.text ?? '');
}

// 물음 1개 생성 + 검증(실패 시 1회 재생성). 성공 시 텍스트, 실패 시 null.
async function generateQuestion(book: BookRow): Promise<string | null> {
  for (let attempt = 0; attempt < 2; attempt++) {
    let text: string;
    try {
      text = await callAnthropic(book);
    } catch (_e) {
      continue; // 호출 실패 -> 재시도
    }
    if (validate(text).ok) return text;
  }
  return null;
}

async function processBook(
  book: BookRow,
  regenerate: boolean,
): Promise<{ book_id: string; ok: boolean; reason?: string }> {
  // 이미 활성 물음이 있으면 skip (regenerate 아니면)
  const { data: existing } = await supabase
    .from('book_questions')
    .select('id')
    .eq('book_id', book.id)
    .eq('is_active', true)
    .maybeSingle();

  if (existing && !regenerate) {
    return { book_id: book.id, ok: true, reason: 'already_exists' };
  }
  if (!ANTHROPIC_API_KEY) {
    return { book_id: book.id, ok: false, reason: 'no_api_key' };
  }

  const question = await generateQuestion(book);
  if (!question) {
    return { book_id: book.id, ok: false, reason: 'generation_failed' };
  }

  if (existing && regenerate) {
    await supabase
      .from('book_questions')
      .update({ is_active: false })
      .eq('book_id', book.id)
      .eq('is_active', true);
  }

  const { error } = await supabase.from('book_questions').insert({
    book_id: book.id,
    question,
    model: MODEL,
    is_active: true,
  });
  if (error) {
    return { book_id: book.id, ok: false, reason: `insert_error: ${error.message}` };
  }
  return { book_id: book.id, ok: true };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return json({ error: 'POST 요청만 허용됩니다.' }, 405);
    }

    // 인가: service role = 전체 권한, 인증 사용자 = 단일 book_id 생성만.
    const auth = req.headers.get('Authorization') ?? '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    const isAdmin = token !== '' && token === SUPABASE_SERVICE_ROLE_KEY;

    if (!isAdmin) {
      const { data: userData } = await supabase.auth.getUser(token);
      if (!userData?.user) {
        return json({ error: '권한이 없습니다.' }, 401);
      }
    }

    const body = await req.json().catch(() => ({}));
    // 재생성은 관리자만.
    const regenerate = isAdmin && body.regenerate === true;

    let books: BookRow[] = [];
    if (body.all === true) {
      if (!isAdmin) return json({ error: '전체 생성은 관리자만 가능합니다.' }, 403);
      const { data, error } = await supabase
        .from('books')
        .select('id, title, author, description');
      if (error) return json({ error: error.message }, 500);
      books = data ?? [];
    } else if (body.book_id) {
      const { data, error } = await supabase
        .from('books')
        .select('id, title, author, description')
        .eq('id', body.book_id)
        .maybeSingle();
      if (error) return json({ error: error.message }, 500);
      if (!data) return json({ error: '책을 찾을 수 없습니다.' }, 404);
      books = [data];
    } else {
      return json({ error: 'book_id 또는 all 이 필요합니다.' }, 400);
    }

    const results = [];
    for (const book of books) {
      results.push(await processBook(book, regenerate));
    }

    const generated = results.filter((r) => r.ok && !r.reason).length;
    return json({ total: books.length, generated, results });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });
}
