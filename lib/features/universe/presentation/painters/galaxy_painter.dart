import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/label_budget.dart';
import '../../domain/universe_layout.dart';
import '../../domain/universe_math.dart';
import 'glow_sprites.dart';

/// 카메라. 드래그로 돌리고 핀치로 당긴다.
class GalaxyCamera {
  /// 은하 축 회전(라디안).
  final double spin;

  /// 원반 기울기. 20도(거의 정면) ~ 70도(거의 눕힘).
  final double tilt;

  /// 확대 배율.
  final double scale;

  /// 화면 중심에서의 이동(픽셀).
  final Offset pan;

  const GalaxyCamera({
    this.spin = 0,
    this.tilt = 0.9,
    this.scale = 1,
    this.pan = Offset.zero,
  });

  GalaxyCamera copyWith({double? spin, double? tilt, double? scale, Offset? pan}) =>
      GalaxyCamera(
        spin: spin ?? this.spin,
        tilt: tilt ?? this.tilt,
        scale: scale ?? this.scale,
        pan: pan ?? this.pan,
      );

  static const double minTilt = 0.35; // 20도
  static const double maxTilt = 1.22; // 70도
  static const double minScale = 0.5;
  static const double maxScale = 2.5;
}

/// 별 하나의 화면 좌표. 히트 테스트와 라벨 배치가 같은 값을 쓴다.
class ProjectedStar {
  final PlacedStar star;
  final Offset screen;
  final double size;
  ProjectedStar(this.star, this.screen, this.size);
}

/// 은하 렌더러.
///
/// 레이어(아래->위): 성운 -> 별먼지 -> 별자리 선 -> 익명 별 -> 책 아이콘 -> 코어
/// -> 라벨. 라벨 채택은 [pickLabels] 가 매 프레임 판정하고, 여기서는 [labelOpacity]
/// 로 받은 값만 그린다(깜빡임 방지는 화면 쪽 애니메이션 책임).
class GalaxyPainter extends CustomPainter {
  final UniverseLayout layout;
  final GalaxyCamera camera;
  final GlowSprites? glow;

  /// 별 id -> 라벨 불투명도(0~1). 화면이 매 프레임 보간해서 넘긴다.
  final Map<String, double> labelOpacity;

  final String? focusedId;

  /// 배경 별먼지(고정 풀). 화면이 한 번 만들어 넘긴다.
  final List<Offset> dust;

  /// 투영된 별 목록을 화면에 돌려준다(히트 테스트/라벨 후보용).
  final void Function(List<ProjectedStar>)? onProjected;

  GalaxyPainter({
    required this.layout,
    required this.camera,
    required this.labelOpacity,
    required this.dust,
    this.glow,
    this.focusedId,
    this.onProjected,
    required Listenable repaint,
  }) : super(repaint: repaint);

  Color _paletteColor(int i) => Color(kUniversePalette[i % kUniversePalette.length]);

  /// 월드(디자인 좌표계 중심 기준) -> 화면.
  Offset _project(double wx, double wy, Size size, double unit) {
    final c = math.cos(camera.spin), s = math.sin(camera.spin);
    final rx = wx * c - wy * s;
    final ry = wx * s + wy * c;
    // 원반을 눕힌다. tilt 가 클수록 y 가 납작해진다.
    final fy = ry * math.cos(camera.tilt);
    return Offset(
      size.width / 2 + camera.pan.dx + rx * unit,
      size.height / 2 + camera.pan.dy + fy * unit,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(kUniverseBg));

    // 디자인 좌표(1080 기준)를 화면 폭에 맞춘 단위. 여기에 줌을 곱한다.
    final unit = (size.width / kDesignWidth) * camera.scale;
    final center = Offset(size.width / 2 + camera.pan.dx, size.height / 2 + camera.pan.dy);

    _paintNebula(canvas, size, center, unit);
    _paintDust(canvas, size);

    final projected = <ProjectedStar>[];
    for (final st in layout.stars) {
      final p = _project(st.x, st.y, size, unit);
      // 크기도 디자인 좌표(1080 기준)에서 재고 unit 으로 환산한다.
      // 화면 px 로 두면 기기마다 별 크기가 달라진다.
      final designSize = st.named ? 40.0 : 5.0 + (st.notes / 6).clamp(0, 5);
      final px = designSize * unit * st.depth;
      projected.add(ProjectedStar(st, p, math.max(px, st.named ? 9.0 : 1.6)));
    }
    onProjected?.call(projected);

    _paintConstellation(canvas, projected);

    // 뒤(깊이 작은 것)부터 그려야 앞뒤가 맞다.
    projected.sort((a, b) => a.star.depth.compareTo(b.star.depth));
    for (final p in projected) {
      if (p.star.named) {
        _paintBookIcon(canvas, p);
      } else {
        _paintAnonStar(canvas, p);
      }
    }

    _paintCore(canvas, center, unit);
    _paintLabels(canvas, size, projected);
  }

