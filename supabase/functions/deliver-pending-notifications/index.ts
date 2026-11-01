// 방해 금지 시간에 모아둔 알림을 아침 7시(사용자 현지)에 묶어 보낸다.
// pg_cron 이 10분마다 부른다. 인증: x-cron-secret == env DELIVER_PENDING_SECRET.
import {
  buildDigests,
  countSentToday,
  getAdminClient,
  isQuietHour,
  loadRecipient,
  type PendingRow,
  recordSend,
  sendPush,
} from '../_shared/notify.ts';

const supabase = getAdminClient();
const BATCH_LIMIT = 1000;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });
}

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  try {
    const secret = Deno.env.get('DELIVER_PENDING_SECRET');
    const given = req.headers.get('x-cron-secret') ?? '';
    if (!secret || !safeEqual(given, secret)) return json({ error: 'unauthorized' }, 401);

    const now = new Date();
    const { data: rows, error } = await supabase
      .from('pending_notifications')
      .select('id, user_id, kind, title, body, data, created_at, deliver_after')
      .is('sent_at', null)
      .lte('deliver_after', now.toISOString())
      .order('created_at', { ascending: true })
      .limit(BATCH_LIMIT);
    if (error) return json({ error: error.message }, 500);
    if (!rows || rows.length === 0) return json({ message: '보낼 알림 없음', users: 0 });

    const byUser = new Map<string, typeof rows>();
    for (const r of rows) {
      const list = byUser.get(r.user_id) ?? [];
      list.push(r);
      byUser.set(r.user_id, list);
    }

    const stats = { users: byUser.size, sent: 0, skipped: 0, failed: 0, deferred: 0 };

    for (const [userId, userRows] of byUser) {
      const markSent = async (ids: string[]) => {
        if (ids.length === 0) return;
        const { error: e } = await supabase
          .from('pending_notifications')
          .update({ sent_at: new Date().toISOString() })
          .in('id', ids);
        if (e) console.error('sent_at 갱신 실패:', e.message);
      };
      const allIds = userRows.map((r) => r.id as string);

      try {
        // 수신 조건을 다시 본다. 그 사이 스위치를 껐거나 토큰이 사라졌을 수 있다.
        const rc = await loadRecipient(supabase, userId, 'comment');
        const rb = await loadRecipient(supabase, userId, 'book_memo');
        if (!rc || !rb || !rc.enabled || !rc.token) {
          await markSent(allIds);
          stats.skipped += allIds.length;
          continue;
        }
        // 시간대를 바꿔 아직 방해 금지 시간이면 다음 주기로 미룬다
        if (rc.quietHours && isQuietHour(now, rc.timeZone)) {
          stats.deferred += allIds.length;
          continue;
        }

        const commentRows = userRows.filter((r) => r.kind === 'comment');
        const memoRows = userRows.filter((r) => r.kind === 'book_memo');
        const useRows = [
          ...(rc.switchOn ? commentRows : []),
          ...(rb.switchOn ? memoRows : []),
        ] as PendingRow[];

        const sentToday = await countSentToday(supabase, userId, 'book_memo', rb.timeZone, now);
        const digests = buildDigests(useRows, sentToday < 1);

        for (const d of digests) {
          const outcome = await sendPush(supabase, userId, rc.token, {
            title: d.title,
            body: d.body,
            data: d.data,
          });
          if (outcome === 'sent') {
            await recordSend(supabase, userId, d.kind);
            stats.sent++;
          } else if (outcome === 'failed') {
            stats.failed++;
          } else {
            stats.skipped++;
            if (outcome === 'dead_token') break;
          }
        }

        // 보낸 것, 건너뛴 것, 실패한 것 모두 닫는다 (재시도하면 이미 나간 묶음이 중복된다)
        await markSent(allIds);
      } catch (e) {
        console.error(`사용자 ${userId} 처리 실패:`, e);
        stats.failed++;
      }
    }

    console.log('아침 묶음 발송:', JSON.stringify(stats));
    return json({ success: true, ...stats });
  } catch (e) {
    console.error('에러 발생:', e);
    return json({ error: (e as Error).message }, 500);
  }
});
