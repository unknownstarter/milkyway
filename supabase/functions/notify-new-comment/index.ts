import { decide, getAdminClient } from '../_shared/notify.ts';

const supabase = getAdminClient();

function ok(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });
}

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

    // 3) 알림 문구용 부가 정보(댓글 작성자 닉네임, 책 제목)
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

    // 4) 수신 판정(전체 끔/댓글 스위치/토큰/방해 금지 시간)은 decide 가 한다. 댓글은 하루 상한 없음.
    const result = await decide(supabase, authorId, 'comment', {
      title: `[${bookTitle}] 새 댓글`,
      body: `${commenterName}님이 댓글을 남겼습니다: "${preview}"`,
      // data.memo_id -> 기존 딥링크가 메모 상세로 라우팅
      data: {
        type: 'new_comment',
        memo_id: memo.id,
        book_id: memo.book_id ?? '',
      },
      preview,
    });

    return ok({
      success: result.status === 'sent' || result.status === 'queued',
      ...result,
    });
  } catch (e) {
    console.error('에러 발생:', e);
    return ok({ error: (e as Error).message }, 500);
  }
});
