-- 의견 보내기. 기존 mailto(메일앱 없으면 실패)를 서버 저장으로 대체.
-- 운영자는 대시보드/서비스롤로 조회. 유저는 본인 것만 insert.
create table if not exists public.feedback (
  id          bigserial primary key,
  user_id     uuid references auth.users(id) on delete set null,
  content     text not null,
  email       text,
  device_id   text,
  os          text,
  app_version text,
  created_at  timestamptz not null default now()
);

alter table public.feedback enable row level security;

create policy feedback_insert on public.feedback
  for insert to authenticated with check (auth.uid() = user_id);
