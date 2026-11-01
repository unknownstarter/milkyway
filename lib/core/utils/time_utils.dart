/// 서버(timestamptz)로 보내는 현재 시각. 반드시 UTC ('Z' 로 끝남).
/// 시간대 표시 없는 현지 시각을 보내면 Postgres 가 UTC 로 해석해 시각이 어긋난다.
String nowUtcIso() => DateTime.now().toUtc().toIso8601String();
