import { createClient } from 'npm:@supabase/supabase-js@2';

// 전역 공개 메모 피드(메모 탭 '공개' / 홈 최근 공개 메모).
// RLS상 클라이언트는 타 유저 정보 조인이 막혀 있어 service role로 우회한다.
// get-public-book-memos와 동일 패턴, book_id 필터만 없앤 전 책 대상.

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return json({ error: 'POST 요청만 허용됩니다.' }, 405);
    }

    const body = await req.json().catch(() => ({}));
    const limit = Math.min(body.limit || 20, 50);
    const offset = Math.max(body.offset || 0, 0);
    const includeCount = body.include_count !== false;
    // 본인 메모 제외(홈 '다른 별들이 남긴 생각들' 전용). 메모탭 '공개'는 미전달 -> 전체.
    const excludeUserId = typeof body.exclude_user_id === 'string'
      ? body.exclude_user_id
      : null;

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
          picture_url
        )
      `,
        includeCount && offset === 0 ? { count: 'exact' } : undefined,
      )
      .eq('visibility', 'public');

    if (excludeUserId) {
      query = query.neq('user_id', excludeUserId);
    }

    const { data, error, count } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('공개 피드 조회 실패:', error);
      return json({ error: error.message }, 500);
    }

    const hasMore = count !== null
      ? offset + limit < count
      : (data?.length ?? 0) === limit;

    return json({ memos: data || [], hasMore, total: count || 0 });
  } catch (e) {
    console.error('에러 발생:', e);
    return json({ error: (e as Error).message }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });
}
