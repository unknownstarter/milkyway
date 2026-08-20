-- 읽음 트래킹: 메모가 없어도 "읽은 날"을 기록(신규 테이블, 기존 스키마 불변).
-- 하루에 같은 책 1개 로그(unique). 메모 작성 시 자동 upsert + 책 상세 "오늘 읽음" 토글.
create table if not exists public.reading_logs (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  read_on date not null default (timezone('utc', now()))::date,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, book_id, read_on)
);

create index if not exists idx_reading_logs_user_date
  on public.reading_logs(user_id, read_on);

alter table public.reading_logs enable row level security;

-- 본인 것만 조회/기록/삭제
drop policy if exists reading_logs_select on public.reading_logs;
create policy reading_logs_select on public.reading_logs
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists reading_logs_insert on public.reading_logs;
create policy reading_logs_insert on public.reading_logs
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists reading_logs_delete on public.reading_logs;
create policy reading_logs_delete on public.reading_logs
  for delete to authenticated using (auth.uid() = user_id);
