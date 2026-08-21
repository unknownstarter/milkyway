import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: "POST 요청만 허용됩니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 405,
      });
    }

    const body = await req.json();
    const memoId = body.memo_id;

    if (!memoId || typeof memoId !== 'string') {
      return new Response(JSON.stringify({ error: "memo_id가 제공되지 않았습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // 호출자 식별(가시성 검사용). service role client로 전달된 사용자 JWT를 검증.
    const authHeader = req.headers.get('Authorization') ?? '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    let callerId: string | null = null;
    if (token && token !== SUPABASE_SERVICE_ROLE_KEY) {
      const { data: userData } = await supabase.auth.getUser(token);
      callerId = userData?.user?.id ?? null;
    }

    // Service Role Key를 사용하므로 RLS를 우회한다. 가시성은 아래에서 직접 강제한다.
    const { data, error } = await supabase
      .from('memos')
      .select(
        `
        *,
        comment_count,
        lyra_question,
        books (
          id,
          title,
          author,
          cover_url
        ),
        users!user_id (
          nickname,
          picture_url
        )
      `
      )
      .eq('id', memoId)
      .single();

    if (error) {
      console.error('메모 조회 실패:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    if (!data) {
      return new Response(JSON.stringify({ error: "메모를 찾을 수 없습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 404,
      });
    }

    // 가시성 강제: 공개 메모이거나 본인 메모만. 남의 비공개는 존재 자체를 숨겨 404.
    const isPublic = data.visibility === 'public';
    const isOwner = callerId !== null && data.user_id === callerId;
    if (!isPublic && !isOwner) {
      return new Response(JSON.stringify({ error: "메모를 찾을 수 없습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 404,
      });
    }

    return new Response(
      JSON.stringify({ memo: data }),
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

