// 알림 판정용 순수 함수. 네트워크/DB 의존 없음 (deno test 대상).

export const DEFAULT_TIME_ZONE = 'Asia/Seoul';
export const MILESTONES = [1, 5, 10, 20, 50, 100] as const;
export const QUIET_START_HOUR = 22;
export const QUIET_END_HOUR = 7;

/// 잘못된 IANA 이름이면 Asia/Seoul.
export function safeTimeZone(tz: string | null | undefined): string {
  if (!tz) return DEFAULT_TIME_ZONE;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return tz;
  } catch (_) {
    return DEFAULT_TIME_ZONE;
  }
}

export interface LocalParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

export function localParts(date: Date, tz: string): LocalParts {
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: safeTimeZone(tz),
    hourCycle: 'h23',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
  });
  const m: Record<string, number> = {};
  for (const p of fmt.formatToParts(date)) {
    if (p.type !== 'literal') m[p.type] = parseInt(p.value, 10);
  }
  return {
    year: m.year,
    month: m.month,
    day: m.day,
    hour: m.hour % 24,
    minute: m.minute,
    second: m.second,
  };
}

/// 현지 시각 -> UTC Date. month 는 1부터, day 오버플로(다음 달/다음 날)는 허용.
export function zonedTimeToUtc(
  y: number,
  month: number,
  d: number,
  h: number,
  mi: number,
  tz: string,
): Date {
  const wall = Date.UTC(y, month - 1, d, h, mi, 0);
  const offsetAt = (utcMs: number) => {
    const p = localParts(new Date(utcMs), tz);
    return Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second) - utcMs;
  };
  let guess = wall - offsetAt(wall);
  guess = wall - offsetAt(guess); // DST 경계 보정
  return new Date(guess);
}

/// 방해 금지 시간: 현지 22:00 ~ 06:59
export function isQuietHour(date: Date, tz: string): boolean {
  const h = localParts(date, tz).hour;
  return h >= QUIET_START_HOUR || h < QUIET_END_HOUR;
}

/// 다음 현지 07:00 (UTC). 정각 07:00 이면 같은 날 07:00 이 이미 지났으므로 다음 날.
export function nextMorning(date: Date, tz: string): Date {
  const p = localParts(date, tz);
  const dayOffset = p.hour < QUIET_END_HOUR ? 0 : 1;
  return zonedTimeToUtc(p.year, p.month, p.day + dayOffset, QUIET_END_HOUR, 0, tz);
}

/// 현지 오늘 [자정, 다음 자정) 을 UTC 로.
export function localDayRange(date: Date, tz: string): { start: Date; end: Date } {
  const p = localParts(date, tz);
  return {
    start: zonedTimeToUtc(p.year, p.month, p.day, 0, 0, tz),
    end: zonedTimeToUtc(p.year, p.month, p.day + 1, 0, 0, tz),
  };
}

/// n 번째 공개 메모가 알림 마일스톤인가. 이미 알린 마일스톤 이하면 null.
export function milestoneFor(n: number, lastMilestone: number): number | null {
  if (!(MILESTONES as readonly number[]).includes(n)) return null;
  return n > lastMilestone ? n : null;
}

// ───────────── 문구 (언어 x 종류) ─────────────

export type Lang = 'ko' | 'en' | 'ja' | 'zh';
export const LANGS: readonly Lang[] = ['ko', 'en', 'ja', 'zh'];
export const PREVIEW_MAX = 40;

export interface Copy {
  title: string;
  body: string;
}

/// null/모르는 값은 ko.
export function normalizeLang(lang: string | null | undefined): Lang {
  return (LANGS as readonly string[]).includes(lang ?? '') ? (lang as Lang) : 'ko';
}

const NAME_FALLBACK: Record<Lang, string> = { ko: '누군가', en: 'Someone', ja: 'だれか', zh: '有人' };
const BOOK_FALLBACK: Record<Lang, string> = { ko: '책', en: 'a book', ja: '本', zh: '书' };

export function nameOrFallback(name: string | null | undefined, lang: Lang): string {
  const t = (name ?? '').trim();
  return t.length > 0 ? t : NAME_FALLBACK[lang];
}

