import '../../../l10n/app_localizations.dart';
import '../domain/models/memo_filter.dart';
import '../domain/models/memo_visibility_filter.dart';
import '../domain/models/report_reason.dart';

/// 메모 도메인 enum 표시명 로컬라이저. enum 자체는 언어 중립(DB 값/analytics는 value 사용),
/// 표시 시점에만 현재 언어로 매핑.
String reportReasonLabel(AppL10n l, ReportReason r) {
  switch (r) {
    case ReportReason.spam:
      return l.reportReasonSpam;
    case ReportReason.inappropriate:
      return l.reportReasonInappropriate;
    case ReportReason.harassment:
      return l.reportReasonHarassment;
    case ReportReason.sexual:
      return l.reportReasonSexual;
    case ReportReason.violence:
      return l.reportReasonViolence;
    case ReportReason.copyright:
      return l.reportReasonCopyright;
    case ReportReason.other:
      return l.reportReasonOther;
  }
}

String memoFilterLabel(AppL10n l, MemoFilter f) {
  switch (f) {
    case MemoFilter.myMemos:
      return l.memoFilterWrittenByMe;
    case MemoFilter.all:
      return l.memoFilterAllMemos;
  }
}

String memoVisibilityFilterLabel(AppL10n l, MemoVisibilityFilter f) {
  switch (f) {
    case MemoVisibilityFilter.all:
      return l.memoFilterAllMemos;
    case MemoVisibilityFilter.public:
      return l.memoVisibilityPublic;
    case MemoVisibilityFilter.private:
      return l.memoFilterPrivate;
  }
}

/// 메모 카드에 쓰는 상대 시각. 7일이 넘으면 절대 날짜로 떨어진다.
/// 메모 목록과 메모 검색이 같은 표기를 쓰도록 여기로 모았다.
String memoRelativeDate(AppL10n l, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l.memoTimeJustNow;
  if (diff.inMinutes < 60) return l.memoTimeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.memoTimeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l.memoTimeDaysAgo(diff.inDays);
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '${dt.year}.$m.$d';
}
