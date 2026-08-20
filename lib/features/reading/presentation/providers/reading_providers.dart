import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/reading_log.dart';
import '../../data/repositories/reading_repository.dart';

final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => ReadingRepository(Supabase.instance.client),
);

/// 특정 책을 오늘 읽음 기록했는지.
final readTodayProvider = FutureProvider.family<bool, String>(
  (ref, bookId) => ref.watch(readingRepositoryProvider).hasReadToday(bookId),
);

/// 내 전체 읽음 기록(캘린더 '책' 세그먼트/홈 스트립 소스).
final readingLogsProvider = FutureProvider<List<ReadingLog>>(
  (ref) => ref.watch(readingRepositoryProvider).getMyReadingLogs(),
);
