-- Phase 3: Lyra 흐름 (일반 질문 + 답 스냅샷 + 다음 질문)
-- 기존 스키마 불변. book_questions(책 단위)는 유지, 일반 질문은 신규 테이블.

-- 1) general_questions: 책과 무관한 홈 Lyra 질문 풀
create table if not exists public.general_questions (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.general_questions enable row level security;
create policy "general_questions_select_authenticated" on public.general_questions
  for select using (true);

-- 2) memo_question_context: 메모가 어떤 Lyra 질문에 답한 것인지 스냅샷
create table if not exists public.memo_question_context (
  memo_id uuid primary key references public.memos(id) on delete cascade,
  source text not null check (source in ('book','general')),
  question_id uuid,
  question_text text not null,
  created_at timestamptz not null default now()
);
create index if not exists memo_question_context_qid_idx
  on public.memo_question_context (question_id);
alter table public.memo_question_context enable row level security;
create policy "mqc_select" on public.memo_question_context for select
using (
  exists (select 1 from public.memos m
          where m.id = memo_question_context.memo_id
            and (m.user_id = auth.uid() or m.visibility = 'public'))
);
create policy "mqc_insert" on public.memo_question_context for insert
with check (
  exists (select 1 from public.memos m
          where m.id = memo_question_context.memo_id and m.user_id = auth.uid())
);

-- 3) memos에 lyra_question computed column
create or replace function public.lyra_question(m public.memos)
returns text
language sql stable security invoker
set search_path = ''
as $$
  select question_text from public.memo_question_context c where c.memo_id = m.id;
$$;

-- 4) 다음 Lyra 질문 1개: 내가 아직 답 안 한 활성 질문(책>일반 우선, 랜덤)
create or replace function public.get_lyra_prompt()
returns table(source text, question_id uuid, question text, book_id uuid, book_title text)
language sql stable security invoker
set search_path = ''
as $$
  with answered as (
    select c.question_id
    from public.memo_question_context c
    join public.memos m on m.id = c.memo_id
    where m.user_id = auth.uid() and c.question_id is not null
  ),
  cands as (
    select 'book'::text src, bq.id qid, bq.question q, b.id bid, b.title bt, 0 pri
    from public.book_questions bq
    join public.user_books ub on ub.book_id = bq.book_id and ub.user_id = auth.uid()
    join public.books b on b.id = bq.book_id
    where bq.is_active and bq.id not in (select question_id from answered)
    union all
    select 'general'::text src, gq.id qid, gq.question q, null::uuid bid, null::text bt, 1 pri
    from public.general_questions gq
    where gq.is_active and gq.id not in (select question_id from answered)
  )
  select src, qid, q, bid, bt
  from cands
  order by pri, random()
  limit 1;
$$;

grant execute on function public.get_lyra_prompt() to authenticated;

-- 5) 일반 질문 시딩 (Lyra 톤: 반말/다정, AI 금지기호 없음, '당신' 금지)
insert into public.general_questions (question) values
('요즘 네 마음을 가장 오래 붙잡는 문장은 뭐야? 그게 왜 지금 너한테 왔을까?'),
('읽다가 책을 덮고 한참 멍해진 적 있어? 그때 네 안에서 뭐가 흔들렸을까?'),
('요즘 자꾸 미루게 되는 생각이 하나 있다면, 어떤 책이 그걸 건드려줬으면 좋겠어?'),
('딱 한 권을 누군가에게 건네야 한다면 뭘 고를래? 그 사람한테 무슨 말이 하고 싶은 거야?'),
('오늘 읽은 것 중에 내일의 너를 조금 바꿀 문장이 있었어?'),
('책 속의 나와 살아가는 나 사이, 요즘 얼마나 가까운 것 같아?'),
('요즘 가장 답을 찾고 싶은 물음은 뭐야? 어떤 페이지에서 실마리를 봤어?'),
('다 읽고도 마음에 남는 인물이 있어? 그 사람의 어떤 선택이 너랑 닮았을까?');
