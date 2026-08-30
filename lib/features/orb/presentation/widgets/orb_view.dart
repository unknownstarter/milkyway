import 'package:flutter/material.dart';

import '../../domain/orb_tier.dart';
import 'orb_palette.dart';

/// 진화 은하 오브. 레이어 합성:
///   - 뒤 글로우: 네이티브 BoxShadow가 밝아졌다 어두워졌다 호흡(breathe)
///   - 회전 은하(core): 제자리에서 천천히 자전
///   - 고정 유리(glass): 스펙큘러/림 하이라이트는 광원 고정(안 돎)
/// RepaintBoundary로 감싸 애니메이션이 형제(별 배경 등)를 재페인트시키지 않게 격리.
class OrbView extends StatefulWidget {
  final OrbTier tier;
  final double size;
  final bool animate;

  const OrbView({
    super.key,
    required this.tier,
    this.size = 240,
    this.animate = true,
  });

  @override
  State<OrbView> createState() => _OrbViewState();
}

class _OrbViewState extends State<OrbView> with TickerProviderStateMixin {
  late final AnimationController _rot;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(vsync: this, duration: const Duration(seconds: 24));
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    if (widget.animate) {
      _rot.repeat();
      _glow.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OrbView old) {
    super.didUpdateWidget(old);
    if (widget.animate) {
      if (!_rot.isAnimating) _rot.repeat();
      if (!_glow.isAnimating) _glow.repeat(reverse: true);
    } else {
      _rot.stop();
      _glow.stop();
    }
  }

  @override
  void dispose() {
    _rot.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = orbAccentOf(widget.tier);
    final core = orbCoreAsset(widget.tier);
    final glass = orbGlassAsset(widget.tier);
    final s = widget.size;

    Widget coreLayer = Image.asset(core, fit: BoxFit.contain);
    if (widget.animate) {
      coreLayer = RotationTransition(turns: _rot, child: coreLayer);
    }

    return RepaintBoundary(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 뒤 글로우(호흡)
            AnimatedBuilder(
              animation: _glow,
              builder: (context, _) {
                final p = widget.animate ? _glow.value : 0.5; // 0..1
                return Container(
                  width: s * 0.56,
                  height: s * 0.56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18 + 0.30 * p),
                        blurRadius: s * (0.18 + 0.12 * p),
                        spreadRadius: s * 0.03,
                      ),
                    ],
                  ),
                );
              },
            ),
            coreLayer,
            Image.asset(glass, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