  void _paintNebula(Canvas canvas, Size size, Offset center, double unit) {
    final r = layout.maxRadius * unit * 1.25;
    if (r <= 0) return;
    for (var i = 0; i < 3; i++) {
      final c = _paletteColor(i);
      final off = Offset(
        center.dx + math.cos(i * 2.1) * r * 0.22,
        center.dy + math.sin(i * 2.1) * r * 0.14,
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: 0.16), c.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: off, radius: r));
      canvas.drawCircle(off, r, paint);
    }
  }

  void _paintDust(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.30);
    for (final d in dust) {
      canvas.drawCircle(Offset(d.dx * size.width, d.dy * size.height), 0.8, paint);
    }
  }

  /// 별자리 선. 라벨 붙는 책들을 메모 많은 순으로 잇는다.
  void _paintConstellation(Canvas canvas, List<ProjectedStar> projected) {
    final named = projected.where((p) => p.star.named).toList()
      ..sort((a, b) {
        final c = b.star.notes.compareTo(a.star.notes);
        return c != 0 ? c : a.star.id.compareTo(b.star.id);
      });
    if (named.length < 2) return;
    final path = Path()..moveTo(named.first.screen.dx, named.first.screen.dy);
    for (var i = 1; i < named.length; i++) {
      path.lineTo(named[i].screen.dx, named[i].screen.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _paletteColor(0).withValues(alpha: 0.22),
    );
  }

  void _drawGlow(Canvas canvas, Offset at, double radius, int colorIndex, double alpha) {
    final g = glow;
    if (g == null) return;
    final img = g[colorIndex];
    final dst = Rect.fromCenter(center: at, width: radius * 2, height: radius * 2);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dst,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
  }

  /// 이름 없는 별 - 45도 회전한 정사각형.
  void _paintAnonStar(Canvas canvas, ProjectedStar p) {
    final st = p.star;
    final c = _paletteColor(st.colorIndex);
    // 메모 0인 책은 흐리다. "담기만 한 책은 흐린 채로 남는다"(디자인 규칙).
    final lit = st.notes > 0;
    final alpha = lit ? (0.45 + (st.notes / 20).clamp(0, 0.5)) : 0.18;

    _drawGlow(canvas, p.screen, p.size * (lit ? 2.6 : 1.4), st.colorIndex,
        lit ? 0.5 : 0.18);

    canvas.save();
    canvas.translate(p.screen.dx, p.screen.dy);
    canvas.rotate(math.pi / 4);
    final s = p.size;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: s, height: s),
      Paint()..color = c.withValues(alpha: alpha.toDouble()),
    );
    canvas.restore();
  }

  /// 제목 붙는 책 - 도트 책 아이콘. 메모가 많을수록 밝다.
  void _paintBookIcon(Canvas canvas, ProjectedStar p) {
    final st = p.star;
    final c = _paletteColor(st.colorIndex);
    final focused = st.id == focusedId;
    final w = p.size, h = p.size * (54 / 40);

    // 메모가 많을수록 밝다(디자인: glow = 20 + min(notes,70)*0.5).
    _drawGlow(canvas, p.screen, w * 1.6 + math.min(st.notes, 70) * 0.25,
        st.colorIndex, focused ? 0.85 : 0.55);

    final rect = Rect.fromCenter(center: p.screen, width: w, height: h);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF100C22));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 2.4 : 1.6
        ..color = c.withValues(alpha: focused ? 1.0 : 0.9),
    );
    // 책등
    canvas.drawRect(
      Rect.fromLTWH(rect.left + w * 0.2, rect.top, w * 0.1, h),
      Paint()..color = c.withValues(alpha: 0.7),
    );
  }

  void _paintCore(Canvas canvas, Offset center, double unit) {
    final r = 120 * unit;
    if (r <= 0) return;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.30),
            _paletteColor(1).withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  void _paintLabels(Canvas canvas, Size size, List<ProjectedStar> projected) {
    for (final p in projected) {
      final o = labelOpacity[p.star.id] ?? 0;
      if (o <= 0.01 || p.star.title.isEmpty) continue;
      final c = _paletteColor(p.star.colorIndex);

      final title = TextPainter(
        text: TextSpan(
          text: p.star.title,
          style: TextStyle(
            color: const Color(0xFFEEF3FF).withValues(alpha: o),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        maxLines: 1,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 140);

      final notes = TextPainter(
        text: TextSpan(
          text: '${p.star.notes} NOTES',
          style: TextStyle(
            color: c.withValues(alpha: o * 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 화면 가장자리에서 잘리지 않게 가로만 밀어 넣는다(별 위치는 그대로).
      double clampX(double w) =>
          (p.screen.dx - w / 2).clamp(8.0, math.max(8.0, size.width - w - 8));
      final top = p.screen.dy + p.size + 6;
      title.paint(canvas, Offset(clampX(title.width), top));
      notes.paint(canvas, Offset(clampX(notes.width), top + title.height + 3));
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyPainter old) => true;
}
