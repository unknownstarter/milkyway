import { assertEquals } from 'jsr:@std/assert@1';
import {
  bookMemoBody,
  buildDigests,
  dailyLimitReached,
  isQuietHour,
  localDayRange,
  milestoneFor,
  nextMorning,
  safeTimeZone,
} from './notify_core.ts';

const SEOUL = 'Asia/Seoul'; // UTC+9, DST 없음
const NY = 'America/New_York';

const seoul = (iso: string) => new Date(`${iso}+09:00`);

Deno.test('방해 금지 경계 Asia/Seoul: 21:59 / 22:00 / 06:59 / 07:00', () => {
  assertEquals(isQuietHour(seoul('2026-11-01T21:59:00'), SEOUL), false);
  assertEquals(isQuietHour(seoul('2026-11-01T22:00:00'), SEOUL), true);
  assertEquals(isQuietHour(seoul('2026-11-02T00:00:00'), SEOUL), true);
  assertEquals(isQuietHour(seoul('2026-11-02T06:59:00'), SEOUL), true);
  assertEquals(isQuietHour(seoul('2026-11-02T07:00:00'), SEOUL), false);
});

Deno.test('방해 금지 경계 America/New_York (EST, UTC-5)', () => {
  assertEquals(isQuietHour(new Date('2026-11-02T02:59:00Z'), NY), false); // 21:59
  assertEquals(isQuietHour(new Date('2026-11-02T03:00:00Z'), NY), true); // 22:00
  assertEquals(isQuietHour(new Date('2026-11-02T11:59:00Z'), NY), true); // 06:59
  assertEquals(isQuietHour(new Date('2026-11-02T12:00:00Z'), NY), false); // 07:00
});

Deno.test('다음 07:00: 밤 22시는 다음 날, 새벽은 같은 날', () => {
  assertEquals(
    nextMorning(seoul('2026-11-01T22:00:00'), SEOUL).toISOString(),
    seoul('2026-11-02T07:00:00').toISOString(),
  );
  assertEquals(
    nextMorning(seoul('2026-11-02T06:59:00'), SEOUL).toISOString(),
    seoul('2026-11-02T07:00:00').toISOString(),
  );
  assertEquals(
    nextMorning(seoul('2026-11-02T00:30:00'), SEOUL).toISOString(),
    seoul('2026-11-02T07:00:00').toISOString(),
  );
  // 뉴욕 11/01 22:30 EST (전환 후) = 11/02 03:30Z -> 11/02 07:00 EST = 12:00Z
  assertEquals(
    nextMorning(new Date('2026-11-02T03:30:00Z'), NY).toISOString(),
    '2026-11-02T12:00:00.000Z',
  );
  // 연말 넘김
  assertEquals(
    nextMorning(seoul('2026-12-31T23:00:00'), SEOUL).toISOString(),
    seoul('2027-01-01T07:00:00').toISOString(),
  );
});

Deno.test('DST 전환일에도 07:00 현지 (뉴욕 2026-03-08 spring forward)', () => {
  // 3/7 23:00 EST = 3/8 04:00Z. 다음 07:00 은 3/8 07:00 EDT = 11:00Z
  assertEquals(
    nextMorning(new Date('2026-03-08T04:00:00Z'), NY).toISOString(),
    '2026-03-08T11:00:00.000Z',
  );
});

Deno.test('현지 하루 경계', () => {
  const r = localDayRange(seoul('2026-11-01T23:30:00'), SEOUL);
  assertEquals(r.start.toISOString(), seoul('2026-11-01T00:00:00').toISOString());
  assertEquals(r.end.toISOString(), seoul('2026-11-02T00:00:00').toISOString());
  // 뉴욕 11/01 은 EDT -> EST 전환일 (25시간)
  const ny = localDayRange(new Date('2026-11-02T03:30:00Z'), NY);
  assertEquals(ny.start.toISOString(), '2026-11-01T04:00:00.000Z');
  assertEquals(ny.end.toISOString(), '2026-11-02T05:00:00.000Z');
});

Deno.test('잘못된 time_zone 은 Asia/Seoul', () => {
  assertEquals(safeTimeZone('Mars/Olympus'), SEOUL);
  assertEquals(safeTimeZone(null), SEOUL);
  assertEquals(safeTimeZone(NY), NY);
  assertEquals(isQuietHour(seoul('2026-11-01T22:00:00'), 'Mars/Olympus'), true);
});

Deno.test('마일스톤 n=1,4,5,10,11,100,101 과 last_milestone 조합', () => {
  assertEquals(milestoneFor(1, 0), 1);
  assertEquals(milestoneFor(4, 1), null);
  assertEquals(milestoneFor(5, 1), 5);
  assertEquals(milestoneFor(10, 5), 10);
  assertEquals(milestoneFor(11, 10), null);
  assertEquals(milestoneFor(100, 50), 100);
  assertEquals(milestoneFor(101, 100), null);
  assertEquals(milestoneFor(5, 5), null);
  assertEquals(milestoneFor(5, 10), null);
  assertEquals(milestoneFor(1, 1), null);
  assertEquals(milestoneFor(10, 20), null);
});

Deno.test('책 메모 문구', () => {
  assertEquals(bookMemoBody(1), '다른 사람의 첫 메모가 생겼어요');
  assertEquals(bookMemoBody(5), '다른 사람 메모가 5개 쌓였어요');
  assertEquals(bookMemoBody(100), '다른 사람 메모가 100개 쌓였어요');
});

Deno.test('하루 상한: book_memo 만 1개', () => {
  assertEquals(dailyLimitReached(0, 'book_memo'), false);
  assertEquals(dailyLimitReached(1, 'book_memo'), true);
  assertEquals(dailyLimitReached(5, 'comment'), false);
});

Deno.test('아침 묶음: 댓글 1개는 그대로, 2개 이상은 묶음, book_memo 는 1개', () => {
  const mk = (id: string, kind: 'comment' | 'book_memo', at: string, extra = {}) => ({
    id,
    kind,
    title: `t-${id}`,
    body: `b-${id}`,
    data: { memo_id: id, ...extra } as Record<string, string>,
    created_at: at,
  });
  const one = buildDigests([mk('1', 'comment', '2026-11-01T14:00:00Z')], true);
  assertEquals(one.length, 1);
  assertEquals(one[0].title, 't-1');
  assertEquals(one[0].data, { memo_id: '1' });

  const many = buildDigests(
    [
      mk('2', 'comment', '2026-11-01T15:00:00Z', { preview: '마지막 댓글' }),
      mk('1', 'comment', '2026-11-01T14:00:00Z'),
      mk('3', 'book_memo', '2026-11-01T16:00:00Z'),
      mk('4', 'book_memo', '2026-11-01T17:00:00Z'),
    ],
    true,
  );
  assertEquals(many.length, 2);
  assertEquals(many[0].title, '밤사이 댓글 2개가 달렸어요');
  assertEquals(many[0].body, '마지막 댓글');
  assertEquals(many[0].data, { memo_id: '2' });
  assertEquals(many[1].kind, 'book_memo');
  assertEquals(many[1].title, 't-3');

  assertEquals(buildDigests([mk('3', 'book_memo', '2026-11-01T16:00:00Z')], false).length, 0);
});
