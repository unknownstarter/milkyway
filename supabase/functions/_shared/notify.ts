// 알림 공통 모듈: 수신 판정(decide), FCM 발송, 꺼진 토큰 처리.
// 순수 계산(시간대/마일스톤/묶음 문구)은 notify_core.ts.
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';
import {
  dailyLimitReached,
  isQuietHour,
  type Lang,
  localDayRange,
  nextMorning,
  normalizeLang,
  safeTimeZone,
} from './notify_core.ts';

export * from './notify_core.ts';

export type NotifyKind = 'comment' | 'book_memo';

export interface NotifyPayload {
  title: string;
  body: string;
  /// FCM data 는 문자열만 허용
  data: Record<string, string>;
  image?: string | null;
  /// 아침 묶음 본문에 쓸 댓글 본문 요약 (pending data 에만 저장, FCM 으로는 안 보냄)
  preview?: string;
  /// 아침 묶음에서 "OO님 외 N명" 문구용 (pending data 에만 저장, FCM 으로는 안 보냄)
  actorName?: string;
  actorId?: string;
}

export type DecideResult =
  | { status: 'sent' }
  | { status: 'queued'; deliverAfter: string }
  | { status: 'skipped'; reason: string }
  | { status: 'failed'; reason: string };

export function getAdminClient(): SupabaseClient {
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) {
    throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
  }
  return createClient(url, key);
}

// ───────────── FCM ─────────────

let cachedAccessToken: { token: string; exp: number; sa: any } | null = null;

/// JWT 토큰 생성 및 OAuth2 액세스 토큰 획득 (FCM v1 API 인증용)
async function generateAccessToken(serviceAccount: any): Promise<string> {
  const { SignJWT, importPKCS8 } = await import('npm:jose@5.2.0');
  const now = Math.floor(Date.now() / 1000);
  const privateKey = await importPKCS8(
    serviceAccount.private_key.replace(/\\n/g, '\n'),
    'RS256',
  );
  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuedAt(now)
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!tokenResponse.ok) {
    throw new Error(`OAuth2 토큰 획득 실패: ${await tokenResponse.text()}`);
  }
  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

async function getFcmAuth(): Promise<{ accessToken: string; projectId: string } | null> {
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  if (!raw) {
    console.warn('FCM_SERVICE_ACCOUNT_JSON 미설정 - 발송 건너뜀');
    return null;
  }
  const nowSec = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp > nowSec + 60) {
    return { accessToken: cachedAccessToken.token, projectId: cachedAccessToken.sa.project_id };
  }
  const sa = JSON.parse(raw);
  const token = await generateAccessToken(sa);
  cachedAccessToken = { token, exp: nowSec + 3000, sa };
  return { accessToken: token, projectId: sa.project_id };
}

/// FCM 이 "이 토큰은 더 못 쓴다"고 답한 경우인지. 404 UNREGISTERED, 400 INVALID_ARGUMENT(토큰 형식).
/// INVALID_ARGUMENT 는 페이로드 문제일 수도 있어서 메시지/상세가 토큰을 가리킬 때만 인정한다.
export function isDeadTokenError(status: number, bodyText: string): boolean {
  let err: any = null;
  try {
    err = JSON.parse(bodyText)?.error ?? null;
  } catch (_) {
    return false;
  }
  if (!err) return false;
  const details = JSON.stringify(err.details ?? []);
  if (status === 404 || err.status === 'NOT_FOUND') {
    return err.status === 'NOT_FOUND' ? details.includes('UNREGISTERED') : true;
  }
  if (status === 400 || err.status === 'INVALID_ARGUMENT') {
    return /token/i.test(`${err.message ?? ''} ${details}`);
  }
  return false;
}

/// 죽은 토큰을 users 에서 지운다. 그 사이 새 토큰으로 바뀌었으면 건드리지 않도록 값이 같을 때만.
export async function dropDeadToken(
  supabase: SupabaseClient,
  userId: string,
  token: string,
): Promise<void> {
  const { error } = await supabase
    .from('users')
    .update({ fcm_token: null })
    .eq('id', userId)
    .eq('fcm_token', token);
  if (error) console.error('죽은 FCM 토큰 삭제 실패:', error.message);
  else console.log(`죽은 FCM 토큰 삭제: user=${userId}`);
}

export type PushOutcome = 'sent' | 'dead_token' | 'failed' | 'no_fcm';

/// FCM 한 건 발송. 성공 기록(notification_sends)은 호출자가 한다.
export async function sendPush(
  supabase: SupabaseClient,
  userId: string,
  token: string,
  payload: NotifyPayload,
): Promise<PushOutcome> {
  let auth;
  try {
    auth = await getFcmAuth();
  } catch (e) {
    console.error('FCM 인증 실패:', e);
    return 'failed';
  }
  if (!auth) return 'no_fcm';

  const message: any = {
    token,
    notification: { title: payload.title, body: payload.body },
    data: payload.data,
    android: { priority: 'high' },
    apns: { headers: { 'apns-priority': '10' }, payload: { aps: { sound: 'default' } } },
  };
  if (payload.image) {
    message.android.notification = { image: payload.image };
    message.apns.fcmOptions = { image: payload.image };
  }

  try {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${auth.projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${auth.accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message }),
      },
    );
    if (res.ok) return 'sent';
    const errorText = await res.text();
    console.error(`FCM 전송 실패 (user=${userId}):`, errorText);
    if (isDeadTokenError(res.status, errorText)) {
      await dropDeadToken(supabase, userId, token);
      return 'dead_token';
    }
    return 'failed';
  } catch (e) {
    console.error('FCM 전송 중 오류 발생:', e);
    return 'failed';
  }
}

