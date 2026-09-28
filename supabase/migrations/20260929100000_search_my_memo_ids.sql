-- 책 제목/저자로도 내 메모를 찾는다(PRD v2 §14 Metadata 확장).
-- 기존 스키마 불변. 신규 테이블 없음. RPC 하나만 추가한다.
--
-- 왜 id 만 돌려주나:
--   메모 JSON 을 여기서 조립하면 select 모양이 두 군데로 갈라진다. 특히
--   comment_count / lyra_question 은 memos 의 컬럼이 아니라 PostgREST computed field 라
--   (함수 comment_count(memos) · lyra_question(memos)) 여기서 재현해야 하고,
--   나중에 컬럼이 하나 늘면 조용히 어긋난다.
--   그래서 순서만 여기서 정하고 본문은 클라이언트가 기존 select 로 채운다.
--   search-memos-semantic 이 쓰는 방식과 같다.
--
-- 왜 books 를 left join 하나:
--   memos.book_id 는 nullable 이다. inner join 으로 바꾸면 책 없는 메모가
--   키워드 검색에서 통째로 사라진다. 지금은 0건이지만 스키마가 허용하는 이상 언젠가 생긴다.
create or replace function public.search_my_memo_ids(
  p_query text,
  p_limit int default 20,
  p_offset int default 0
) returns table (memo_id uuid, matched_content boolean)
language sql stable security invoker set search_path = '' as $$
  with pat as (
    -- ILIKE 메타문자를 리터럴로 막는다. 순서 중요: 백슬래시를 먼저 늘려야 한다.
    select '%' || replace(replace(replace(p_query, '\', '\\'), '%', '\%'), '_', '\_') || '%' as p
  )
  select m.id, (m.content ilike pat.p)
  from public.memos m
  left join public.books b on b.id = m.book_id
  cross join pat
  where m.user_id = auth.uid()
    and (m.content ilike pat.p or b.title ilike pat.p or b.author ilike pat.p)
  -- 내가 쓴 말이 먼저. 책 제목만 걸린 메모는 그 뒤에 둔다.
  -- '타이탄'을 쳤을 때 그 책의 메모 30개가 내용 일치를 밀어내면 안 된다.
  order by (m.content ilike pat.p) desc, m.created_at desc
  limit p_limit offset p_offset;
$$;

-- security invoker 라 RLS 가 그대로 적용된다. auth.uid() 조건은 그 위의 이중 방어.
grant execute on function public.search_my_memo_ids(text, int, int) to authenticated;
