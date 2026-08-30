import '../../orb/domain/orb_tier.dart';

/// 은하 회고(Milky Wrapped) 한 달치 스냅샷. 기존 데이터 재조합(신규 수집/LLM 0).
///   - 멈춘 문장: 기간 내 메모 수
///   - 읽은 날: 메모 남긴 날(고유 일자)
///   - 상위%: 익명 백분위(ranking)
///   - 가장 오래 머문 책: 기간 메모를 책별로 묶어 최다
///   - 그 달의 문장: 기간 메모 중 대표 한 줄
///   - Lyra 물음: 그 달 메모에 붙은 Lyra 물음 스냅샷
class WrappedData {
  final int year;
  final int month; // 1..12

  final int memoCount; // 멈춘 문장
  final int readDays; // 읽은 날(고유 일자)
  final int? topPercent; // 상위 N% (없으면 null)

  final String? bookTitle; // 가장 오래 머문 책
  final String? bookAuthor;
  final int bookMemoCount; // 그 책에 남긴 메모 수

  final String? quote; // 그 달의 문장(대표 메모)
  final String? quoteBook; // 인용 출처('제목에서')

  final String? lyra; // Lyra 물음

  final OrbTier tier; // 공유 카드 발행용(전체 누적 기준)

  const WrappedData({
    required this.year,
    required this.month,
    required this.memoCount,
    required this.readDays,
    required this.topPercent,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookMemoCount,
    required this.quote,
    required this.quoteBook,
    required this.lyra,
    required this.tier,
  });

  /// 회고를 띄울 만큼의 기록이 있는지(빈 달 방지).
  bool get hasEnough => memoCount > 0;

  /// "2026.08"
  String get periodLabel =>
      '$year.${month.toString().padLeft(2, '0')}';

  /// "8월"
  String get monthLabel => '$month월';
}
