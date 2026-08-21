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

    // Service Role Key를 사용하므로 RLS 정책을 우회하여 메모와 사용자 정보 조회 가능
    // 공개/비공개 모두 조회 가능 (메모 상세 화면에서 필요)
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

