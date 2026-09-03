import '../../../l10n/app_localizations.dart';
import '../../home/domain/models/book_status.dart';

/// 책 상태 표시명 로컬라이저. enum의 `value`는 DB 저장값이라 한국어 그대로 두고,
/// 화면에 그릴 때만 현재 언어로 매핑한다(홈·책탭·상세 공용).
String bookStatusLabel(AppL10n l, BookStatus status) {
  switch (status) {
    case BookStatus.wantToRead:
      return l.bookStatusWantToRead;
    case BookStatus.reading:
      return l.bookStatusReading;
    case BookStatus.completed:
      return l.bookStatusCompleted;
  }
}
