import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../memos/presentation/widgets/memo_card.dart';
import '../providers/selected_book_provider.dart';
import '../../../../core/router/app_routes.dart';

class RecentMemosSection extends ConsumerWidget {
  const RecentMemosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBookId = ref.watch(selectedBookIdProvider);

    // 선택된 책이 없을 때는 메모를 보여주지 않음
    if (selectedBookId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '책을 선택하면 메모를 쓰고 저장할 수 있어요',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ref.watch(paginatedMemosProvider(selectedBookId)).when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFECECEC)),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('불러오지 못했어',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => ref
                      .invalidate(paginatedMemosProvider(selectedBookId)),
                  child: const Text('다시 시도',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ],
            ),
          ),
          data: (memos) {
            if (memos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        AppRoutes.bookDetailName,
                        pathParameters: {'id': selectedBookId},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF48FF00),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      '메모하러 가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: memos.length,
              itemBuilder: (context, index) => MemoCard(memo: memos[index]),
            );
          },
        );
  }
}
