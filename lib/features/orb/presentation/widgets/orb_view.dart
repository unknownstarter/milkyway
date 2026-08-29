import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/orb_tier.dart';
import 'orb_palette.dart';

/// 진화 은하 오브. 뒤 글로우가 호흡(펄스)하고 오브가 제자리에서 천천히 자전한다.
/// MVP: 단일 WebP 자산 통짜 저속 회전(1회전 24s). M2에서 galaxy/glass 레이어 분리 예정.
/// 성능: 컨트롤러 1개. animate=false면 정적(리스트/썸네일). 화면 이탈 시 상위에서 dispose.
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

class _OrbViewState extends State<OrbView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(OrbView old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = orbAccentOf(widget.tier);
    final asset = orbAssetPath(widget.tier);

    if (!widget.animate) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.asset(asset, fit: BoxFit.contain),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value; // 0..1
          final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi); // 0..1
          return Stack(
            alignment: Alignment.center,
            children: [
              // 뒤에서 빛나는 글로우(호흡)
              Container(
                width: widget.size * 0.82,
                height: widget.size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16 + 0.14 * pulse),
                      blurRadius: widget.size * (0.24 + 0.05 * pulse),
                      spreadRadius: widget.size * 0.01,
                    ),
                  ],
                ),
              ),
              // 오브 자전(통짜 저속)
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            ],
          );
        },
      ),
    );
  }
}
