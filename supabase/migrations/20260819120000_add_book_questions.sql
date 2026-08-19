-- N3 Lyra 물음 엔진: 책별 자동 생성 물음 저장 (신규 테이블, 기존 스키마 변경 없음)
create table if not exists public.book_questions (
  id uuid primary key default extensions.uuid_generate_v4(),
  book_id uuid not null references public.books(id) on delete cascade,
  question text not null,
  model text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_book_questions_book_id on public.book_questions(book_id);
-- 책당 활성 물음 1개만 허용
create unique index if not exists uq_book_questions_active
  on public.book_questions(book_id) where is_active;

alter table public.book_questions enable row level security;

-- 읽기: 인증 사용자 전체(공개 피드 콘텐츠). 쓰기 정책 없음 = 클라 차단, service role(Edge Function)만 삽입.
drop policy if exists book_questions_select_authenticated on public.book_questions;
create policy book_questions_select_authenticated
  on public.book_questions for select
  to authenticated
  using (true);
