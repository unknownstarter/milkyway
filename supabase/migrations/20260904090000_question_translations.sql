-- Lyra 물음 다국어: 한국어 정본은 그대로 두고 번역만 신규 테이블에 캐시.
-- 기존 테이블(book_questions/general_questions/memo_question_context) 스키마 불변.
-- 조회 RPC는 오버로드로 추가해 구버전 앱(무인자 호출)이 그대로 동작한다.

create table if not exists public.question_translations (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('book', 'general')),
  question_id uuid not null,          -- book_questions.id 또는 general_questions.id
  lang text not null check (lang in ('en', 'ja', 'zh')),
  question text not null,
  model text,
  created_at timestamptz not null default now(),
  unique (source, question_id, lang)
);

alter table public.question_translations enable row level security;

-- 읽기: 인증 사용자 전체. 쓰기 정책 없음 = 클라 차단, service role(Edge Function)만 삽입.
drop policy if exists question_translations_select_authenticated on public.question_translations;
create policy question_translations_select_authenticated
  on public.question_translations for select
  to authenticated
  using (true);

-- 홈 '다음 Lyra 물음' 언어별. 번역 없으면 한국어 정본으로 폴백(카드가 비지 않게).
create or replace function public.get_lyra_prompt(p_lang text)
returns table(source text, question_id uuid, question text, book_id uuid, book_title text)
language sql
stable
set search_path to ''
as $function$
  with answered as (
    select c.question_id
    from public.memo_question_context c
    join public.memos m on m.id = c.memo_id
    where m.user_id = auth.uid() and c.question_id is not null
  ),
  cands as (
    select 'book'::text src, bq.id qid,
           coalesce(t.question, bq.question) q,
           b.id bid, b.title bt, 0 pri
    from public.book_questions bq
    join public.user_books ub on ub.book_id = bq.book_id and ub.user_id = auth.uid()
    join public.books b on b.id = bq.book_id
    left join public.question_translations t
      on t.source = 'book' and t.question_id = bq.id and t.lang = p_lang
    where bq.is_active and bq.id not in (select question_id from answered)
    union all
    select 'general'::text src, gq.id qid,
           coalesce(t.question, gq.question) q,
           null::uuid bid, null::text bt, 1 pri
    from public.general_questions gq
    left join public.question_translations t
      on t.source = 'general' and t.question_id = gq.id and t.lang = p_lang
    where gq.is_active and gq.id not in (select question_id from answered)
  )
  select src, qid, q, bid, bt
  from cands
  order by pri, random()
  limit 1;
$function$;

-- 책 상세의 활성 물음 언어별(없으면 한국어 정본).
create or replace function public.get_book_question(p_book_id uuid, p_lang text)
returns table(id uuid, book_id uuid, question text, model text, created_at timestamptz)
language sql
stable
set search_path to ''
as $function$
  select bq.id, bq.book_id,
         coalesce(t.question, bq.question) as question,
         bq.model, bq.created_at
  from public.book_questions bq
  left join public.question_translations t
    on t.source = 'book' and t.question_id = bq.id and t.lang = p_lang
  where bq.book_id = p_book_id and bq.is_active
  limit 1;
$function$;

grant execute on function public.get_lyra_prompt(text) to authenticated;
grant execute on function public.get_book_question(uuid, text) to authenticated;
