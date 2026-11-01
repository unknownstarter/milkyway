-- 2026-11-01 메모 작성 시각 시간대 오류 복구 (마스터 승인, 운영에 MCP 로 적용 끝: repair_memo_timezone_skew_20261101)
-- 앱이 현지 시각을 시간대 표시 없이 보내 UTC 로 저장됐다 (한국 +9h 17개, 미국 서부 -7h 5개).
-- memo_embeddings.created_at (서버 now()) 과 정확히 정수 시간 차이 (오차 10분 이내) 인 메모만 고친다.
-- 원래 값은 memo_time_repair_backup_20261101 에 있다. 되돌리기:
--   update memos m set created_at = b.old_created_at, updated_at = b.old_updated_at
--   from memo_time_repair_backup_20261101 b where m.id = b.memo_id;
create table if not exists public.memo_time_repair_backup_20261101 (
  memo_id uuid primary key,
  old_created_at timestamptz not null,
  old_updated_at timestamptz,
  hours_off int not null,
  repaired_at timestamptz not null default now()
);
alter table public.memo_time_repair_backup_20261101 enable row level security;

with d as (
  select m.id, m.created_at, m.updated_at,
         round(extract(epoch from (m.created_at - e.created_at))/3600)::int as h,
         abs(extract(epoch from (m.created_at - e.created_at))
             - round(extract(epoch from (m.created_at - e.created_at))/3600)*3600) as residual_s
  from public.memos m
  join public.memo_embeddings e on e.memo_id = m.id
), targets as (
  select id, created_at, updated_at, h from d
  where h <> 0 and abs(h) <= 14 and residual_s < 600
), backed as (
  insert into public.memo_time_repair_backup_20261101 (memo_id, old_created_at, old_updated_at, hours_off)
  select id, created_at, updated_at, h from targets
  on conflict (memo_id) do nothing
  returning memo_id, hours_off
)
update public.memos m
set created_at = m.created_at - make_interval(hours => b.hours_off),
    updated_at = case when m.updated_at is null then null
                      else m.updated_at - make_interval(hours => b.hours_off) end
from backed b
where m.id = b.memo_id;
