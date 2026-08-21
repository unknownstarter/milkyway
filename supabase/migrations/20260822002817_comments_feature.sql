-- 댓글 기능: 신규 테이블 3개 + RLS + 카운트 RPC
-- 기존 스키마 불변. memo_reports / user_hidden_memos 패턴 미러링, report_reason_type enum 재사용.

-- 1) comments
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  memo_id uuid not null references public.memos(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists comments_memo_created_idx on public.comments (memo_id, created_at);
create index if not exists comments_user_idx on public.comments (user_id);
alter table public.comments enable row level security;

-- SELECT: 볼 수 있는 메모(내것 또는 public)의 댓글만
create policy "comments_select" on public.comments for select
using (
  exists (
    select 1 from public.memos m
    where m.id = comments.memo_id
      and (m.user_id = auth.uid() or m.visibility = 'public')
  )
);
-- INSERT: 내 댓글 + 그 메모의 책을 내가 저장한 경우만 (저장 안 한 책이면 DB단 차단)
create policy "comments_insert" on public.comments for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.memos m
    join public.user_books ub on ub.book_id = m.book_id
    where m.id = comments.memo_id and ub.user_id = auth.uid()
  )
);
-- UPDATE/DELETE: 본인만
create policy "comments_update" on public.comments for update
using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "comments_delete" on public.comments for delete
using (auth.uid() = user_id);

-- 2) comment_reports (memo_reports 미러)
create table if not exists public.comment_reports (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.comments(id) on delete cascade,
  reporter_id uuid not null references public.users(id) on delete cascade,
  reason public.report_reason_type not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (comment_id, reporter_id)
);
create index if not exists comment_reports_comment_idx on public.comment_reports (comment_id);
alter table public.comment_reports enable row level security;
create policy "comment_reports_insert" on public.comment_reports for insert
  with check (auth.uid() = reporter_id);
create policy "comment_reports_select_own" on public.comment_reports for select
  using (auth.uid() = reporter_id);

-- 3) user_hidden_comments (user_hidden_memos 미러, 신고 즉시 내게만 숨김)
create table if not exists public.user_hidden_comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  comment_id uuid not null references public.comments(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, comment_id)
);
create index if not exists user_hidden_comments_user_idx on public.user_hidden_comments (user_id);
alter table public.user_hidden_comments enable row level security;
create policy "user_hidden_comments_insert" on public.user_hidden_comments for insert
  with check (auth.uid() = user_id);
create policy "user_hidden_comments_delete" on public.user_hidden_comments for delete
  using (auth.uid() = user_id);
create policy "user_hidden_comments_select" on public.user_hidden_comments for select
  using (auth.uid() = user_id);

-- 4) 댓글 수 일괄 조회 RPC (RLS 적용 - 볼 수 있는 메모의 댓글만 카운트)
create or replace function public.get_comment_counts(memo_ids uuid[])
returns table(memo_id uuid, cnt bigint)
language sql stable security invoker
set search_path = ''
as $$
  select c.memo_id, count(*)::bigint
  from public.comments c
  where c.memo_id = any(memo_ids)
  group by c.memo_id;
$$;

-- 5) memos에 comment_count computed column 노출 (PostgREST select 'comment_count'로 카드 카운트 1쿼리 처리)
create or replace function public.comment_count(m public.memos)
returns bigint
language sql stable security invoker
set search_path = ''
as $$
  select count(*)::bigint from public.comments c where c.memo_id = m.id;
$$;
