import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/memo_report_repository.dart';
import '../../domain/models/report_reason.dart';
import 'memo_provider.dart'; // paginatedPublicBookMemosProvider import

final memoReportRepositoryProvider = Provider((ref) {
  return MemoReportRepository(Supabase.instance.client);
});

/// 사용자가 숨긴 메모 ID 목록 (캐시)
///
/// 신고한 메모는 자동으로 숨겨지므로, 숨긴 메모 목록만 조회하면 됩니다.
/// 오류를 빈 집합으로 삼키면 신고한 메모가 다시 보인다. 오류는 그대로 전파하고
/// 소비처가 직전 값을 유지한다.
final hiddenMemoIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repository = ref.watch(memoReportRepositoryProvider);
  return repository.getHiddenMemoIds();
});

/// 메모 신고 파라미터 타입 (bookId 추가)
typedef ReportMemoParams = ({
  String memoId,
  String bookId, // 메모 리스트 리로딩을 위해 필요
  ReportReason reason,
  String? description,
});

/// 메모 신고 동작. 부를 때마다 repository 를 새로 친다(결과 캐시 없음).
final reportMemoActionProvider =
    Provider<Future<void> Function(ReportMemoParams params)>(
  (ref) => (params) async {
    await ref.read(memoReportRepositoryProvider).reportMemo(
          memoId: params.memoId,
          reason: params.reason,
          description: params.description,
        );

    // 신고 후 캐시 무효화
    ref.invalidate(hiddenMemoIdsProvider);

    // 공개 메모 리스트 리로딩 (신고한 메모가 즉시 사라지도록)
    ref
        .read(paginatedPublicBookMemosProvider(params.bookId).notifier)
        .loadInitialMemos();
  },
);