// ───────────── 수신자 / 판정 ─────────────

export interface Recipient {
  token: string | null;
  enabled: boolean; // users.notification_enabled (null 은 켜짐)
  switchOn: boolean; // 종류별 스위치
  quietHours: boolean;
  timeZone: string;
  /// 수신자 언어 (notification_preferences.language, 없으면 ko)
  language: Lang;
}

/// users + notification_preferences. 설정 행이 없으면 기본값 (모두 켜짐, Asia/Seoul).
export async function loadRecipient(
  supabase: SupabaseClient,
  userId: string,
  kind: NotifyKind,
): Promise<Recipient | null> {
  const { data: user } = await supabase
    .from('users')
    .select('fcm_token, notification_enabled')
    .eq('id', userId)
    .maybeSingle();
  if (!user) return null;
  const { data: pref } = await supabase
    .from('notification_preferences')
    .select('book_memos, comments, quiet_hours, time_zone, language')
    .eq('user_id', userId)
    .maybeSingle();
  const switchOn = pref ? (kind === 'comment' ? pref.comments : pref.book_memos) !== false : true;
  return {
    token: user.fcm_token && user.fcm_token.length > 0 ? user.fcm_token : null,
    enabled: user.notification_enabled !== false,
    switchOn,
    quietHours: pref ? pref.quiet_hours !== false : true,
    timeZone: safeTimeZone(pref?.time_zone),
    language: normalizeLang(pref?.language),
  };
}

/// 현지 오늘 해당 kind 발송 수
export async function countSentToday(
  supabase: SupabaseClient,
  userId: string,
  kind: NotifyKind,
  timeZone: string,
  now: Date,
): Promise<number> {
  const { start, end } = localDayRange(now, timeZone);
  const { count } = await supabase
    .from('notification_sends')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('kind', kind)
    .gte('sent_at', start.toISOString())
    .lt('sent_at', end.toISOString());
  return count ?? 0;
}

export async function recordSend(
  supabase: SupabaseClient,
  userId: string,
  kind: NotifyKind,
): Promise<void> {
  const { error } = await supabase.from('notification_sends').insert({ user_id: userId, kind });
  if (error) console.error('notification_sends 기록 실패:', error.message);
}

/// 알림 한 건을 보낼지/모아둘지/버릴지 판정하고 실행한다.
/// 1 전체 끔 2 종류 스위치 3 토큰 4 하루 상한(book_memo) 5 방해 금지 시간 6 즉시 발송
export async function decide(
  supabase: SupabaseClient,
  userId: string,
  kind: NotifyKind,
  payloadOrBuild: NotifyPayload | ((lang: Lang) => NotifyPayload),
  now: Date = new Date(),
): Promise<DecideResult> {
  const r = await loadRecipient(supabase, userId, kind);
  if (!r) return { status: 'skipped', reason: 'no_user' };
  if (!r.enabled) return { status: 'skipped', reason: 'notification_disabled' };
  if (!r.switchOn) return { status: 'skipped', reason: 'preference_off' };
  if (!r.token) return { status: 'skipped', reason: 'no_token' };

  // 수신자 언어로 문구를 만든다 (prefs 를 이미 읽었으므로 쿼리 추가 없음)
  const payload = typeof payloadOrBuild === 'function'
    ? payloadOrBuild(r.language)
    : payloadOrBuild;

  if (kind === 'book_memo') {
    const sent = await countSentToday(supabase, userId, kind, r.timeZone, now);
    if (dailyLimitReached(sent, kind)) return { status: 'skipped', reason: 'daily_limit' };
  }

  if (r.quietHours && isQuietHour(now, r.timeZone)) {
    if (kind === 'book_memo') {
      // 아침에 어차피 1개만 나가므로 이미 모아둔 게 있으면 더 넣지 않는다
      const { count } = await supabase
        .from('pending_notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('kind', 'book_memo')
        .is('sent_at', null);
      if ((count ?? 0) > 0) return { status: 'skipped', reason: 'already_queued' };
    }
    const deliverAfter = nextMorning(now, r.timeZone).toISOString();
    const { error } = await supabase.from('pending_notifications').insert({
      user_id: userId,
      kind,
      title: payload.title,
      body: payload.body,
      data: {
        ...payload.data,
        ...(payload.preview ? { preview: payload.preview } : {}),
        ...(payload.actorName ? { actor_name: payload.actorName } : {}),
        ...(payload.actorId ? { actor_id: payload.actorId } : {}),
        lang: r.language,
      },
      deliver_after: deliverAfter,
    });
    if (error) {
      console.error('pending_notifications 저장 실패:', error.message);
      return { status: 'failed', reason: 'queue_error' };
    }
    return { status: 'queued', deliverAfter };
  }

  const outcome = await sendPush(supabase, userId, r.token, payload);
  if (outcome === 'sent') {
    await recordSend(supabase, userId, kind);
    return { status: 'sent' };
  }
  return { status: 'failed', reason: outcome };
}
