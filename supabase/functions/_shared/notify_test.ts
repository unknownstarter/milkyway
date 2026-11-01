import { assertEquals } from 'jsr:@std/assert@1';
import {
  bookMemoCopy,
  bookMemoPayload,
  buildDigests,
  commentCopy,
  commentPayload,
  digestCopy,
  makePreview,
  normalizeLang,
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
  // actor 정보가 없는 옛 pending 은 한 사람(누군가)으로 폴백
  assertEquals(many[0].body, '누군가님이 내 메모에 댓글을 남겼어요');
  assertEquals(many[0].data, { memo_id: '2' });
  assertEquals(many[1].kind, 'book_memo');
  assertEquals(many[1].title, 't-3');

  assertEquals(buildDigests([mk('3', 'book_memo', '2026-11-01T16:00:00Z')], false).length, 0);
});

// ───────────── 푸시 문구 계약 (명세에서 그대로 복사한 기대값) ─────────────
type L = 'ko' | 'en' | 'ja' | 'zh';
const LS: L[] = ['ko', 'en', 'ja', 'zh'];
const N = { ko: '하늘', en: 'Sky', ja: 'そら', zh: '小天' };
const B = { ko: '데미안', en: 'Demian', ja: 'デミアン', zh: '德米安' };
const P = '오늘 읽은 문장이 좋았어요';

const EXPECT_COMMENT: Record<L, [string, string]> = {
  ko: ['하늘님이 내 메모에 댓글을 남겼어요', `《데미안》 "${P}"`],
  en: ['Sky commented on your memo', `On "Demian": "${P}"`],
  ja: ['そらさんがメモにコメントしました', `『デミアン』「${P}」`],
  zh: ['小天 评论了你的笔记', `《德米安》"${P}"`],
};
const EXPECT_MEMO1: Record<L, [string, string]> = {
  ko: ['하늘님이 《데미안》에 메모를 남겼어요', '같은 책을 읽는 사람의 생각을 만나보세요'],
  en: ['Sky left a memo on "Demian"', 'See what another reader is thinking'],
  ja: ['そらさんが『デミアン』にメモを残しました', '同じ本を読む人の思いを見てみましょう'],
  zh: ['小天 在《德米安》留下了笔记', '看看同样读这本书的人在想什么'],
};
const EXPECT_MEMO5: Record<L, [string, string]> = {
  ko: ['《데미안》에 메모가 5개 쌓였어요', '같은 책을 읽는 사람들의 생각을 만나보세요'],
  en: ['5 memos on "Demian"', 'See what other readers are thinking'],
  ja: ['『デミアン』にメモが5件たまりました', '同じ本を読む人たちの思いを見てみましょう'],
  zh: ['《德米安》已有 5 条笔记', '看看同样读这本书的人们在想什么'],
};
const EXPECT_DIGEST_TITLE: Record<L, string> = {
  ko: '밤사이 댓글 3개가 달렸어요',
  en: '3 comments came in overnight',
  ja: '夜のあいだにコメントが3件届きました',
  zh: '夜里收到了 3 条评论',
};
const EXPECT_DIGEST_M0: Record<L, string> = {
  ko: '하늘님이 내 메모에 댓글을 남겼어요',
  en: 'Sky commented on your memo',
  ja: 'そらさんがメモにコメントしました',
  zh: '小天 评论了你的笔记',
};
const EXPECT_DIGEST_M1: Record<L, string> = {
  ko: '하늘님 외 1명이 내 메모에 댓글을 남겼어요',
  en: 'Sky and 1 other commented on your memo',
  ja: 'そらさんほか1人がメモにコメントしました',
  zh: '小天 等 1 人评论了你的笔记',
};
const EXPECT_DIGEST_M2: Record<L, string> = {
  ko: '하늘님 외 2명이 내 메모에 댓글을 남겼어요',
  en: 'Sky and 2 others commented on your memo',
  ja: 'そらさんほか2人がメモにコメントしました',
  zh: '小天 等 2 人评论了你的笔记',
};
Deno.test('문구: 댓글 4개 언어', () => {
  for (const l of LS) {
    const c = commentCopy(l, { name: N[l], book: B[l], preview: P });
    assertEquals([c.title, c.body], EXPECT_COMMENT[l]);
  }
});

