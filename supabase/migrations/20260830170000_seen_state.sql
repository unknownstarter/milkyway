-- 빨간점(seen/봤음) 상태를 기기 로컬(SharedPreferences) -> 서버로.
-- 재설치/기기변경에도 유지되게 유저별로 저장. 탭 뱃지 + 책별 점 + (추후)메모 전부 커버.
--   scope: 'tab'(key='books'|'memos') | 'book'(key=bookId) | 'memo'(key=memoId)
create table if not exists public.seen_state (
  user_id uuid not null references auth.users(id) on delete cascade,
  scope   text not null,
  key     text not null,
  seen_at timestamptz not null default now(),
  primary key (user_id, scope, key)
);

alter table public.seen_state enable row level security;

create policy seen_state_select on public.seen_state
  for select to authenticated using (auth.uid() = user_id);
create policy seen_state_insert on public.seen_state
  for insert to authenticated with check (auth.uid() = user_id);
create policy seen_state_update on public.seen_state
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 봤음 기록(upsert, 서버 now()). auth.uid()는 SECURITY DEFINER에서도 호출자 JWT 기준.
create or replace function public.mark_seen(p_scope text, p_key text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.seen_state(user_id, scope, key, seen_at)
  values (auth.uid(), p_scope, p_key, now())
  on conflict (user_id, scope, key) do update set seen_at = now();
$$;

grant execute on function public.mark_seen(text, text) to authenticated;
