import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// 메인 앱 Shell
///
/// BottomNavigationBar와 FAB를 포함한 메인 레이아웃
class MainShell extends StatefulWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _navVisible = true;

  // 스크롤 방향에 따라 하단 네비를 부드럽게 숨김/표시 (일반적 모바일 UX).
  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final dir = n.direction;
    if (dir == ScrollDirection.reverse && _navVisible) {
      setState(() => _navVisible = false);
    } else if (dir == ScrollDirection.forward && !_navVisible) {
      setState(() => _navVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      // extendBody: 본문이 네비 뒤로 확장돼 은은한 블러가 걸림.
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _navVisible ? Offset.zero : const Offset(0, 1.6),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _navVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: _buildBottomNavigationBar(context),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentIndex = _getCurrentIndex(widget.location);

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
              // Layer 1: Backdrop Blur
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    // 깔끔한 반투명 다크(전 탭 동일). 약한 블러로 뒤 콘텐츠는 은은히
                    // 눌러 표시 - 초록 배너 등이 튀지 않게.
                    color: const Color(0xFF232323).withValues(alpha: 0.86),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
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
                        onTap: () => _onTabTapped(context, 0),
                      ),
                      _buildNavButton(
                        context: context,
                        icon: Icons.book_outlined,
                        activeIcon: Icons.book,
                        label: 'Books',
                        isActive: currentIndex == 1,
                        onTap: () => _onTabTapped(context, 1),
                      ),
                      _buildNavButton(
                        context: context,
                        icon: Icons.note_outlined,
                        activeIcon: Icons.note,
                        label: 'Memos',
                        isActive: currentIndex == 2,
                        onTap: () => _onTabTapped(context, 2),
                      ),
                      _buildNavButton(
                        context: context,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        isActive: currentIndex == 3,
                        onTap: () => _onTabTapped(context, 3),
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
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 가벼운 진동 피드백
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          // 클릭 영역을 넓히기 위해 최소 높이 설정 (보이지 않는 영역)
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 48, // 최소 터치 영역 (보이지 않는 영역 포함)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20, // 원래 크기로 복원
                  color: isActive
                      ? const Color(0xFFF3F3F3)
                      : const Color(0xFF757575),
                ),
                const SizedBox(height: 2),
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
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

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(AppRoutes.homeName);
        break;
      case 1:
        context.goNamed(AppRoutes.bookShelfName);
        break;
      case 2:
        context.goNamed(AppRoutes.memosName);
        break;
      case 3:
        context.goNamed(AppRoutes.profileName);
        break;
    }
  }
}
