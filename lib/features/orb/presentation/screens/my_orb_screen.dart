import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/presentation/widgets/design/app_snackbar.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/star_background_painter.dart';
import '../../domain/orb_tier.dart';
import '../../domain/share_payload.dart';
import '../orb_tier_l10n.dart';
import '../providers/orb_providers.dart';
import '../widgets/orb_palette.dart';
import '../widgets/shader_orb.dart';

/// 내 우주: 진짜 앱 스크린(글래스 앱바 + 스타 배경 + 네이티브 애니메이션 오브 + 스탯).
/// 공유는 이미지 생성 없이 링크만 발행(OG 썸네일=정적 오브 이미지).
class MyOrbScreen extends ConsumerStatefulWidget {
  const MyOrbScreen({super.key});

  @override
  ConsumerState<MyOrbScreen> createState() => _MyOrbScreenState();
}

class _MyOrbScreenState extends ConsumerState<MyOrbScreen> {
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logEvent('share_card_open');
  }

  TextStyle _num(double size, Color color) => TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * -0.03,
        height: 1.05,
        color: color,
      );

  Future<void> _share(OrbShareData data) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final analytics = ref.read(analyticsProvider);
    try {
      // 이미지 생성/업로드 없음. 링크만 발행 -> OG 썸네일은 정적 오브 이미지가 동적 반영.
      final repo = ref.read(shareRepositoryProvider);
      final link = await repo.publish(tier: data.tier);
      await Clipboard.setData(ClipboardData(text: link));
      analytics.logEvent('share_completed', {'tier': data.tier.name});
      if (mounted) showAppSnackBar(context, AppL10n.of(context).orbShareLinkCopied);
      await SharePlus.instance.share(ShareParams(text: link));
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, AppL10n.of(context).orbShareError);
      }
      analytics.logError('ERR_SHARE', operation: 'publish');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orbShareDataProvider);
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF08080E),
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: Text(l10n.orbMyUniverseTitle, style: AppTypography.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: StarBackgroundPainter(numberOfStars: 150)),
            ),
          ),
          async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
            error: (_, __) => _error(l10n),
            data: (data) => _content(l10n, data),
          ),
          async.maybeWhen(
            data: (data) => Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                      AppSpacing.md + MediaQuery.of(context).padding.bottom),
                  child: _shareButton(data),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _content(AppL10n l10n, OrbShareData data) {
    final accent = orbAccentOf(data.tier);
    return LayoutBuilder(
      builder: (context, constraints) {
        final name = orbTierName(l10n, data.tier);
        // 오브를 화면 높이에 맞춰 반응형: 큰 폰은 340 그대로, 작은 폰만 살짝 축소(최소 290).
        // -> 스크롤 없이 딱 맞고, 오브가 하단 공유 버튼을 가리지 않는다.
        final orbSize =
            (constraints.maxHeight * 0.40).clamp(290.0, 340.0).toDouble();
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg,
              glassTopPadding(context) + AppSpacing.sm, AppSpacing.lg, 104),
          child: Column(
            children: [
              ShaderOrb(tier: data.tier, size: orbSize, animate: true),
              const SizedBox(height: 20),
              _badge(l10n, name, accent),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: l10n.orbNowPrefix,
                      style: _num(32, AppColors.textPrimary)),
                  TextSpan(text: name, style: _num(32, accent)),
                ]),
              ),
              const SizedBox(height: 20),
              _statsPanel(l10n, data, accent),
              const SizedBox(height: 14),
              _progress(l10n, data, accent),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(AppL10n l10n, String name, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(l10n.orbTierBadge(name), style: AppTypography.label.copyWith(color: accent, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _statsPanel(AppL10n l10n, OrbShareData d, Color accent) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          _stat('${d.books}', l10n.unitBooks, l10n.statBooksRead,
              AppColors.textPrimary),
          _statDiv(),
          _stat('${d.memos}', l10n.unitCount, l10n.statMemosLeft,
              AppColors.textPrimary),
          _statDiv(),
          _stat('${d.topPercent ?? '-'}', '%', l10n.statTopPercent, accent),
          _statDiv(),
          _stat('${d.streakDays}', l10n.unitDays, l10n.statStreak,
              AppColors.textPrimary),
        ]),
      );

  Widget _stat(String value, String unit, String label, Color color) => Expanded(
        child: Column(children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(text: value, style: _num(26, color)),
              TextSpan(
                  text: unit,
                  style: AppTypography.caption.copyWith(
                      color: AppColors.textBright, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 7),
          Text(label, style: AppTypography.caption),
        ]),
      );

  Widget _statDiv() =>
      Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.08));

  Widget _progress(AppL10n l10n, OrbShareData d, Color accent) {
    final pts = orbPoints(d.books, d.memos);
    final idx = OrbTier.values.indexOf(d.tier);
    final curLo = orbTierInfo(d.tier).lo;
    final nextLo = idx < orbTiers.length - 1 ? orbTiers[idx + 1].lo : null;
    final nextName = idx < orbTiers.length - 1
        ? orbTierName(l10n, orbTiers[idx + 1].tier)
        : null;
    final band = nextLo != null ? ((pts - curLo) / (nextLo - curLo)).clamp(0.04, 1.0) : 1.0;
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: band.toDouble(),
          minHeight: 8,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation(accent),
        ),
      ),
      const SizedBox(height: 12),
      nextName != null
          ? RichText(
              text: TextSpan(style: AppTypography.bodySmall, children: [
                TextSpan(text: l10n.orbToNextTier(nextName)),
                TextSpan(
                    text: '${d.pointsToNext}',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
              ]),
            )
          : Text(l10n.orbDeepestReached, style: AppTypography.bodySmall),
    ]);
  }

  Widget _shareButton(OrbShareData data) {
    return GestureDetector(
      onTap: _sharing ? null : () => _share(data),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.45)),
            ),
            child: _sharing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen),
                  )
                : Text(AppL10n.of(context).commonShare,
                    style: AppTypography.bodyBold
                        .copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _error(AppL10n l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.orbLoadErrorTitle,
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.wrappedLoadErrorBody,
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => ref.invalidate(orbShareDataProvider),
                child: Text(l10n.commonRetry,
                    style: AppTypography.bodyBold.copyWith(color: AppColors.accentGreen)),
              ),
            ],
          ),
        ),
      );
}
