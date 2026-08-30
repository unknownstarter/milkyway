import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/presentation/widgets/design/app_snackbar.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/star_background_painter.dart';
import '../../../orb/presentation/providers/orb_providers.dart';
import '../../domain/wrapped_data.dart';
import '../providers/wrapped_providers.dart';
import '../widgets/wrapped_card.dart';

/// 은하 회고: 전체 스크린(글래스 앱바 + 스타 배경 + 네이티브 회고 + 하단 공유).
/// 공유 카드(WrappedCard)는 화면에 안 띄우고 공유 시에만 오프스크린 캡처.
class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  static const Color _accent = WrappedCard.accent;
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
      final image = await _renderCardOffscreen(data);
      final repo = ref.read(shareRepositoryProvider);
      final jpg = await repo.encodeJpg(image);
      final link = await repo.publish(
        tier: data.tier,
        jpg: jpg,
        payload: {'kind': 'wrapped', 'period': data.periodLabel},
      );
      await Clipboard.setData(ClipboardData(text: link));
      analytics.logEvent('wrapped_share_completed', {'period': data.periodLabel});
      if (mounted) showAppSnackBar(context, '공유하기 링크가 복사되었어요');
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(jpg, mimeType: 'image/jpeg', name: 'milkyway_wrapped_${data.periodLabel}.jpg'),
        ],
        text: link,
      ));
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, '공유 준비 중 문제가 생겼어요. 잠시 후 다시 시도해요');
      }
      analytics.logError('ERR_SHARE', operation: 'wrapped_publish');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// 회고 카드를 화면 밖 1080x1350으로 렌더 -> 캡처.
  Future<ui.Image> _renderCardOffscreen(WrappedData data) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(0, MediaQuery.of(context).size.height + 200),
              child: RepaintBoundary(
                key: key,
                child: Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: WrappedCard.w,
                    height: WrappedCard.h,
                    child: WrappedCard(data: data),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await Future.delayed(const Duration(milliseconds: 260));
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      return await boundary.toImage(pixelRatio: 1.0);
    } finally {
      entry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wrappedProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF08080E),
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: const Text('은하 회고', style: AppTypography.title),
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

  Widget _content(WrappedData d) {
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
                TextSpan(text: '${d.monthLabel}, 네가\n'),
                const TextSpan(text: '멈춘 순간들', style: TextStyle(color: _accent)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('그 자리에 남은 ${d.memoCount}개의 별', style: AppTypography.bodySmall),
          const SizedBox(height: 26),
          _statsPanel(d),
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

  Widget _statsPanel(WrappedData d) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          _stat('${d.memoCount}', '개', '멈춘 문장', AppColors.textPrimary),
          _statDiv(),
          _stat('${d.readDays}', '일', '읽은 날', AppColors.textPrimary),
          _statDiv(),
          _stat(d.topPercent != null ? '${d.topPercent}' : '-', '%', '상위', _accent),
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

  Widget _bookCard(WrappedData d) => _panel(
        child: Row(children: [
          Container(
            width: 56,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.cover),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A4A86), Color(0xFF20264A)],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_stories_outlined, color: Colors.white.withValues(alpha: 0.35), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가장 오래 머문 책',
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
            Text('그 달의 문장',
                style: AppTypography.caption.copyWith(color: _accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(d.quote!,
                style: AppTypography.body.copyWith(color: AppColors.textBright, height: 1.55)),
            if ((d.quoteBook ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(d.quoteBook!, style: AppTypography.caption),
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
                : Text('회고 공유하기',
                    style: AppTypography.bodyBold
                        .copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('이번 달 회고는 아직 준비 중이에요',
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.sm),
              Text('메모를 남기면 그 자리에 별이 쌓여요',
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
              const Text('회고를 불러오지 못했어요',
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              const Text('잠시 후 다시 시도해요',
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => ref.invalidate(wrappedProvider),
                child: Text('다시 시도',
                    style: AppTypography.bodyBold.copyWith(color: AppColors.accentGreen)),
              ),
            ],
          ),
        ),
      );
}
