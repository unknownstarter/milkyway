-- 사유의 커넥톰(별자리): 임베딩 사이드카 + 메모 엣지. 기존 스키마 불변(전부 신규).
create extension if not exists vector;
do $$ begin
  create type public.memo_rel_type as enum ('similar','extends','reverses','echo');
exception when duplicate_object then null; end $$;
create table if not exists public.memo_embeddings (
  memo_id uuid primary key references public.memos(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  embedding vector(1024) not null, model text not null, dim int not null default 1024,
  content_hash text, created_at timestamptz not null default now());
create index if not exists memo_embeddings_hnsw on public.memo_embeddings
  using hnsw (embedding vector_cosine_ops) with (m=16, ef_construction=64);
create index if not exists memo_embeddings_user_idx on public.memo_embeddings (user_id);
alter table public.memo_embeddings enable row level security;
create policy "memo_embeddings_select_own" on public.memo_embeddings for select using (user_id = auth.uid());
create table if not exists public.memo_edges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  memo_a uuid not null references public.memos(id) on delete cascade,
  memo_b uuid not null references public.memos(id) on delete cascade,
  rel_type public.memo_rel_type, strength real not null, rationale text,
  status text not null default 'active' check (status in ('active','dismissed')),
  created_at timestamptz not null default now(),
  constraint memo_edges_order check (memo_a < memo_b),
  constraint memo_edges_uniq unique (memo_a, memo_b));
create index if not exists memo_edges_user_idx on public.memo_edges (user_id, status);
create index if not exists memo_edges_memo_a_idx on public.memo_edges (memo_a);
create index if not exists memo_edges_memo_b_idx on public.memo_edges (memo_b);
alter table public.memo_edges enable row level security;
create policy "memo_edges_select_own" on public.memo_edges for select using (user_id = auth.uid());
create policy "memo_edges_update_own_dismiss" on public.memo_edges for update
  using (user_id = auth.uid()) with check (user_id = auth.uid() and status in ('active','dismissed'));
create table if not exists public.seed_sentences (
  id uuid primary key default gen_random_uuid(), text text not null,
  embedding vector(1024), is_active boolean not null default true,
  created_at timestamptz not null default now());
alter table public.seed_sentences enable row level security;
create policy "seed_sentences_select_auth" on public.seed_sentences for select using (true);
create or replace function public.match_memos(p_memo_id uuid, p_k int default 5, p_threshold real default 0.6)
returns table(memo_b uuid, strength real) language sql stable security definer set search_path = '' as $$
  with src as (select e.user_id, e.embedding from public.memo_embeddings e where e.memo_id = p_memo_id)
  select me.memo_id, (1 - (me.embedding OPERATOR(public.<=>) src.embedding))::real
  from public.memo_embeddings me, src
  where me.user_id = src.user_id and me.memo_id <> p_memo_id
    and (1 - (me.embedding OPERATOR(public.<=>) src.embedding)) >= p_threshold
  order by me.embedding OPERATOR(public.<=>) src.embedding limit p_k;
$$;
revoke execute on function public.match_memos(uuid,int,real) from public, anon, authenticated;
create or replace function public.get_constellation(node_limit int default 60)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with my_edges as (select id, memo_a, memo_b, rel_type, strength, rationale from public.memo_edges
    where user_id = auth.uid() and status = 'active' and strength >= 0.5 order by strength desc limit 300),
  node_ids as (select memo_a as mid from my_edges union select memo_b from my_edges),
  nodes as (select m.id, left(m.content, 80) as preview, m.book_id, m.created_at from public.memos m
    where m.id in (select mid from node_ids) and m.user_id = auth.uid() order by m.created_at desc limit node_limit)
  select jsonb_build_object('nodes', coalesce((select jsonb_agg(nodes) from nodes),'[]'::jsonb),
    'edges', coalesce((select jsonb_agg(my_edges) from my_edges),'[]'::jsonb));
$$;
grant execute on function public.get_constellation(int) to authenticated;
