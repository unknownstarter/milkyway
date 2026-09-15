import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../orb/domain/orb_tier.dart';
import '../../../orb/presentation/orb_tier_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/label_budget.dart';
import '../../domain/universe_layout.dart';
import '../painters/galaxy_painter.dart';
import '../painters/glow_sprites.dart';
import '../providers/universe_providers.dart';
import '../widgets/universe_memo_card.dart';

/// 나의 우주 - 서재를 은하로 보는 탐험 화면.
///
/// 기존 '내 우주'(구슬 하나)와 공존한다. 이쪽은 책 한 권이 별 하나다.
/// 드래그로 돌리고 핀치로 당기며, 라벨은 줌에 따라 알아서 늘고 준다.
class UniverseScreen extends ConsumerStatefulWidget {
  const UniverseScreen({super.key});

  @override
  ConsumerState<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends ConsumerState<UniverseScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier(0);

  GalaxyCamera _cam = const GalaxyCamera();
  GlowSprites? _glow;

  // 관성. 손을 떼면 감쇠하다가 자동 회전으로 돌아간다.
  double _spinVel = 0;
  double _lastTick = 0;

  List<ProjectedStar> _projected = const [];
  final Map<String, double> _labelOpacity = {};
  String? _focusedId;

  /// 카메라 다이브 목표. 매 틱 여기로 부드럽게 간다. 도착하면 null.
  GalaxyCamera? _camTarget;

  /// 탭 리플(중심, 0~1 진행).
  Offset? _rippleAt;
  double _rippleT = 1;

  // 배경 별먼지는 고정 풀에서 앞에서부터 잘라 쓴다(메모가 수천 개여도 안 무너지게).
  late final List<Offset> _dustPool = _makeDust(620);

