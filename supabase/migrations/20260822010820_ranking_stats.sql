-- Phase 4: 랭킹(익명 백분위 + 성장). 집계값만 반환(PII 없음).
-- SECURITY DEFINER: 전체 메모 정확 집계(타 유저 private 포함) 위해 RLS 우회.
--   반환은 내 통계 + 익명 백분위뿐이라 데이터 유출 없음. anon 실행 차단.
create or replace function public.get_my_ranking()
returns table(
  this_week_memos int,
  last_week_memos int,
  delta int,
  top_percent int,     -- 상위 N% (낮을수록 상위). 이번 주 메모 없으면 null
  active_users int,    -- 이번 주 메모 남긴 유저 수(맥락)
  streak_days int      -- 오늘/어제부터 연속 읽은 날 수
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_week_start timestamptz :=
    date_trunc('week', (now() at time zone 'Asia/Seoul')) at time zone 'Asia/Seoul';
  v_prev_start timestamptz := v_week_start - interval '7 days';
  v_this int; v_last int; v_ahead int; v_total int; v_top int; v_streak int := 0;
  v_day date;
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  select count(*) into v_this from public.memos
    where user_id = v_uid and created_at >= v_week_start;
  select count(*) into v_last from public.memos
    where user_id = v_uid and created_at >= v_prev_start and created_at < v_week_start;

  with weekly as (
    select user_id, count(*) c from public.memos
    where created_at >= v_week_start group by user_id
  )
  select count(*) into v_total from weekly;
  select count(*) into v_ahead from (
    select user_id, count(*) c from public.memos
    where created_at >= v_week_start group by user_id
  ) w where w.c > v_this;

  if v_this > 0 and v_total > 0 then
    v_top := ceil((v_ahead + 1)::numeric / v_total * 100);
  else
    v_top := null;
  end if;

  v_day := (now() at time zone 'Asia/Seoul')::date;
  if not exists (select 1 from public.reading_logs where user_id = v_uid and read_on = v_day) then
    v_day := v_day - 1;
  end if;
  loop
    exit when not exists (select 1 from public.reading_logs where user_id = v_uid and read_on = v_day);
    v_streak := v_streak + 1;
    v_day := v_day - 1;
  end loop;

  return query select v_this, v_last, (v_this - v_last), v_top, v_total, v_streak;
end;
$$;

revoke execute on function public.get_my_ranking() from public, anon;
grant execute on function public.get_my_ranking() to authenticated;
