import { createClient } from 'npm:@supabase/supabase-js@2';

// Lyra 물음 다국어화
// 한국어 정본(book_questions / general_questions)을 en/ja/zh로 옮겨 question_translations에 캐시.
// 번역은 1회만 하고 영구 캐시. 재번역(force)은 service role 전용.
//   POST { all: true, langs?: [..] }                 -> 미번역 전부 (service role 전용)
//   POST { source, question_id, lang }               -> 1건 온디맨드 (인증 사용자도 가능)
//   POST { all: true, force: true }                  -> 전량 재번역 (service role 전용)

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// 번역은 기계적 작업이라 저비용 모델로 충분. 결과는 영구 캐시라 재호출도 없다.
const MODEL = 'claude-haiku-4-5';

const LANGS = ['en', 'ja', 'zh'] as const;
type Lang = (typeof LANGS)[number];

// AI 금지 기호: em/en dash, 중간점, 말줄임표. (곡선따옴표는 곧은 따옴표로 치환)
const FORBIDDEN = /[—–·…]/;

const LANG_GUIDE: Record<Lang, string> = {
  en: [
    'Target language: English.',
    "Voice: a close friend speaking casually. Warm and grounded, never lofty or preachy.",
    "Address the reader as 'you'. Contractions are fine.",
  ].join('\n'),
  ja: [
    'Target language: Japanese.',
    '親しい友だちが隣でふと問いかけるような、やわらかいタメ口で。上から目線や説教は禁止。',
    "「あなた」という呼びかけは使わないこと(距離が出る)。呼びかけは「きみ」か、主語を省く。",
  ].join('\n'),
  zh: [
    'Target language: Simplified Chinese.',
    '语气像亲近的朋友随口一问，温和真诚，不要说教、不要文绉绉。',
    "称呼用「你」。",
  ].join('\n'),
};

const SYSTEM_PROMPT = `You localize a single reflective question from a reading app.

The speaker is Lyra: a friend who hands the reader one question that widens their thinking. Not a teacher, not a philosopher.

Rules:
- Transcreate, do not translate literally. Keep the meaning and the warmth; let the wording be natural in the target language.
- Keep the same shape: 2 to 4 sentences, and the last sentence is the one question. Exactly one question.
- Do not add content that is not in the source. Do not add advice, praise, or a lesson.
- Keep at most one emoji, and only if the source has one. Avoid exclamation marks.
- Never use these characters: em dash, en dash, middle dot, ellipsis character. Use straight quotes only.
- Output only the localized question text. No preamble, no quotes around it, no notes.`;

interface Row {
  source: 'book' | 'general';
  question_id: string;
  question: string;
}

function sanitize(text: string): string {
  return text
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .trim();
}

function validate(text: string, lang: Lang): { ok: boolean; reason?: string } {
  if (!text || text.length < 8) return { ok: false, reason: 'too_short' };
  if (text.length > 600) return { ok: false, reason: 'too_long' };
  if (FORBIDDEN.test(text)) return { ok: false, reason: 'forbidden_symbol' };
  // 일본어는 'あなた'가 한국어 '당신'과 같은 거리감을 만든다.
  if (lang === 'ja' && text.includes('あなた')) {
    return { ok: false, reason: 'forbidden_word_anata' };
  }
  // 번역이 안 되고 한국어가 그대로 남은 경우 방지.
  if (/[가-힣]/.test(text)) return { ok: false, reason: 'untranslated_korean' };
  return { ok: true };
}

async function callAnthropic(question: string, lang: Lang): Promise<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 1000,
      temperature: 1.0,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: `${LANG_GUIDE[lang]}\n\nSource (Korean):\n${question}`,
        },
      ],
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

// 번역 1건 + 검증(실패 시 1회 재시도). 성공 시 텍스트, 실패 시 null.
async function translate(question: string, lang: Lang): Promise<string | null> {
  for (let attempt = 0; attempt < 2; attempt++) {
    let text: string;
    try {
      text = await callAnthropic(question, lang);
    } catch (_e) {
      continue;
    }
    if (validate(text, lang).ok) return text;
  }
  return null;
}

async function processOne(
  row: Row,
  lang: Lang,
  force: boolean,
): Promise<{ question_id: string; lang: string; ok: boolean; reason?: string }> {
  const { data: existing } = await supabase
    .from('question_translations')
    .select('id')
    .eq('source', row.source)
    .eq('question_id', row.question_id)
    .eq('lang', lang)
    .maybeSingle();

  if (existing && !force) {
    return { question_id: row.question_id, lang, ok: true, reason: 'already_exists' };
  }
  if (!ANTHROPIC_API_KEY) {
    return { question_id: row.question_id, lang, ok: false, reason: 'no_api_key' };
  }

  const text = await translate(row.question, lang);
  if (!text) {
    return { question_id: row.question_id, lang, ok: false, reason: 'translation_failed' };
  }

  const { error } = await supabase
    .from('question_translations')
    .upsert(
      {
        source: row.source,
        question_id: row.question_id,
        lang,
        question: text,
        model: MODEL,
      },
      { onConflict: 'source,question_id,lang' },
    );
  if (error) {
    return { question_id: row.question_id, lang, ok: false, reason: `insert_error: ${error.message}` };
  }
  return { question_id: row.question_id, lang, ok: true };
}

// 정본 목록(책 물음 + 일반 물음).
async function loadSources(): Promise<Row[]> {
  const rows: Row[] = [];
  const { data: bq } = await supabase
    .from('book_questions')
    .select('id, question')
    .eq('is_active', true);
  for (const r of bq ?? []) {
    rows.push({ source: 'book', question_id: r.id, question: r.question });
  }
  const { data: gq } = await supabase
    .from('general_questions')
    .select('id, question')
    .eq('is_active', true);
  for (const r of gq ?? []) {
    rows.push({ source: 'general', question_id: r.id, question: r.question });
  }
  return rows;
}

async function loadOne(source: 'book' | 'general', questionId: string): Promise<Row | null> {
  const table = source === 'book' ? 'book_questions' : 'general_questions';
  const { data } = await supabase
    .from(table)
    .select('id, question')
    .eq('id', questionId)
    .maybeSingle();
  if (!data) return null;
  return { source, question_id: data.id, question: data.question };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return json({ error: 'POST 요청만 허용됩니다.' }, 405);
    }

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
    const force = isAdmin && body.force === true;

    const langs: Lang[] = Array.isArray(body.langs)
      ? body.langs.filter((l: string): l is Lang => (LANGS as readonly string[]).includes(l))
      : [...LANGS];

    let rows: Row[] = [];
    if (body.all === true) {
      if (!isAdmin) return json({ error: '전체 번역은 관리자만 가능합니다.' }, 403);
      rows = await loadSources();
    } else if (body.question_id && body.source) {
      if (body.source !== 'book' && body.source !== 'general') {
        return json({ error: 'source는 book 또는 general 이어야 합니다.' }, 400);
      }
      const one = await loadOne(body.source, body.question_id);
      if (!one) return json({ error: '물음을 찾을 수 없습니다.' }, 404);
      rows = [one];
    } else {
      return json({ error: 'all 또는 (source, question_id)가 필요합니다.' }, 400);
    }

    const results = [];
    for (const row of rows) {
      for (const lang of langs) {
        results.push(await processOne(row, lang, force));
      }
    }

    const translated = results.filter((r) => r.ok && !r.reason).length;
    return json({ total: results.length, translated, results });
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
