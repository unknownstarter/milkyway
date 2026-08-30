import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/orb_tier.dart';
import 'orb_palette.dart';
import 'orb_view.dart';

/// 진화 은하 오브(프래그먼트 셰이더). GPU 실시간 렌더로 유리/은하/안개를
/// 한 장의 .frag로 그린다. PNG 레이어(OrbView)를 대체.
///   - 셰이더 로드 전/실패 시 OrbView(PNG)로 자동 폴백(끊김 없음, 구형 렌더러 안전)
///   - RepaintBoundary로 형제(별 배경) 재페인트 격리
/// 설계: docs/design/06-ORB_RENDERING.md
class ShaderOrb extends StatefulWidget {
  final OrbTier tier;
  final double size;
  final bool animate;

  const ShaderOrb({
    super.key,
    required this.tier,
    this.size = 240,
    this.animate = true,
  });

  @override
  State<ShaderOrb> createState() => _ShaderOrbState();
}

class _ShaderOrbState extends State<ShaderOrb> with SingleTickerProviderStateMixin {
  // 프로그램은 앱 전체에서 1회만 로드(정적 캐시).
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;
  static bool _failed = false;

  Ticker? _ticker;
  final ValueNotifier<double> _clock = ValueNotifier<double>(3.0);

  @override
  void initState() {
    super.initState();
    _ensureProgram();
    if (widget.animate) _startTicker();
  }

  void _ensureProgram() {
    if (_program != null || _failed) return;
    _loading ??= ui.FragmentProgram.fromAsset('shaders/orb.frag');
    _loading!.then((p) {
      _program = p;
      if (mounted) setState(() {});
    }).catchError((_) {
      _failed = true;
      if (mounted) setState(() {});
    });
  }

  void _startTicker() {
    _ticker ??= createTicker((el) => _clock.value = el.inMicroseconds / 1e6);
    _ticker!.start();
  }

  @override
  void didUpdateWidget(ShaderOrb old) {
    super.didUpdateWidget(old);
    if (widget.animate && (_ticker == null || !_ticker!.isActive)) {
      _startTicker();
    } else if (!widget.animate && _ticker != null) {
      _ticker!.stop();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    // 셰이더 준비 전/실패 -> PNG 레이어로 폴백.
    if (_program == null) {
      return OrbView(tier: widget.tier, size: s, animate: widget.animate);
    }
    return RepaintBoundary(
      child: SizedBox(
        width: s,
        height: s,
        child: CustomPaint(
          painter: _OrbShaderPainter(
            program: _program!,
            tier: widget.tier,
            clock: _clock,
            animate: widget.animate,
          ),
        ),
      ),
    );
  }
}

class _OrbShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final OrbTier tier;
  final ValueNotifier<double> clock;
  final bool animate;

  _OrbShaderPainter({
    required this.program,
    required this.tier,
    required this.clock,
    required this.animate,
  }) : super(repaint: clock);

  static const double _twoPi = 2 * math.pi;
  // 회전(0.26)/트윙클(2.0) 둘 다 심리스하게 감기는 주기: 100π초.
  //   0.26*100π = 13*2π, 2.0*100π = 100*2π → 래핑 시 점프 없음.
  static const double _period = 100 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = orbAccentOf(tier);
    final core = Color.lerp(Colors.white, accent, 0.12)!;
    final idx = OrbTier.values.indexOf(tier);
    const arms = [0.0, 0.0, 2.0, 2.0, 3.0, 4.0];
    const density = [0.5, 0.7, 0.85, 1.0, 1.15, 1.3];
    final seed = idx * 3.0;

    final raw = animate ? clock.value : 3.0;
    final uTime = animate ? raw % _period : 3.0;
    final uGlow = animate ? 0.5 + 0.5 * math.sin((raw % 2.8) / 2.8 * _twoPi) : 0.7;

    final sh = program.fragmentShader();
    sh.setFloat(0, size.width);
    sh.setFloat(1, size.height);
    sh.setFloat(2, uTime);
    sh.setFloat(3, uGlow);
    sh.setFloat(4, accent.r);
    sh.setFloat(5, accent.g);
    sh.setFloat(6, accent.b);
    sh.setFloat(7, core.r);
    sh.setFloat(8, core.g);
    sh.setFloat(9, core.b);
    sh.setFloat(10, arms[idx]);
    sh.setFloat(11, density[idx]);
    sh.setFloat(12, seed);

    canvas.drawRect(Offset.zero & size, Paint()..shader = sh);
  }

  @override
  bool shouldRepaint(_OrbShaderPainter old) =>
      old.tier != tier || old.animate != animate;
}
