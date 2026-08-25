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
    const bookId = body.book_id;
    const limit = Math.min(body.limit || 10, 50); // 기본값 10, 최대 50으로 제한
    const offset = Math.max(body.offset || 0, 0); // 음수 방지
    const includeCount = body.include_count !== false; // 기본값 true, 첫 페이지에서만 필요

    if (!bookId || typeof bookId !== 'string') {
      return new Response(JSON.stringify({ error: "book_id가 제공되지 않았습니다." }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // Service Role Key를 사용하므로 RLS 정책을 우회하여 모든 공개 메모와 사용자 정보 조회 가능
    // count는 첫 페이지(offset === 0)에서만 계산하여 성능 최적화
    let query = supabase
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
          picture_url,
          deleted_at
        )
      `,
        includeCount && offset === 0 ? { count: 'exact' } : undefined
      )
      .eq('book_id', bookId)
      .eq('visibility', 'public')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // book_id로 목록 조회
    const { data, error, count } = await query;

    if (error) {
      console.error('공개 메모 조회 실패:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    // 소프트삭제(탈퇴 유예) 작성자의 메모는 숨김. deleted_at 은 응답에서 제거.
    const memos = (data || []).filter((m: any) => !m.users?.deleted_at)
      .map((m: any) => {
        if (m.users) delete m.users.deleted_at;
        return m;
      });

    // count가 없으면 (첫 페이지가 아니면) 결과 길이로 hasMore 판단
    const hasMore = count !== null
      ? (offset + limit) < count
      : memos.length === limit; // 정확하지 않지만 근사치로 사용

    return new Response(
      JSON.stringify({
        memos: memos,
        hasMore: hasMore,
        total: count || 0,
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

