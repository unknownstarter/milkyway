import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/// FCM v1 API 인증용 OAuth2 액세스 토큰 획득 (notify-new-public-memo와 동일)
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
  return (await tokenResponse.json()).access_token;
}

/// FCM 이 "이 토큰은 더 못 쓴다"고 답한 경우인지. 404 UNREGISTERED, 400 INVALID_ARGUMENT(토큰 형식).
/// INVALID_ARGUMENT 는 페이로드 문제일 수도 있어서 메시지/상세가 토큰을 가리킬 때만 인정한다.
function isDeadTokenError(status: number, bodyText: string): boolean {
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
async function dropDeadToken(userId: string, token: string): Promise<void> {
  const { error } = await supabase
    .from('users')
    .update({ fcm_token: null })
    .eq('id', userId)
    .eq('fcm_token', token);
  if (error) console.error('죽은 FCM 토큰 삭제 실패:', error.message);
  else console.log(`죽은 FCM 토큰 삭제: user=${userId}`);
}

const ok = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return ok({ error: 'POST 요청만 허용됩니다.' }, 405);

    const { comment_id: commentId } = await req.json();
    if (!commentId || typeof commentId !== 'string') {
      return ok({ error: 'comment_id가 제공되지 않았습니다.' }, 400);
    }

    // 1) 댓글 -> 메모 -> 작성자 체인 조회 (서비스 롤이라 RLS 우회)
    const { data: comment, error: commentErr } = await supabase
      .from('comments')
      .select('id, content, user_id, memo_id')
      .eq('id', commentId)
      .single();
    if (commentErr || !comment) return ok({ error: '댓글을 찾을 수 없습니다.' }, 404);

    const { data: memo, error: memoErr } = await supabase
      .from('memos')
      .select('id, user_id, book_id')
      .eq('id', comment.memo_id)
      .single();
    if (memoErr || !memo) return ok({ error: '메모를 찾을 수 없습니다.' }, 404);

    const authorId = memo.user_id as string | null;
    const commenterId = comment.user_id as string;

    // 2) 자기 메모에 자기 댓글이면 알림 없음
    if (!authorId || authorId === commenterId) {
      return ok({ message: '알림 대상 없음(본인 댓글).' });
    }

    // 3) 작성자 알림 설정/토큰 확인
    const { data: author } = await supabase
      .from('users')
      .select('fcm_token, notification_enabled')
      .eq('id', authorId)
      .single();
    if (
      !author ||
      !author.fcm_token ||
      author.fcm_token.length === 0 ||
      author.notification_enabled === false
    ) {
      return ok({ message: '알림을 받을 수 없는 사용자입니다.' });
    }

    // 4) 알림 문구용 부가 정보(댓글 작성자 닉네임, 책 제목)
    const { data: commenter } = await supabase
      .from('users')
      .select('nickname')
      .eq('id', commenterId)
      .single();
    const { data: book } = await supabase
      .from('books')
      .select('title')
      .eq('id', memo.book_id)
      .single();

    const commenterName = commenter?.nickname || '누군가';
    const bookTitle = book?.title || '메모';
    const preview =
      comment.content && comment.content.length > 50
        ? comment.content.substring(0, 50) + '...'
        : comment.content || '새 댓글';

    const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
    if (!FCM_SERVICE_ACCOUNT_JSON) {
      console.warn('FCM_SERVICE_ACCOUNT_JSON 미설정 - 발송 건너뜀');
      return ok({ success: false, message: 'FCM_SERVICE_ACCOUNT_JSON 미설정' });
    }
    const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
    const accessToken = await generateAccessToken(serviceAccount);

    // 5) 메모 작성자에게만 발송. data.memo_id -> 기존 딥링크가 메모 상세로 라우팅.
    const messagePayload = {
      message: {
        token: author.fcm_token,
        notification: {
          title: `[${bookTitle}] 새 댓글`,
          body: `${commenterName}님이 댓글을 남겼습니다: "${preview}"`,
        },
        data: {
          type: 'new_comment',
          memo_id: memo.id,
          book_id: memo.book_id ?? '',
        },
        android: { priority: 'high' },
        apns: {
          headers: { 'apns-priority': '10' },
          payload: { aps: { sound: 'default' } },
        },
      },
    };

    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(messagePayload),
      },
    );

    if (!fcmResponse.ok) {
      const errorData = await fcmResponse.text();
      console.error('FCM 전송 실패:', errorData);
      if (isDeadTokenError(fcmResponse.status, errorData)) {
        await dropDeadToken(authorId, author.fcm_token);
        return ok({ sent: false, success: false, reason: 'token_unregistered' }, 200);
      }
      return ok({ success: false, message: 'FCM 전송 실패' }, 200);
    }

    return ok({ success: true, message: '댓글 알림 전송 완료' });
  } catch (e) {
    console.error('에러 발생:', e);
    return ok({ error: (e as Error).message }, 500);
  }
});
