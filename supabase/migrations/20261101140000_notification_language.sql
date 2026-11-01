-- 푸시 문구 언어: 수신자가 앱에서 보는 언어로 알림을 보낸다.
-- 신규 칼럼 1개 (오늘 만든 notification_preferences 에만). 기존 테이블(users 등) 변경 없음.
-- nullable, 기본값 없음 -> 락은 메타데이터 변경 수준. null 이면 서버는 'ko' 로 본다.
-- RLS: 기존 notification_preferences 정책(본인 select/insert/update)이 그대로 적용된다.

alter table public.notification_preferences
  add column if not exists language text null;

alter table public.notification_preferences
  drop constraint if exists notification_preferences_language_check;
alter table public.notification_preferences
  add constraint notification_preferences_language_check
  check (language in ('ko', 'en', 'ja', 'zh'));

-- ROLLBACK (수동):
--   alter table public.notification_preferences drop constraint if exists notification_preferences_language_check;
--   alter table public.notification_preferences drop column if exists language;
