import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/presentation/widgets/design/app_snackbar.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/star_background_painter.dart';
import '../../../orb/presentation/providers/orb_providers.dart';
import '../../domain/wrapped_data.dart';
import '../providers/wrapped_providers.dart';

/// 은하 회고: 전체 스크린(글래스 앱바 + 스타 배경 + 네이티브 회고 + 하단 공유).
/// 공유는 이미지 생성 없이 링크만 발행(OG 썸네일=책 표지).
class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  // 회고 시그니처색(밤하늘 보라).
  static const Color _accent = Color(0xFF8A7CFF);
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logEvent('wrapped_open');
  }

  TextStyle _num(double size, Color color) => TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * -0.03,
        height: 1.05,
        color: color,
      );

  Future<void> _share(WrappedData data) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final analytics = ref.read(analyticsProvider);
    try {
      // 이미지 생성/업로드 없음. 링크만 발행 -> OG 썸네일은 책 표지(cover_url)가 동적 반영.
      final repo = ref.read(shareRepositoryProvider);
      final link = await repo.publish(
        tier: data.tier,
        payload: {
          'kind': 'wrapped',
          'period': data.periodLabel,
          if (data.bookCoverUrl != null && data.bookCoverUrl!.isNotEmpty)
            'cover_url': data.bookCoverUrl,
        },
      );
      await Clipboard.setData(ClipboardData(text: link));
      analytics.logEvent('wrapped_share_completed', {'period': data.periodLabel});
      if (mounted) showAppSnackBar(context, AppL10n.of(context).wrappedShareLinkCopied);
      await SharePlus.instance.share(ShareParams(text: link));
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, AppL10n.of(context).wrappedShareError);
      }
      analytics.logError('ERR_SHARE', operation: 'wrapped_publish');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wrappedProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF08080E),
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: Text(AppL10n.of(context).wrappedTitle, style: AppTypography.title),
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
            error: (_, __) => _error(),
            data: (data) => data.hasEnough ? _content(data) : _empty(),
          ),
          async.maybeWhen(
            data: (data) => data.hasEnough
                ? Positioned(
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
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 현재 언어의 월 이름("8월" / "August" / "8月" / "八月").
  String _monthLabel(BuildContext context, WrappedData d) => DateFormat.MMMM(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(DateTime(d.year, d.month));

  Widget _content(WrappedData d) {
    final l10n = AppL10n.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, glassTopPadding(context) + AppSpacing.sm, AppSpacing.lg, 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge(d.periodLabel),
          const SizedBox(height: 18),
          RichText(
            text: TextSpan(
              style: _num(34, AppColors.textPrimary).copyWith(height: 1.18),
              children: [
                TextSpan(text: '${l10n.wrappedHeroLead(_monthLabel(context, d))}\n'),
                TextSpan(
                    text: l10n.wrappedHeroAccent,
                    style: const TextStyle(color: _accent)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.wrappedStarsLeft(d.memoCount), style: AppTypography.bodySmall),
          const SizedBox(height: 26),
          _statsPanel(l10n, d),
          if (d.bookTitle != null) ...[
            const SizedBox(height: 16),
            _bookCard(d),
          ],
          if (d.quote != null) ...[
            const SizedBox(height: 16),
            _quoteCard(d),
          ],
          if (d.lyra != null) ...[
            const SizedBox(height: 16),
            _lyraCard(d),
          ],
        ],
      ),
    );
  }

  Widget _badge(String period) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _accent.withValues(alpha: 0.5)),
        ),
        child: Text(period,
            style: AppTypography.label.copyWith(color: _accent, fontWeight: FontWeight.w700)),
      );

  Widget _statsPanel(AppL10n l10n, WrappedData d) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          _stat('${d.memoCount}', l10n.unitCount, l10n.wrappedStatSentences,
              AppColors.textPrimary),
          _statDiv(),
          _stat('${d.readDays}', l10n.unitDays, l10n.wrappedStatReadDays,
              AppColors.textPrimary),
          _statDiv(),
          _stat(d.topPercent != null ? '${d.topPercent}' : '-', '%',
              l10n.statTopPercent, _accent),
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

  Widget _panel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );

  Widget _coverPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A4A86), Color(0xFF20264A)],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.auto_stories_outlined, color: Colors.white.withValues(alpha: 0.35), size: 22),
      );

  Widget _bookCard(WrappedData d) => _panel(
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.cover),
            child: SizedBox(
              width: 56,
              height: 80,
              child: (d.bookCoverUrl != null && d.bookCoverUrl!.isNotEmpty)
                  ? CachedImage(
                      url: d.bookCoverUrl!,
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                      fallback: _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppL10n.of(context).wrappedTopBookLabel,
                    style: AppTypography.caption.copyWith(color: _accent, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(d.bookTitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitle),
                if ((d.bookAuthor ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(d.bookAuthor!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ]),
      );

  Widget _quoteCard(WrappedData d) => _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppL10n.of(context).wrappedQuoteLabel,
                style: AppTypography.caption.copyWith(color: _accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(d.quote!,
                style: AppTypography.body.copyWith(color: AppColors.textBright, height: 1.55)),
            if ((d.quoteBookTitle ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(AppL10n.of(context).wrappedQuoteSource(d.quoteBookTitle!),
                  style: AppTypography.caption),
            ],
          ],
        ),
      );

  Widget _lyraCard(WrappedData d) => _panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.auto_awesome, color: _accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(d.lyra!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.55)),
            ),
          ],
        ),
      );

  Widget _shareButton(WrappedData data) {
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
                : Text(AppL10n.of(context).wrappedShareCta,
                    style: AppTypography.bodyBold
                        .copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppL10n.of(context).wrappedEmptyTitle,
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(AppL10n.of(context).wrappedEmptyBody,
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _error() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppL10n.of(context).wrappedLoadErrorTitle,
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(AppL10n.of(context).wrappedLoadErrorBody,
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => ref.invalidate(wrappedProvider),
                child: Text(AppL10n.of(context).commonRetry,
                    style: AppTypography.bodyBold.copyWith(color: AppColors.accentGreen)),
              ),
            ],
          ),
        ),
      );
}
