import '../../../l10n/app_localizations.dart';
import '../data/models/recommended_book.dart';

/// 추천 책의 사회적 증거 문구 로컬라이저. 도메인은 숫자만 들고 있고
/// 표시 시점에만 현재 언어로 매핑한다(savers 우선).
String recommendedBookProof(AppL10n l, RecommendedBook book) {
  if (book.savers > 0) return l.discoveryProofSavers(book.savers);
  if (book.publicMemos > 0) return l.discoveryProofMemos(book.publicMemos);
  return l.discoveryProofNew;
}