  static List<Offset> _makeDust(int n) {
    final r = math.Random(20260915);
    return List.generate(n, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('universe_screen');
    GlowSprites.create(
      kUniversePalette.map((v) => Color(v)).toList(),
    ).then((g) {
      if (mounted) setState(() => _glow = g);
    });
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = _lastTick == 0 ? 1 / 60 : (t - _lastTick).clamp(0.0, 0.05);
    _lastTick = t;

    // 관성 감쇠 후 자동 회전(0.6도/s)으로 복귀.
    const auto = 0.6 * math.pi / 180;
    _spinVel *= 0.92;
    final spin = _cam.spin + (_spinVel + auto) * dt;
    _cam = _cam.copyWith(spin: spin);

    // 카메라 다이브. 목표로 부드럽게 수렴한다.
    final tgt = _camTarget;
    if (tgt != null) {
      const k = 0.12;
      final ns = _cam.scale + (tgt.scale - _cam.scale) * k;
      final np = Offset.lerp(_cam.pan, tgt.pan, k)!;
      _cam = _cam.copyWith(scale: ns, pan: np);
      if ((tgt.scale - ns).abs() < 0.005 && (tgt.pan - np).distance < 1) {
        _camTarget = null;
      }
    }

    // 탭 리플 0.85초.
    if (_rippleT < 1) _rippleT = (_rippleT + dt / 0.85).clamp(0.0, 1.0);

    // 라벨 페이드는 _updateLabels 가 페인트 때마다 목표치로 민다.
    _frame.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _glow?.dispose();
    super.dispose();
  }

  /// 매 프레임 라벨 채택을 다시 계산하고 불투명도를 목표치로 민다.
  void _updateLabels(Size viewport) {
    if (_projected.isEmpty) return;
    final candidates = <LabelCandidate>[
      for (final p in _projected)
        if (p.star.named && p.star.title.isNotEmpty)
          LabelCandidate(
            id: p.star.id,
            screenX: p.screen.dx,
            screenY: p.screen.dy,
            // 라벨 상자 근사치. 정확한 측정은 페인터가 하지만 판정은 이걸로 충분하다.
            width: math.min(140, p.star.title.length * 12).toDouble(),
            height: 30,
            notes: p.star.notes,
          ),
    ];
    final picked = pickLabels(
      candidates,
      scale: _cam.scale,
      viewport: viewport,
      focusedId: _focusedId,
    ).toSet();

    const step = 0.12;
    for (final c in candidates) {
      final cur = _labelOpacity[c.id] ?? 0;
      final target = picked.contains(c.id) ? 1.0 : 0.0;
      final next = cur + (target - cur).clamp(-step, step);
      _labelOpacity[c.id] = next.clamp(0.0, 1.0);
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _spinVel = 0;
    _camTarget = null; // 손이 개입하면 자동 이동은 그만둔다.
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size size) {
    final dx = d.focalPointDelta.dx;
    final dy = d.focalPointDelta.dy;
    setState(() {
      _cam = _cam.copyWith(
        // 수평 드래그 = 축 회전. 화면 폭 기준으로 정규화.
        spin: _cam.spin - dx / size.width * 2.4,
        // 수직 드래그 = 원반 기울기.
        tilt: (_cam.tilt + dy / size.height * 1.6)
            .clamp(GalaxyCamera.minTilt, GalaxyCamera.maxTilt),
        scale: (_cam.scale * d.scale.clamp(0.98, 1.02))
            .clamp(GalaxyCamera.minScale, GalaxyCamera.maxScale),
      );
    });
    _spinVel = -dx / size.width * 2.4 * 8;
  }

  /// 별 탭 - 히트 영역은 시각적 크기보다 크게(최소 44pt).
  /// 촘촘한 구간에서는 가장 가까운 별을 고른다.
  void _onTapUp(TapUpDetails d, Size size) {
    _rippleAt = d.localPosition;
    _rippleT = 0;

    ProjectedStar? best;
    var bestDist = double.infinity;
    for (final p in _projected) {
      final dist = (p.screen - d.localPosition).distance;
      final hit = math.max(22.0, p.size * 1.6);
      if (dist < hit && dist < bestDist) {
        best = p;
        bestDist = dist;
      }
    }

    if (best == null) {
      // 빈 곳을 누르면 카드를 닫고 전체 보기로 돌아간다.
      if (_focusedId != null) {
        setState(() => _focusedId = null);
        _camTarget = _cam.copyWith(scale: 1, pan: Offset.zero);
      }
      return;
    }

    setState(() => _focusedId = best!.star.id);
    _dive(best, size);
    ref.read(analyticsProvider).logEvent('universe_star_tap', {
      'notes': best.star.notes,
    });
  }

  /// 별로 카메라를 끌고 간다. 카드가 아래를 덮으므로 별은 상단 38% 자리에 둔다.
  void _dive(ProjectedStar p, Size size) {
    final targetScale =
        (_cam.scale * 1.7).clamp(1.4, GalaxyCamera.maxScale).toDouble();
    final desired = Offset(size.width / 2, size.height * 0.38);
    // 투영이 pan 에 선형이라, pan=0 으로 한 번 투영해 필요한 이동량을 바로 구한다.
    final probe = _cam.copyWith(scale: targetScale, pan: Offset.zero);
    final at = projectWorld(p.star.x, p.star.y, probe, size);
    _camTarget = _cam.copyWith(scale: targetScale, pan: desired - at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(universeLayoutProvider);

    return Scaffold(
      backgroundColor: const Color(kUniverseBg),
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: Text(l10n.universeTitle, style: AppTypography.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen)),
        error: (_, __) => _error(l10n),
        data: (layout) => _body(l10n, layout),
      ),
    );
  }

  Widget _body(AppL10n l10n, UniverseLayout layout) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: (d) => _onScaleUpdate(d, size),
              onTapUp: (d) => _onTapUp(d, size),
              child: CustomPaint(
                painter: GalaxyPainter(
                  layout: layout,
                  camera: _cam,
                  glow: _glow,
                  labelOpacity: _labelOpacity,
                  focusedId: _focusedId,
                  ripple: _rippleT < 1 && _rippleAt != null
                      ? (_rippleAt!, _rippleT)
                      : null,
                  dust: _dustPool.take(layout.dust).toList(),
                  repaint: _frame,
                  onProjected: (p) {
                    _projected = p;
                    _updateLabels(size);
                  },
                ),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: glassTopPadding(context),
            child: _hud(l10n, layout),
          ),
          if (_focusedId != null) _memoCard(layout),
          if (layout.phase != UniversePhase.ready && _focusedId == null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xxl + MediaQuery.of(context).padding.bottom,
              child: _emptyGuide(l10n, layout.phase),
            ),
        ],
      );
    });
  }

  Widget _memoCard(UniverseLayout layout) {
    final star = layout.stars.where((s) => s.id == _focusedId).firstOrNull;
    if (star == null) return const SizedBox.shrink();
    final memos = ref.watch(universeBookMemosProvider(star.id));
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      child: UniverseMemoCard(
        title: star.title.isEmpty ? '-' : star.title,
        author: star.author,
        notes: star.notes,
        colorIndex: star.colorIndex,
        memos: memos.asData?.value ?? const [],
        onClose: () {
          setState(() => _focusedId = null);
          _camTarget = _cam.copyWith(scale: 1, pan: Offset.zero);
        },
        onOpenMemo: (m) => context.pushNamed(
          AppRoutes.memoDetailName,
          pathParameters: {'id': m.id},
        ),
        onWrite: () => context.pushNamed(
          AppRoutes.memoCreateName,
          queryParameters: {'bookId': star.id},
        ),
      ),
    );
  }

  Widget _hud(AppL10n l10n, UniverseLayout layout) {
    // 레벨은 앱의 오브 단계를 그대로 쓴다(핸드오프의 LV 표는 임시값이라고 명시됨).
    final pts = orbPoints(layout.totalBooks, layout.totalNotes);
    final info = resolveOrbTier(layout.totalBooks, layout.totalNotes);
    final name = orbTierName(l10n, info.tier);
    final idx = OrbTier.values.indexOf(info.tier);
    final next = idx < orbTiers.length - 1 ? orbTiers[idx + 1] : null;
    final band = next == null
        ? 1.0
        : ((pts - info.lo) / (next.lo - info.lo)).clamp(0.04, 1.0);

    return Column(
      children: [
        const Text('MY UNIVERSE',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 11,
              color: Color(0xFF7FE9FF),
              letterSpacing: 3,
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB98BFF).withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(name,
              style: AppTypography.label
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 210,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: band.toDouble(),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7FE9FF)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counter('${layout.totalBooks}', l10n.statBooksRead),
            const SizedBox(width: 44),
            _counter('${layout.totalNotes}', l10n.statMemosLeft),
          ],
        ),
      ],
    );
  }

  Widget _counter(String value, String label) => Column(
        children: [
          Text(value,
              style: TextStyle(
                // 숫자는 픽셀 폰트. 한글은 이 폰트에 없으니 라벨은 앱 폰트로 둔다.
                fontFamily: 'PressStart2P',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(color: const Color(0xFF7FE9FF).withValues(alpha: 0.6), blurRadius: 12),
                ],
              )),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      );

  /// 첫 진입 유도. 책이 없으면 책을, 책은 있는데 메모가 없으면 메모를.
  /// 은하가 이미 그 상태를 말해주고 있으므로(별이 없거나 다 흐리다) 문구는 짧게.
  Widget _emptyGuide(AppL10n l10n, UniversePhase phase) {
    final isNoBooks = phase == UniversePhase.noBooks;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isNoBooks ? l10n.universeEmptyBooksTitle : l10n.universeEmptyNotesTitle,
            style: AppTypography.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isNoBooks ? l10n.universeEmptyBooksBody : l10n.universeEmptyNotesBody,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentGreen.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
              onPressed: () {
                ref.read(analyticsProvider).logEvent('universe_empty_cta',
                    {'phase': isNoBooks ? 'no_books' : 'no_notes'});
                context.pushNamed(isNoBooks
                    ? AppRoutes.bookSearchName
                    : AppRoutes.memoCreateName);
              },
              child: Text(
                isNoBooks ? l10n.universeEmptyBooksCta : l10n.universeEmptyNotesCta,
                style: AppTypography.bodyBold
                    .copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
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
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => ref.invalidate(universeLayoutProvider),
                child: Text(l10n.commonRetry,
                    style: AppTypography.bodyBold
                        .copyWith(color: AppColors.accentGreen)),
              ),
            ],
          ),
        ),
      );
}