Deno.test('문구: 책 메모 1개째 / n개째', () => {
  for (const l of LS) {
    const a = bookMemoCopy(l, { n: 1, book: B[l], name: N[l] });
    assertEquals([a.title, a.body], EXPECT_MEMO1[l]);
    const b = bookMemoCopy(l, { n: 5, book: B[l], name: N[l] });
    assertEquals([b.title, b.body], EXPECT_MEMO5[l]);
  }
});

Deno.test('문구: 밤사이 묶음 m=0/1/2', () => {
  for (const l of LS) {
    for (const [m, exp] of [[0, EXPECT_DIGEST_M0], [1, EXPECT_DIGEST_M1], [2, EXPECT_DIGEST_M2]] as const) {
      const d = digestCopy(l, { k: 3, m, name: N[l] });
      assertEquals(d.title, EXPECT_DIGEST_TITLE[l]);
      assertEquals(d.body, exp[l]);
    }
  }
});

Deno.test('묶음 k=1: 4개 언어 모두 묶음이 아닌 댓글 문구 그대로 (buildDigests)', () => {
  for (const l of LS) {
    const c = commentCopy(l, { name: N[l], book: B[l], preview: P });
    const out = buildDigests(
      [{
        id: '1',
        kind: 'comment',
        title: c.title,
        body: c.body,
        data: { type: 'new_comment', memo_id: 'm', book_id: 'b', actor_name: N[l], lang: l, preview: P },
        created_at: '2026-11-01T14:00:00Z',
      }],
      true,
    );
    assertEquals(out.length, 1);
    assertEquals([out[0].title, out[0].body], EXPECT_COMMENT[l]);
    assertEquals(out[0].data, { type: 'new_comment', memo_id: 'm', book_id: 'b' });
  }
});

Deno.test('묶음: 서로 다른 사람 수와 최근 사람 이름, lang 은 data 에서', () => {
  const mk = (id: string, at: string, name: string, actor: string) => ({
    id,
    kind: 'comment' as const,
    title: 'x',
    body: 'x',
    data: { memo_id: id, actor_name: name, actor_id: actor, lang: 'en' },
    created_at: at,
  });
  const out = buildDigests(
    [
      mk('1', '2026-11-01T14:00:00Z', 'Ann', 'a'),
      mk('2', '2026-11-01T15:00:00Z', 'Bob', 'b'),
      mk('3', '2026-11-01T16:00:00Z', 'Ann', 'a'),
    ],
    true,
  );
  assertEquals(out[0].title, '3 comments came in overnight');
  assertEquals(out[0].body, 'Ann and 1 other commented on your memo');
  assertEquals(out[0].data, { memo_id: '3' });
  // 한 사람이 여러 개
  const one = buildDigests(
    [mk('1', '2026-11-01T14:00:00Z', 'Ann', 'a'), mk('2', '2026-11-01T15:00:00Z', 'Ann', 'a')],
    true,
  );
  assertEquals(one[0].body, 'Ann commented on your memo');
});

Deno.test('폴백: 이름/책 없음, language null -> ko', () => {
  const exp: Record<L, [string, string]> = {
    ko: ['누군가님이 내 메모에 댓글을 남겼어요', `《책》 "x"`],
    en: ['Someone commented on your memo', `On "a book": "x"`],
    ja: ['だれかさんがメモにコメントしました', '『本』「x」'],
    zh: ['有人 评论了你的笔记', '《书》"x"'],
  };
  for (const l of LS) {
    for (const bad of [null, undefined, '', '   ']) {
      const c = commentCopy(l, { name: bad, book: bad, preview: 'x' });
      assertEquals([c.title, c.body], exp[l]);
    }
  }
  for (const lang of [null, undefined, '', 'fr', 'KO']) {
    assertEquals(normalizeLang(lang), 'ko');
    assertEquals(commentCopy(lang, { name: 'a', book: 'b', preview: 'c' }).title, 'a님이 내 메모에 댓글을 남겼어요');
  }
  assertEquals(bookMemoCopy('en', { n: 1, book: null, name: null }).title, 'Someone left a memo on "a book"');
  assertEquals(digestCopy('zh', { k: 2, m: 0, name: '' }).body, '有人 评论了你的笔记');
});

