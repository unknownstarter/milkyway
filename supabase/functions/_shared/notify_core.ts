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

export function bookMemoBody(n: number): string {
  return n <= 1 ? '다른 사람의 첫 메모가 생겼어요' : `다른 사람 메모가 ${n}개 쌓였어요`;
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
    out.push({
      kind: 'comment',
      title: `밤사이 댓글 ${comments.length}개가 달렸어요`,
      body: last.data?.preview ?? last.body,
      data: stripPreview(last.data),
    });
  }
  const memo = sorted.find((r) => r.kind === 'book_memo');
  if (memo && bookMemoAllowed) {
    out.push({ kind: 'book_memo', title: memo.title, body: memo.body, data: stripPreview(memo.data) });
  }
  return out;
}

function stripPreview(data: Record<string, string> | null | undefined): Record<string, string> {
  const { preview: _p, ...rest } = data ?? {};
  return rest;
}
