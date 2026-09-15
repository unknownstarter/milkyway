import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 글로우 스프라이트 캐시.
///
/// 별마다 실시간 blur 를 걸면 수백 개에서 프레임이 무너진다. 색깔별로 글로우를
/// **한 번 구워두고 크기만 바꿔 그린다**(핸드오프 Performance 절 지시).
class GlowSprites {
  final List<ui.Image> images;
  const GlowSprites._(this.images);

  static const int _size = 96;

  static Future<GlowSprites> create(List<Color> colors) async {
    final out = <ui.Image>[];
    for (final c in colors) {
      out.add(await _bake(c));
    }
    return GlowSprites._(out);
  }

  static Future<ui.Image> _bake(Color color) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const r = _size / 2.0;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, _size.toDouble(), _size.toDouble()));
    canvas.drawCircle(const Offset(r, r), r, paint);
    return recorder.endRecording().toImage(_size, _size);
  }

  ui.Image operator [](int i) => images[i % images.length];

  void dispose() {
    for (final i in images) {
      i.dispose();
    }
  }
}