export function bookOrFallback(book: string | null | undefined, lang: Lang): string {
  const t = (book ?? '').trim();
  return t.length > 0 ? t : BOOK_FALLBACK[lang];
}

/// 줄바꿈은 공백으로, 앞뒤 공백 제거, 40자(유니코드 문자 기준) 넘으면 40자에서 자른다. 말줄임 표시 없음.
export function makePreview(text: string | null | undefined): string {
  const flat = (text ?? '').replace(/[\r\n]+/g, ' ').trim();
  const chars = Array.from(flat);
  return chars.length > PREVIEW_MAX ? chars.slice(0, PREVIEW_MAX).join('') : flat;
}

/// 댓글 1개. preview 는 이미 makePreview 를 거친 값.
export function commentCopy(
  langIn: string | null | undefined,
  v: { name?: string | null; book?: string | null; preview: string },
): Copy {
  const lang = normalizeLang(langIn);
  const name = nameOrFallback(v.name, lang);
  const book = bookOrFallback(v.book, lang);
  const p = v.preview;
  // 미리보기가 비면 빈 따옴표 대신 책 제목만 보인다
  const has = p.trim().length > 0;
  switch (lang) {
    case 'en':
      return { title: `${name} commented on your memo`, body: has ? `On "${book}": "${p}"` : `On "${book}"` };
    case 'ja':
      return { title: `${name}さんがメモにコメントしました`, body: has ? `『${book}』「${p}」` : `『${book}』` };
    case 'zh':
      return { title: `${name} 评论了你的笔记`, body: has ? `《${book}》"${p}"` : `《${book}》` };
    default:
      return { title: `${name}님이 내 메모에 댓글을 남겼어요`, body: has ? `《${book}》 "${p}"` : `《${book}》` };
  }
}

/// 책 메모. n <= 1 이면 첫 메모(name = 그 메모 작성자), 아니면 n개째(name 안 씀).
export function bookMemoCopy(
  langIn: string | null | undefined,
  v: { n: number; book?: string | null; name?: string | null },
): Copy {
  const lang = normalizeLang(langIn);
  const book = bookOrFallback(v.book, lang);
  const n = v.n;
  if (n <= 1) {
    const name = nameOrFallback(v.name, lang);
    switch (lang) {
      case 'en':
        return { title: `${name} left a memo on "${book}"`, body: 'See what another reader is thinking' };
      case 'ja':
        return { title: `${name}さんが『${book}』にメモを残しました`, body: '同じ本を読む人の思いを見てみましょう' };
      case 'zh':
        return { title: `${name} 在《${book}》留下了笔记`, body: '看看同样读这本书的人在想什么' };
      default:
        return { title: `${name}님이 《${book}》에 메모를 남겼어요`, body: '같은 책을 읽는 사람의 생각을 만나보세요' };
    }
  }
  switch (lang) {
    case 'en':
      return { title: `${n} memos on "${book}"`, body: 'See what other readers are thinking' };
    case 'ja':
      return { title: `『${book}』にメモが${n}件たまりました`, body: '同じ本を読む人たちの思いを見てみましょう' };
    case 'zh':
      return { title: `《${book}》已有 ${n} 条笔记`, body: '看看同样读这本书的人们在想什么' };
    default:
      return { title: `《${book}》에 메모가 ${n}개 쌓였어요`, body: '같은 책을 읽는 사람들의 생각을 만나보세요' };
  }
}

/// 밤사이 댓글 묶음 (k >= 2). m = 서로 다른 사람 수 - 1, name = 가장 최근 댓글 단 사람.
export function digestCopy(
  langIn: string | null | undefined,
  v: { k: number; m: number; name?: string | null },
): Copy {
  const lang = normalizeLang(langIn);
  const name = nameOrFallback(v.name, lang);
  const { k, m } = v;
  switch (lang) {
    case 'en':
      return {
        title: `${k} comments came in overnight`,
        body: m <= 0
          ? `${name} commented on your memo`
          : m === 1
          ? `${name} and 1 other commented on your memo`
          : `${name} and ${m} others commented on your memo`,
      };
    case 'ja':
      return {
        title: `夜のあいだにコメントが${k}件届きました`,
        body: m <= 0 ? `${name}さんがメモにコメントしました` : `${name}さんほか${m}人がメモにコメントしました`,
      };
    case 'zh':
      return {
        title: `夜里收到了 ${k} 条评论`,
        body: m <= 0 ? `${name} 评论了你的笔记` : `${name} 等 ${m} 人评论了你的笔记`,
      };
    default:
      return {
        title: `밤사이 댓글 ${k}개가 달렸어요`,
        body: m <= 0 ? `${name}님이 내 메모에 댓글을 남겼어요` : `${name}님 외 ${m}명이 내 메모에 댓글을 남겼어요`,
      };
  }
}

