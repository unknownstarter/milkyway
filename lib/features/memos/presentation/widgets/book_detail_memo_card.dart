import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/models/memo.dart';
import '../../domain/models/memo_visibility.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/report_memo_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// 책 상세 화면과 메모 리스트 화면에서 사용하는 메모 카드 컴포넌트
/// 
/// 이미지 유무를 자동으로 감지하여 적절한 레이아웃으로 표시
class BookDetailMemoCard extends ConsumerWidget {
  final Memo memo;
  final double cardWidth;

  const BookDetailMemoCard({
    super.key,
    required this.memo,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = memo.imageUrl != null && memo.imageUrl!.isNotEmpty;
    // 현재 사용자 ID는 read로 가져와서 불필요한 rebuild 방지
    final currentUserId = ref.read(authProvider).value?.id;
    final isPublicMemo = memo.visibility == MemoVisibility.public;
    final isOtherUserMemo = currentUserId != null && memo.userId != currentUserId;
    final showReportMenu = isPublicMemo && isOtherUserMemo; // 공개 메모이고 다른 유저의 메모일 때만 표시

    return GestureDetector(
      onTap: () => context.pushNamed(
            AppRoutes.memoDetailName,
            pathParameters: {'id': memo.id},
          ),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(bottom: 40),
        padding: EdgeInsets.zero, // memo_list_view에서 이미 패딩 적용됨
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 메모 카드 내용 (원래 구조 유지)
            hasImage
                ? _buildMemoCardWithImage(context, memo)
                : _buildMemoCardTextOnly(context, memo),
            // 케밥 메뉴 (우측 상단, 공개 메모이고 다른 유저의 메모일 때만)
            // memo_list_view의 패딩(20px)을 고려하여 위치 조정
            if (showReportMenu)
              Positioned(
                top: 0,
                right: 0,
                child: _buildKebabMenu(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  /// 케밥 메뉴 위젯 (우측 상단)
  Widget _buildKebabMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: Color(0xFF838383),
        size: 20,
      ),
      color: const Color(0xFF242424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (value) {
        if (value == 'report') {
          _showReportBottomSheet(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppL10n.of(context).reportAction,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 신고 바텀시트 표시
  void _showReportBottomSheet(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppL10n.of(context).reportAction,
      barrierColor: Colors.black.withOpacity(0.5),
      useRootNavigator: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // 바텀시트 내부 탭은 무시
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF313131),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ReportMemoBottomSheet(memo: memo),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 텍스트만 있는 메모 카드
  Widget _buildMemoCardTextOnly(BuildContext context, Memo memo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          _buildUserInfo(memo),
          const SizedBox(height: 16),
          // 메모 내용
          Text(
            memo.content,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 16),
          // 책 제목 및 페이지
          _buildBookInfo(context, memo),
        ],
      ),
    );
  }

  /// 이미지가 있는 메모 카드
  Widget _buildMemoCardWithImage(BuildContext context, Memo memo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          _buildUserInfo(memo),
          const SizedBox(height: 16),
          // 메모 내용 및 이미지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  memo.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 15),
              // 이미지 (80x120)
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade900,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(
                    url: memo.imageUrl,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    fallback: Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade900,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 책 제목 및 페이지
          _buildBookInfo(context, memo),
        ],
      ),
    );
  }

  /// 사용자 정보 위젯 (아바타, 닉네임, 시간)
  Widget _buildUserInfo(Memo memo) {
    return Row(
      children: [
        // 아바타
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade800,
          ),
          child: ClipOval(
            child: memo.userAvatarUrl != null &&
                    memo.userAvatarUrl!.isNotEmpty
                ? CachedImage(
                    url: memo.userAvatarUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    fallback: const Icon(Icons.person, color: Colors.grey),
                  )
                : const Icon(Icons.person, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        // 닉네임 및 시간
        Expanded(
          child: Row(
            children: [
              Text(
                memo.userNickname ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(memo.createdAt, locale: 'ko'),
                style: const TextStyle(
                  color: Color(0xFF838383),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 책 제목 및 페이지 정보 위젯
  Widget _buildBookInfo(BuildContext context, Memo memo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: Text(
              memo.bookTitle,
              style: const TextStyle(
                color: Color(0xFF838383),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                height: 24 / 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (memo.page != null)
          Text(
            'p ${memo.page}',
            style: const TextStyle(
              color: Color(0xFF838383),
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
      ],
    );
  }
}

