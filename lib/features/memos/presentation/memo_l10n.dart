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
