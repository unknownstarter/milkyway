import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/presentation/widgets/design/app_snackbar.dart';
import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/share_payload.dart';
import '../providers/orb_providers.dart';
import '../widgets/share_card.dart';

/// 내 우주: 성장 카드 프리뷰 + 공유. 카드를 1080x1350로 캡처 -> JPG -> 발행 -> 공유 시트.
class MyOrbScreen extends ConsumerStatefulWidget {
  const MyOrbScreen({super.key});

  @override
  ConsumerState<MyOrbScreen> createState() => _MyOrbScreenState();
}

class _MyOrbScreenState extends ConsumerState<MyOrbScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logEvent('share_card_open');
  }

  Future<void> _share(OrbShareData data) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final analytics = ref.read(analyticsProvider);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final repo = ref.read(shareRepositoryProvider);
      final jpg = await repo.encodeJpg(image);
      final link = await repo.publish(tier: data.tier, jpg: jpg);
      analytics.logEvent('share_completed', {'tier': data.tier.name});
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(jpg, mimeType: 'image/jpeg', name: 'milkyway_${data.tier.name}.jpg'),
        ],
        text: link,
      ));
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, '공유 준비 중 문제가 생겼어요. 잠시 후 다시 시도해요');
      }
      analytics.logError('ERR_SHARE', operation: 'publish');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orbShareDataProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('내 우주', style: AppTypography.title),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
          error: (_, __) => _error(),
          data: (data) => Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: SizedBox(
                          width: ShareCard.w,
                          height: ShareCard.h,
                          child: ShareCard(data: data),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                PrimaryButton(
                  label: '공유하기',
                  loading: _sharing,
                  onPressed: () => _share(data),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _error() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('우주를 불러오지 못했어요',
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              const Text('잠시 후 다시 시도해요',
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              GhostButton(
                label: '다시 시도',
                onPressed: () => ref.invalidate(orbShareDataProvider),
              ),
            ],
          ),
        ),
      );
}
