import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';
import { bookMemoBody, decide, getAdminClient, milestoneFor } from '../_shared/notify.ts';

const supabase = getAdminClient();

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });
}

/// (user, book) 마일스톤을 n 으로 올리는 데 성공하면 true. 이미 n 이상이면 false.
/// 먼저 올리고 발송해서 같은 마일스톤이 두 번 나가지 않게 한다.
async function claimMilestone(
  db: SupabaseClient,
  userId: string,
  bookId: string,
  n: number,
): Promise<boolean> {
  const ins = await db
    .from('book_memo_milestones')
    .upsert(
      { user_id: userId, book_id: bookId, last_milestone: n },
      { onConflict: 'user_id,book_id', ignoreDuplicates: true },
    )
    .select('user_id');
  if (ins.error) {
    console.error('마일스톤 기록 실패:', ins.error.message);
    return false;
  }
  if ((ins.data?.length ?? 0) > 0) return true;

  const upd = await db
    .from('book_memo_milestones')
    .update({ last_milestone: n, updated_at: new Date().toISOString() })
    .eq('user_id', userId)
    .eq('book_id', bookId)
    .lt('last_milestone', n)
    .select('user_id');
  if (upd.error) {
    console.error('마일스톤 갱신 실패:', upd.error.message);
    return false;
  }
  return (upd.data?.length ?? 0) > 0;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return json({ error: 'POST 요청만 허용됩니다.' }, 405);

    const body = await req.json();
    const bookId = body.book_id;
    const memoId = body.memo_id;
    if (!bookId || typeof bookId !== 'string') {
      return json({ error: 'book_id가 제공되지 않았습니다.' }, 400);
    }
    if (!memoId || typeof memoId !== 'string') {
      return json({ error: 'memo_id가 제공되지 않았습니다.' }, 400);
    }

    // 메모 작성자
    let authorId: string | null = body.memo_author_id ?? null;
    if (!authorId) {
      const { data: memoData } = await supabase
        .from('memos')
        .select('user_id')
        .eq('id', memoId)
        .single();
      authorId = memoData?.user_id ?? null;
    }

    // 이 책을 담은 사람 (작성자 제외)와 담은 시각
    const { data: savers, error: saversErr } = await supabase
      .from('user_books')
      .select('user_id, created_at')
      .eq('book_id', bookId);
    if (saversErr) {
      console.error('사용자 조회 실패:', saversErr);
      return json({ error: saversErr.message }, 500);
    }
    const targets = (savers ?? []).filter((s) => s.user_id !== authorId);
    if (targets.length === 0) return json({ message: '알림을 받을 사용자가 없습니다.' });

    // 이 책의 공개 메모 전체 (작성자, 시각만). 사용자별 누적 수는 메모리에서 센다.
    const { data: publicMemos, error: memosErr } = await supabase
      .from('memos')
      .select('user_id, created_at')
      .eq('book_id', bookId)
      .eq('visibility', 'public');
    if (memosErr) {
      console.error('공개 메모 조회 실패:', memosErr);
      return json({ error: memosErr.message }, 500);
    }

    const { data: milestoneRows } = await supabase
      .from('book_memo_milestones')
      .select('user_id, last_milestone')
      .eq('book_id', bookId);
    const lastByUser = new Map<string, number>(
      (milestoneRows ?? []).map((r) => [r.user_id as string, r.last_milestone as number]),
    );

    // 마일스톤에 닿은 사용자만 추린다
    const hits: { userId: string; n: number }[] = [];
    for (const s of targets) {
      const savedAt = new Date(s.created_at).getTime();
      const n = (publicMemos ?? []).filter(
        (m) => m.user_id !== s.user_id && new Date(m.created_at).getTime() >= savedAt,
      ).length;
      const milestone = milestoneFor(n, lastByUser.get(s.user_id) ?? 0);
      if (milestone !== null) hits.push({ userId: s.user_id, n: milestone });
    }
    if (hits.length === 0) return json({ message: '마일스톤에 닿은 사용자가 없습니다.', hits: 0 });

    const { data: book } = await supabase
      .from('books')
      .select('title, cover_url')
      .eq('id', bookId)
      .single();
    const bookTitle = book?.title || '알 수 없는 책';

    const summary: Record<string, number> = {};
    for (const { userId, n } of hits) {
      if (!(await claimMilestone(supabase, userId, bookId, n))) {
        summary['already_claimed'] = (summary['already_claimed'] ?? 0) + 1;
        continue;
      }
      const result = await decide(supabase, userId, 'book_memo', {
        title: bookTitle,
        body: bookMemoBody(n),
        data: { type: 'book_memo', book_id: bookId, memo_id: memoId },
        image: book?.cover_url ?? null,
      });
      const key = result.status === 'sent' || result.status === 'queued'
        ? result.status
        : `${result.status}:${result.reason}`;
      summary[key] = (summary[key] ?? 0) + 1;
    }

    console.log('책 메모 알림 처리:', JSON.stringify(summary));
    return json({ success: true, hits: hits.length, summary });
  } catch (e) {
    console.error('에러 발생:', e);
    return json({ error: (e as Error).message }, 500);
  }
});
