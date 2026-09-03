import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/providers/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/presentation/widgets/design/avatar.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/presentation/widgets/language_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_stats_provider.dart';
import '../../domain/profile_stats.dart';
import '../widgets/feedback_modal.dart';
import '../widgets/notification_settings_tile.dart';

/// 나 탭 = 마이페이지. 프로필 + 내 기록(담은 책/남긴 메모/완독) + 메뉴.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('profile_screen');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // CASE C(타이틀 없음): 상태바 영역만 순수 블러(StatusBarBlur). 콘텐츠는 상태바 아래에서
      // 시작하고, 상태바 뒤로 스크롤될 때만 노치 영역에서 흐려진다.
      body: Stack(
        children: [
          userAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.textSecondary, strokeWidth: 2),
            ),
            error: (e, st) => Center(
              child: Text('불러오지 못했어요',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            data: (user) => user == null
                ? Center(
                    child: Text('로그인이 필요해요',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  )
                : ListView(
                    padding: EdgeInsets.only(
                        top: statusBarTop(context), bottom: 110),
                    children: [
                      _profileRow(context, user),
                      _statsCard(ref),
                      _menuGroup(context, ref),
                      const SizedBox(height: 22),
                      _footer(),
                    ],
                  ),
          ),
          const Positioned(
              top: 0, left: 0, right: 0, child: StatusBarBlur()),
        ],
      ),
    );
  }

  Widget _profileRow(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Avatar(
            imageUrl: user?.pictureUrl as String?,
            initial: user?.nickname as String?,
            size: AvatarSize.md,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.nickname ?? '',
                    style: AppTypography.subtitle
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => context.pushNamed(AppRoutes.profileEditName),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('프로필 편집', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(WidgetRef ref) {
    final async = ref.watch(profileStatsProvider);
    final stats = async.asData?.value ??
        const ProfileStats(savedBooks: 0, completedBooks: 0, memos: 0);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내 기록',
              style: AppTypography.label
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('${stats.savedBooks}', '담은 책'),
              _stat('${stats.memos}', '남긴 메모'),
              _stat('${stats.completedBooks}', '완독한 책'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String n, String c) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
                color: Colors.white,
              )),
          const SizedBox(height: 8),
          Text(c, style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _menuGroup(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const NotificationSettingsTile(),
          const Divider(color: AppColors.divider, height: 1),
          _menuRow(Icons.chat_bubble_outline, '의견 보내기',
              () => _showFeedbackModal(context)),
          const Divider(color: AppColors.divider, height: 1),
          _menuRow(Icons.description_outlined, '이용약관',
              () => _launchTerms()),
          const Divider(color: AppColors.divider, height: 1),
          _menuRow(Icons.language_outlined,
              AppL10n.of(context).settingsLanguage, () => _showLanguageSheet()),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Text('앱 버전', style: AppTypography.body),
                const Spacer(),
                FutureBuilder<String>(
                  future: _appVersion(),
                  builder: (context, snap) => Text(
                    'v${snap.data ?? ''}',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Text(label, style: AppTypography.body),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Center(
      child: Text('milkyway',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
    );
  }

  void _showFeedbackModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '피드백 모달',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final h = MediaQuery.of(context).size.height;
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: h * 0.5,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: const FeedbackModal(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchTerms() async {
    final url = Uri.parse(
        'https://whatisgoingon.notion.site/1838cdd370538097b80bfa3b9a6fe2b7?pvs=4');
    // canLaunchUrl은 Android 11+ 패키지 가시성 때문에 false를 잘못 반환하는 일이 잦다.
    // 게이트 없이 바로 외부 브라우저로 열고, 실패 시에만 플랫폼 기본 모드로 폴백.
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) await launchUrl(url);
    } catch (_) {
      await launchUrl(url);
    }
  }

  void _showLanguageSheet() => showLanguageSheet(context, ref);

  Future<String> _appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
