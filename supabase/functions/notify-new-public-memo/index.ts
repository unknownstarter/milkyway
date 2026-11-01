import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/// JWT 토큰 생성 및 OAuth2 액세스 토큰 획득 (FCM v1 API 인증용)
async function generateAccessToken(serviceAccount: any): Promise<string> {
  // jose 라이브러리 사용 (Deno에서 npm 패키지 import)
  const { SignJWT, importPKCS8 } = await import('npm:jose@5.2.0');
  
  const now = Math.floor(Date.now() / 1000);
  
  // 서비스 계정의 private_key를 사용하여 JWT 서명
  // private_key는 이미 PEM 형식이므로 그대로 사용
  const privateKey = await importPKCS8(
    serviceAccount.private_key.replace(/\\n/g, '\n'),
    'RS256'
  );

  // JWT 생성
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

  // OAuth2 토큰 획득
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text();
    throw new Error(`OAuth2 토큰 획득 실패: ${error}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
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

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: "POST 요청만 허용됩니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 405,
      });
    }

    const body = await req.json();
    const bookId = body.book_id;
    const memoId = body.memo_id;
    const memoContent = body.memo_content;
    const memoAuthorNickname = body.memo_author_nickname;
    const memoAuthorId = body.memo_author_id;

    if (!bookId || typeof bookId !== 'string') {
      return new Response(JSON.stringify({ error: "book_id가 제공되지 않았습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    if (!memoId || typeof memoId !== 'string') {
      return new Response(JSON.stringify({ error: "memo_id가 제공되지 않았습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // 해당 책을 저장한 모든 사용자 조회 (메모 작성자 제외)
    const { data: userBooks, error: userBooksError } = await supabase
      .from('user_books')
      .select(
        `
        user_id,
        users!inner (
          id,
          fcm_token,
          notification_enabled
        )
      `
      )
      .eq('book_id', bookId);

    if (userBooksError) {
      console.error('사용자 조회 실패:', userBooksError);
      return new Response(JSON.stringify({ error: userBooksError.message }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    if (!userBooks || userBooks.length === 0) {
      return new Response(JSON.stringify({ message: "알림을 받을 사용자가 없습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // 메모 작성자 ID는 body에서 받거나, 없으면 DB에서 조회
    let authorId = memoAuthorId;
    if (!authorId) {
      const { data: memoData } = await supabase
        .from('memos')
        .select('user_id')
        .eq('id', memoId)
        .single();
      authorId = memoData?.user_id;
    }

    // FCM 토큰이 있고 알림이 활성화된 사용자만 필터링 (메모 작성자 제외)
    const tokens: { userId: string; token: string }[] = [];
    for (const userBook of userBooks) {
      const user = userBook.users;
      if (
        user &&
        user.id !== authorId && // 메모 작성자 제외
        user.fcm_token &&
        user.fcm_token.length > 0 &&
        user.notification_enabled !== false
      ) {
        tokens.push({ userId: (user as any).id, token: (user as any).fcm_token });
      }
    }

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ message: "알림을 받을 사용자가 없습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // 책 정보 조회 (제목 및 표지 이미지)
    const { data: bookData, error: bookError } = await supabase
      .from('books')
      .select('title, cover_url')
      .eq('id', bookId)
      .single();

    if (bookError) {
      console.error('책 정보 조회 실패:', bookError);
      return new Response(JSON.stringify({ error: bookError.message }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    const bookTitle = bookData?.title || '알 수 없는 책';
    const bookCoverUrl = bookData?.cover_url || null;
    const authorName = memoAuthorNickname || '사용자';
    const contentPreview = memoContent 
      ? (memoContent.length > 50 ? memoContent.substring(0, 50) + '...' : memoContent)
      : '새로운 메모';
    
    // 이미지 URL 설정: 책 표지 이미지가 있으면 사용, 없으면 null (앱 아이콘 사용)
    const notificationImage = bookCoverUrl || null;

    // FCM HTTP v1 API를 사용한 알림 전송
    // 서비스 계정 키 JSON을 환경 변수로 설정 필요
    const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
    
    if (!FCM_SERVICE_ACCOUNT_JSON) {
      console.warn('FCM_SERVICE_ACCOUNT_JSON가 설정되지 않았습니다. 알림 전송을 건너뜁니다.');
      return new Response(
        JSON.stringify({
          success: false,
          tokens_count: tokens.length,
          message: "FCM_SERVICE_ACCOUNT_JSON 환경 변수가 설정되지 않았습니다.",
        }),
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    let serviceAccount;
    try {
      serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
    } catch (e) {
      console.error('서비스 계정 JSON 파싱 실패:', e);
      return new Response(
        JSON.stringify({
          success: false,
          tokens_count: tokens.length,
          message: "서비스 계정 JSON 파싱 실패",
        }),
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // OAuth2 액세스 토큰 획득 (FCM v1 API 인증용)
    const accessToken = await generateAccessToken(serviceAccount);
    
    // FCM HTTP v1 API로 알림 전송
    // v1 API는 한 번에 하나의 토큰만 지원하므로 각각 전송
    let successCount = 0;
    let failureCount = 0;
    let droppedCount = 0;

    for (const { userId, token } of tokens) {
      try {
        // FCM 메시지 페이로드 구성
        const messagePayload: any = {
          message: {
            token: token,
            notification: {
              title: `[${bookTitle}] 새 공개 메모`,
              body: `${authorName}님이 새로운 메모를 남겼습니다: "${contentPreview}"`,
            },
            data: {
              type: 'new_public_memo',
              memo_id: memoId,
              book_id: bookId,
            },
            android: {
              priority: 'high',
            },
            apns: {
              headers: {
                'apns-priority': '10',
              },
              payload: {
                aps: {
                  sound: 'default',
                },
              },
            },
          },
        };

        // 이미지가 있으면 추가 (Android와 iOS 모두 지원)
        if (notificationImage) {
          // Android용 이미지 설정
          messagePayload.message.android.notification = {
            image: notificationImage,
          };
          // iOS용 이미지 설정
          messagePayload.message.apns.fcmOptions = {
            image: notificationImage,
          };
        }

        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(messagePayload),
          }
        );

        if (fcmResponse.ok) {
          successCount++;
        } else {
          const errorText = await fcmResponse.text();
          console.error(`FCM 전송 실패 (토큰: ${token.substring(0, 20)}...):`, errorText);
          failureCount++;
          if (isDeadTokenError(fcmResponse.status, errorText)) {
            await dropDeadToken(userId, token);
            droppedCount++;
          }
        }
      } catch (error) {
        console.error(`FCM 전송 중 오류 발생:`, error);
        failureCount++;
      }
    }

    console.log(`알림 전송 완료: 성공 ${successCount}개, 실패 ${failureCount}개`);

    return new Response(
      JSON.stringify({
        success: true,
        tokens_count: tokens.length,
        success_count: successCount,
        failure_count: failureCount,
        dropped_count: droppedCount,
        reason: droppedCount > 0 ? 'token_unregistered' : undefined,
        message: `알림 전송 완료: ${successCount}개 성공, ${failureCount}개 실패`,
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (e) {
    console.error('에러 발생:', e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

