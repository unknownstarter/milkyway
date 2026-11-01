-- 알림 설정 + 책 메모 마일스톤 알림 + 방해 금지 시간 묶음 발송
-- 신규 테이블 4개만. 기존 테이블(users 등) 변경 없음.
-- 실유저 영향: 없음 (신규 테이블 생성 + cron 등록. 엣지 함수 배포 전까지 행이 쌓이지 않는다).

-- 1) 알림 설정 (본인만 접근). 행이 없으면 서버는 기본값(모두 true, Asia/Seoul)으로 본다.
create table if not exists public.notification_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  book_memos boolean not null default true,
  comments boolean not null default true,
  quiet_hours boolean not null default true,
  time_zone text not null default 'Asia/Seoul',
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences enable row level security;

create policy "notification_preferences_select_own"
  on public.notification_preferences for select
  using (auth.uid() = user_id);

create policy "notification_preferences_insert_own"
  on public.notification_preferences for insert
  with check (auth.uid() = user_id);

create policy "notification_preferences_update_own"
  on public.notification_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
-- delete 정책 없음 (users 삭제 시 cascade)

-- 2) 책 메모 마일스톤 (서버 전용: RLS 켜고 정책 없음 = 서비스 롤만)
create table if not exists public.book_memo_milestones (
  user_id uuid not null references public.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  last_milestone integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, book_id)
);

alter table public.book_memo_milestones enable row level security;

-- 3) 방해 금지 시간에 모아둔 알림 (서버 전용)
create table if not exists public.pending_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  kind text not null check (kind in ('comment', 'book_memo')),
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  deliver_after timestamptz not null,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

alter table public.pending_notifications enable row level security;

create index if not exists pending_notifications_due_idx
  on public.pending_notifications (deliver_after)
  where sent_at is null;

-- 4) 발송 기록 (서버 전용, 하루 상한 판정)
create table if not exists public.notification_sends (
  id bigserial primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  kind text not null,
  sent_at timestamptz not null default now()
);

alter table public.notification_sends enable row level security;

create index if not exists notification_sends_user_kind_sent_idx
  on public.notification_sends (user_id, kind, sent_at);

-- 5) 아침 묶음 발송 스케줄. 10분마다 엣지 함수를 부른다.
--    시크릿(vault 'deliver_pending_secret')은 스케줄된 SQL 안에서 읽는다.
--    시크릿이 없으면 null 헤더로 가서 함수가 401 을 돌려줄 뿐, 마이그레이션은 성공한다.
create extension if not exists pg_net;
create extension if not exists pg_cron;

select cron.schedule(
  'deliver-pending-notifications',
  '*/10 * * * *',
  $cron$
  select net.http_post(
    url := 'https://hyjgfgzexvxhgfmqgiqu.supabase.co/functions/v1/deliver-pending-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', coalesce(
        (select decrypted_secret from vault.decrypted_secrets
          where name = 'deliver_pending_secret' limit 1),
        ''
      )
    ),
    body := '{}'::jsonb
  );
  $cron$
);

-- ─────────────────────────────────────────────────────────────
-- ROLLBACK (down. 수동 적용. 모두 신규 객체라 기존 데이터 영향 없음)
-- ─────────────────────────────────────────────────────────────
-- select cron.unschedule('deliver-pending-notifications');
-- drop table if exists public.notification_sends;
-- drop table if exists public.pending_notifications;
-- drop table if exists public.book_memo_milestones;
-- drop table if exists public.notification_preferences;
-- (pg_net / pg_cron 확장은 다른 용도와 겹칠 수 있어 그대로 둔다)