/// 댓글 알림 payload 전체 (문구 + FCM data). data 키(type, memo_id, book_id)는 앱 라우팅 계약이다.
export function commentPayload(
  lang: string | null | undefined,
  v: {
    memoId: string;
    bookId: string | null;
    commenterId: string;
    commenterName?: string | null;
    bookTitle?: string | null;
    content?: string | null;
  },
) {
  const preview = makePreview(v.content);
  const copy = commentCopy(lang, { name: v.commenterName, book: v.bookTitle, preview });
  return {
    ...copy,
    data: { type: 'new_comment', memo_id: v.memoId, book_id: v.bookId ?? '' } as Record<
      string,
      string
    >,
    preview,
    actorName: v.commenterName?.trim() || undefined,
    actorId: v.commenterId,
  };
}

/// 책 메모 알림 payload 전체. data 키(type 'book_memo', book_id, memo_id)는 앱 라우팅 계약이다.
export function bookMemoPayload(
  lang: string | null | undefined,
  v: {
    n: number;
    bookId: string;
    memoId: string;
    bookTitle?: string | null;
    firstAuthorName?: string | null;
    image?: string | null;
  },
) {
  return {
    ...bookMemoCopy(lang, { n: v.n, book: v.bookTitle, name: v.firstAuthorName }),
    data: { type: 'book_memo', book_id: v.bookId, memo_id: v.memoId } as Record<string, string>,
    image: v.image ?? null,
  };
}

export function dailyLimitReached(sentTodayCount: number, kind: string): boolean {
  return kind === 'book_memo' && sentTodayCount >= 1;
}

export type PendingRow = {
  id: string;
  kind: 'comment' | 'book_memo';
  title: string;
  body: string;
  data: Record<string, string>;
  created_at: string;
};

export interface Digest {
  title: string;
  body: string;
  data: Record<string, string>;
  kind: 'comment' | 'book_memo';
}

/// 한 사용자의 pending 을 보낼 알림으로 묶는다. 댓글은 1개면 그대로, 2개 이상이면 묶음.
/// book_memo 는 가장 오래된 1개만 (하루 상한 판정은 호출자가 bookMemoAllowed 로 넘긴다).
export function buildDigests(rows: PendingRow[], bookMemoAllowed: boolean): Digest[] {
  const out: Digest[] = [];
  const sorted = [...rows].sort((a, b) => a.created_at.localeCompare(b.created_at));
  const comments = sorted.filter((r) => r.kind === 'comment');
  if (comments.length === 1) {
    const c = comments[0];
    out.push({ kind: 'comment', title: c.title, body: c.body, data: stripPreview(c.data) });
  } else if (comments.length >= 2) {
    const last = comments[comments.length - 1];
    // 서로 다른 사람 수: actor_id 가 있으면 그것, 없으면 actor_name, 둘 다 없으면 한 사람으로 본다
    const actors = new Set(
      comments.map((c) => c.data?.actor_id || c.data?.actor_name || ''),
    );
    const copy = digestCopy(last.data?.lang, {
      k: comments.length,
      m: actors.size - 1,
      name: last.data?.actor_name,
    });
    out.push({ kind: 'comment', title: copy.title, body: copy.body, data: stripPreview(last.data) });
  }
  const memo = sorted.find((r) => r.kind === 'book_memo');
  if (memo && bookMemoAllowed) {
    out.push({ kind: 'book_memo', title: memo.title, body: memo.body, data: stripPreview(memo.data) });
  }
  return out;
}

function stripPreview(data: Record<string, string> | null | undefined): Record<string, string> {
  const { preview: _p, actor_name: _n, actor_id: _i, lang: _l, ...rest } = data ?? {};
  return rest;
}