Deno.test('미리보기: 40자 / 41자 / 줄바꿈 / 공백 / 이모지', () => {
  const s40 = 'a'.repeat(40);
  assertEquals(makePreview(s40), s40);
  assertEquals(makePreview(s40 + 'b'), s40); // 41자 -> 40자, 말줄임 없음
  assertEquals(makePreview('  안녕\n하세요\r\n반가워요  '), '안녕 하세요 반가워요');
  assertEquals(makePreview(null), '');
  // 이모지(서로게이트 쌍)가 40자 경계에서 깨지지 않는다
  const emoji = '😀'.repeat(41);
  const cut = makePreview(emoji);
  assertEquals(Array.from(cut).length, 40);
  assertEquals(cut, '😀'.repeat(40));
  const mixed = 'a'.repeat(39) + '😀' + 'b';
  assertEquals(makePreview(mixed), 'a'.repeat(39) + '😀');
});

Deno.test('금지 문자가 모든 출력에 없다', () => {
  const forbidden = ['\u2014', '\u2013', '\u00B7', '\u201C', '\u201D', '\u2018', '\u2019', '\u2026', '!'];
  const outs: string[] = [];
  for (const l of [...LS, null]) {
    for (const nm of [N[(l ?? 'ko') as L], null]) {
      for (const bk of [B[(l ?? 'ko') as L], null]) {
        const c = commentCopy(l, { name: nm, book: bk, preview: makePreview('좋은 문장\n입니다') });
        outs.push(c.title, c.body);
        for (const n of [1, 5, 10, 100]) {
          const m = bookMemoCopy(l, { n, book: bk, name: nm });
          outs.push(m.title, m.body);
        }
        for (const [k, mm] of [[2, 0], [3, 1], [4, 2]]) {
          const d = digestCopy(l, { k, m: mm, name: nm });
          outs.push(d.title, d.body);
        }
      }
    }
  }
  assertEquals(outs.length > 100, true);
  for (const o of outs) {
    for (const f of forbidden) assertEquals(o.includes(f), false, `금지 문자 ${f} in ${o}`);
  }
  for (const l of [...LS, null]) {
    const ko = [
      ...Object.values(commentCopy(l, { name: null, book: null, preview: 'x' })),
      ...Object.values(bookMemoCopy(l, { n: 1 })),
      ...Object.values(bookMemoCopy(l, { n: 5 })),
      ...Object.values(digestCopy(l, { k: 2, m: 1 })),
    ];
    for (const o of ko) assertEquals(o.includes('당신'), false);
    // 짧은 문구 끝 마침표 없음
    for (const o of ko) assertEquals(/[.。]$/.test(o), false, o);
  }
});

Deno.test('FCM data 키 계약: type, memo_id, book_id 불변', () => {
  for (const l of LS) {
    const c = commentPayload(l, {
      memoId: 'm1',
      bookId: 'b1',
      commenterId: 'u1',
      commenterName: 'Sky',
      bookTitle: 'Demian',
      content: 'hello',
    });
    assertEquals(c.data, { type: 'new_comment', memo_id: 'm1', book_id: 'b1' });
    const b = bookMemoPayload(l, { n: 1, bookId: 'b1', memoId: 'm1', bookTitle: 'Demian' });
    assertEquals(b.data, { type: 'book_memo', book_id: 'b1', memo_id: 'm1' });
  }
  // book_id 가 null 이면 빈 문자열 (기존 동작)
  assertEquals(
    commentPayload('ko', { memoId: 'm', bookId: null, commenterId: 'u' }).data.book_id,
    '',
  );
});
