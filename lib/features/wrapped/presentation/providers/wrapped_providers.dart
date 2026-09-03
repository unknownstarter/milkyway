import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../memos/domain/models/memo.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../orb/domain/orb_tier.dart';
import '../../../profile/presentation/providers/profile_stats_provider.dart';
import '../../../ranking/presentation/providers/ranking_providers.dart';
import '../../domain/wrapped_data.dart';

/// 은하 회고 데이터. 전부 기존 provider 조합(allMemos + ranking + profileStats).
/// 이번 달 메모가 없으면 가장 최근 메모가 있는 달로 폴백(빈 회고 방지).
final wrappedProvider = FutureProvider.autoDispose<WrappedData>((ref) async {
  // 병렬 로드.
  final memosF = ref.watch(allMemosProvider.future);
  final rankingF = ref.watch(myRankingProvider.future);
  final statsF = ref.watch(profileStatsProvider.future);

  final memos = await memosF;
  final ranking = await rankingF;
  final stats = await statsF;

  // 기간 결정: 이번 달, 없으면 가장 최근 메모의 달.
  final now = DateTime.now();
  var year = now.year;
  var month = now.month;

  List<Memo> within(int y, int mo) =>
      memos.where((m) => m.createdAt.year == y && m.createdAt.month == mo).toList();

  var period = within(year, month);
  if (period.isEmpty && memos.isNotEmpty) {
    final latest =
        memos.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
    year = latest.createdAt.year;
    month = latest.createdAt.month;
    period = within(year, month);
  }

  // 읽은 날(고유 일자).
  final readDays = period
      .map((m) => DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day))
      .toSet()
      .length;

  // 가장 오래 머문 책(기간 메모 최다).
  final byBook = <String, List<Memo>>{};
  for (final m in period) {
    (byBook[m.bookId] ??= []).add(m);
  }
  String? bookTitle;
  String? bookAuthor;
  String? bookCoverUrl;
  var bookMemoCount = 0;
  List<Memo> topBookMemos = const [];
  if (byBook.isNotEmpty) {
    final top = byBook.entries
        .reduce((a, b) => a.value.length >= b.value.length ? a : b);
    topBookMemos = top.value;
    final rep = topBookMemos.first;
    bookTitle = rep.bookTitle;
    bookAuthor = (rep.books['author'] as String?)?.trim();
    bookCoverUrl = (rep.books['cover_url'] as String?)?.trim();
    bookMemoCount = topBookMemos.length;
  }

  // 그 달의 문장: 최애 책 메모 우선, 읽기 좋은 길이 우선.
  String? quote;
  String? quoteBookTitle;
  final quoteSource = topBookMemos.isNotEmpty ? topBookMemos : period;
  final candidates = quoteSource
      .where((m) => m.content.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => _quoteScore(b.content).compareTo(_quoteScore(a.content)));
  if (candidates.isNotEmpty) {
    final q = candidates.first;
    quote = q.content.trim();
    quoteBookTitle = q.bookTitle;
  }

  // Lyra 물음: 그 달 메모에 붙은 것 중 최근.
  String? lyra;
  final withLyra = period
      .where((m) => (m.lyraQuestion ?? '').trim().isNotEmpty)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (withLyra.isNotEmpty) {
    lyra = withLyra.first.lyraQuestion!.trim();
  }

  return WrappedData(
    year: year,
    month: month,
    memoCount: period.length,
    readDays: readDays,
    topPercent: ranking.topPercent,
    bookTitle: bookTitle,
    bookAuthor: bookAuthor,
    bookCoverUrl: bookCoverUrl,
    bookMemoCount: bookMemoCount,
    quote: quote,
    quoteBookTitle: quoteBookTitle,
    lyra: lyra,
    tier: resolveOrbTier(stats.savedBooks, stats.memos).tier,
  );
});

/// 회고 인용 후보 점수. 너무 짧은 건 배제, 8~90자 구간을 선호.
double _quoteScore(String s) {
  final n = s.trim().runes.length;
  if (n < 8) return (-1000 + n).toDouble();
  if (n <= 90) return n.toDouble();
  return 90 - (n - 90) * 0.5;
}
