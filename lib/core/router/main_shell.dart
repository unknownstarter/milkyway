import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../presentation/widgets/add_floating_action_button.dart';
import '../providers/seen_tracker_provider.dart';
import '../services/seen_tracker.dart';
import '../../features/constellation/presentation/widgets/connection_reveal.dart';
import '../../features/books/presentation/providers/books_tab_badge_provider.dart';
import '../../features/memos/presentation/providers/memos_tab_badge_provider.dart';

/// 메인 앱 Shell
///
/// BottomNavigationBar와 FAB를 포함한 메인 레이아웃
class MainShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _getCurrentIndex(location);
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      // extendBody: 본문이 네비 뒤로 확장돼 유리 뒤로 콘텐츠가 블러되어 비침.
      extendBody: true,
      // 연결이 생기면(memo_edges insert) 어느 탭이든 조용히 Lyra 리빌을 띄운다(push).
      body: ConnectionRevealListener(child: child),
      // FAB를 네비와 같은 Scaffold에 둬서 Flutter가 네비 위에 자동 정렬(겹침/가림 없음).
      // 홈/책 탭에서만 노출.
      floatingActionButton: (index == 0 || index == 1 || index == 2)
          ? const AddFloatingActionButton()
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(context, ref),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, WidgetRef ref) {
    final currentIndex = _getCurrentIndex(location);
    // 점 계산: 저장책에 안 본 남의 새 공개 메모 / 메모탭 새 활동.
    // autoDispose provider라 탭 이동/재빌드 때 자연스럽게 재계산(폴링 없음).
    final booksHasNew =
        ref.watch(booksTabHasNewProvider).asData?.value ?? false;
    final memosHasNew =
        ref.watch(memosTabHasNewProvider).asData?.value ?? false;

    // 배경 불투명 채움 없음(투명) — 콘텐츠가 네비 뒤로 비쳐 블러됨.
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          child: DecoratedBox(
            // Layer 5: Shadow (떠있는 깊이감)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              // Layer 1: Backdrop Blur (원복 - momo 방식 화이트 프로스트)
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    // 투명 유리 - 불투명 배경 없음. 블러된 콘텐츠가 뒤로 비침(momo 방식).
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildNavButton(
                        context: context,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => _onTabTapped(context, ref, 0),
                      ),
                      _buildNavButton(
                        context: context,
                        icon: Icons.book_outlined,
                        activeIcon: Icons.book,
                        label: 'Books',
                        isActive: currentIndex == 1,
                        showDot: booksHasNew,
                        onTap: () => _onTabTapped(context, ref, 1),
                      ),
                      _buildNavButton(
                        context: context,
                        icon: Icons.note_outlined,
                        activeIcon: Icons.note,
                        label: 'Memos',
                        isActive: currentIndex == 2,
                        showDot: memosHasNew,
                        onTap: () => _onTabTapped(context, ref, 2),
                      ),
                      _buildNavButton(
                        context: context,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        isActive: currentIndex == 3,
                        onTap: () => _onTabTapped(context, ref, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return Expanded(
      // InkWell 물결/하이라이트 사각형이 유리 바 밖으로 튀어나가서 GestureDetector로 교체.
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 48, // 최소 터치 영역
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      size: 20, // 원래 크기로 복원
                      color: isActive
                          ? const Color(0xFFF3F3F3)
                          : const Color(0xFF757575),
                    ),
                    if (showDot)
                      Positioned(
                        top: -2,
                        right: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF181818),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: isActive
                          ? const Color(0xFFF3F3F3)
                          : const Color(0xFF757575),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.books)) return 1;
    if (location.startsWith(AppRoutes.memos)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onTabTapped(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.goNamed(AppRoutes.homeName);
        break;
      case 1:
        // 탭 진입 = 이 탭의 새 것들을 '봤음'으로 처리 → 점 제거.
        _markTabSeen(ref, SeenTracker.tabBooks, booksTabHasNewProvider);
        context.goNamed(AppRoutes.bookShelfName);
        break;
      case 2:
        _markTabSeen(ref, SeenTracker.tabMemos, memosTabHasNewProvider);
        context.goNamed(AppRoutes.memosName);
        break;
      case 3:
        context.goNamed(AppRoutes.profileName);
        break;
    }
  }

  /// 탭 진입 시 해당 탭 last-seen을 갱신하고 점 provider를 무효화한다.
  void _markTabSeen(
    WidgetRef ref,
    String tabKey,
    ProviderOrFamily badgeProvider,
  ) {
    ref
        .read(seenTrackerProvider)
        .markTabSeen(tabKey)
        .then((_) => ref.invalidate(badgeProvider));
  }
}
