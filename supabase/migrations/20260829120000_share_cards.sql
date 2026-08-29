-- 공유 카드 + 내부 숏튼(short-link). 오브/성장 카드 공유 기능.
-- 기존 테이블 스키마 변경 없음(신규 테이블만). 상세: docs/design/05-SHARE_ORB_SPEC.md

create table if not exists public.share_cards (
  code        text primary key,                        -- 6자 base62 숏튼 코드(링크 최단화)
  user_id     uuid not null references auth.users(id) on delete cascade,
  tier        text not null,                           -- 't1'..'t6'
  image_path  text not null,                           -- storage 경로: {uid}/{code}.jpg
  payload     jsonb,                                   -- 스탯/연결 스냅샷(선택)
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists share_cards_user_id_idx on public.share_cards(user_id);

alter table public.share_cards enable row level security;

-- 본인만 생성/수정/조회. 공개 링크 조회는 Edge Function(service_role)이 RLS 우회.
drop policy if exists "share_cards own insert" on public.share_cards;
create policy "share_cards own insert" on public.share_cards
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "share_cards own update" on public.share_cards;
create policy "share_cards own update" on public.share_cards
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "share_cards own select" on public.share_cards;
create policy "share_cards own select" on public.share_cards
  for select to authenticated using (auth.uid() = user_id);

-- updated_at 자동 갱신
create or replace function public.tg_share_cards_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists share_cards_updated_at on public.share_cards;
create trigger share_cards_updated_at before update on public.share_cards
  for each row execute function public.tg_share_cards_updated_at();

-- public 버킷(메모 이미지와 동일 정책: public + getPublicUrl, 서명 URL 금지)
insert into storage.buckets (id, name, public)
values ('share_cards', 'share_cards', true)
on conflict (id) do nothing;

-- 공개 읽기 + 본인 폴더({uid}/...)만 쓰기
drop policy if exists "share_cards storage public read" on storage.objects;
create policy "share_cards storage public read" on storage.objects
  for select using (bucket_id = 'share_cards');
drop policy if exists "share_cards storage owner insert" on storage.objects;
create policy "share_cards storage owner insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'share_cards' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "share_cards storage owner update" on storage.objects;
create policy "share_cards storage owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'share_cards' and (storage.foldername(name))[1] = auth.uid()::text);
