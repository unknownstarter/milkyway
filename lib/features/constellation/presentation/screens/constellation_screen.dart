import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/constellation.dart';
import '../providers/constellation_providers.dart';

/// 별자리 화면 = 내 메모(별)와 관계(선)의 은하수. 정적, 절제.
class ConstellationScreen extends ConsumerWidget {
  const ConstellationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(constellationProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('별자리', style: AppTypography.subtitle),
      ),
      body: async.when(
        loading: () => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.textSecondary),
          ),
        ),
        error: (_, __) => _center('별자리를 불러오지 못했어'),
        data: (c) {
          if (c.nodes.length < 2) return _empty(c.nodes.length);
          return _StarMap(constellation: c);
        },
      ),
    );
  }

  Widget _center(String t) => Center(
        child: Text(t,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      );

  Widget _empty(int count) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 28, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.base),
              Text(
                count == 0 ? '아직 이어진 별이 없어' : '별 하나가 떴어',
                style:
                    AppTypography.body.copyWith(color: AppColors.textBright),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                count == 0
                    ? '멈춤이 쌓이면 서로 이어져 밤하늘이 생겨'
                    : '다음 멈춤이 오면 첫 선이 그어져',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}

class _StarMap extends StatefulWidget {
  final Constellation constellation;
  const _StarMap({required this.constellation});

  @override
  State<_StarMap> createState() => _StarMapState();
}

class _StarMapState extends State<_StarMap> {
  // 단위공간[0..1] 좌표. 힘기반 레이아웃을 initState에서 한 번만 계산(정적).
  final Map<String, Offset> _pos = {};

  @override
  void initState() {
    super.initState();
    _layout();
  }

  void _layout() {
    final nodes = widget.constellation.nodes;
    final edges = widget.constellation.edges;
    final ids = nodes.map((n) => n.id).toList();
    // 결정적 시드(별 위치가 매번 바뀌지 않게)
    for (final id in ids) {
      final h = id.hashCode;
      _pos[id] = Offset(
        (((h & 0xffff) / 0xffff) * 0.8) + 0.1,
        ((((h >> 16) & 0xffff) / 0xffff) * 0.8) + 0.1,
      );
    }
    final adj = <String, List<String>>{for (final id in ids) id: []};
    for (final e in edges) {
      if (adj.containsKey(e.memoA) && adj.containsKey(e.memoB)) {
        adj[e.memoA]!.add(e.memoB);
        adj[e.memoB]!.add(e.memoA);
      }
    }
    const iterations = 120;
    const kRep = 0.010; // 반발
    const kSpring = 0.020; // 연결된 별끼리 당김
    const rest = 0.18; // 스프링 자연길이
    for (var it = 0; it < iterations; it++) {
      final disp = <String, Offset>{for (final id in ids) id: Offset.zero};
      // 반발(모든 쌍)
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = _pos[ids[i]]!, b = _pos[ids[j]]!;
          var d = a - b;
          var len = d.distance;
          if (len < 0.001) {
            d = const Offset(0.001, 0.001);
            len = 0.0014;
          }
          final f = kRep / (len * len);
          final push = d / len * f;
          disp[ids[i]] = disp[ids[i]]! + push;
          disp[ids[j]] = disp[ids[j]]! - push;
        }
      }
      // 스프링(엣지)
      for (final e in edges) {
        final a = _pos[e.memoA], b = _pos[e.memoB];
        if (a == null || b == null) continue;
        final d = b - a;
        final len = d.distance.clamp(0.001, 2.0);
        final f = kSpring * (len - rest);
        final pull = d / len * f;
        disp[e.memoA] = disp[e.memoA]! + pull;
        disp[e.memoB] = disp[e.memoB]! - pull;
      }
      // 적용 + 중심 약한 중력 + 경계
      for (final id in ids) {
        var p = _pos[id]! + disp[id]!;
        final toCenter = const Offset(0.5, 0.5) - p;
        p = p + toCenter * 0.01;
        _pos[id] = Offset(p.dx.clamp(0.06, 0.94), p.dy.clamp(0.06, 0.94));
      }
    }
  }

  void _openNode(BuildContext context, ConNode node) {
    final edges = widget.constellation.edges
        .where((e) => e.memoA == node.id || e.memoB == node.id)
        .toList();
    final byId = {for (final n in widget.constellation.nodes) n.id: n};
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.preview,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textBright, height: 1.5)),
              if (edges.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 14),
                for (final e in edges) _edgeRow(e, node, byId),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _edgeRow(ConEdge e, ConNode from, Map<String, ConNode> byId) {
    final otherId = e.memoA == from.id ? e.memoB : e.memoA;
    final other = byId[otherId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 2, color: _relColor(e.relType)),
              const SizedBox(width: 8),
              Text(_relLabel(e.relType),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          if (other != null) ...[
            const SizedBox(height: 6),
            Text(other.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ],
          if (e.rationale != null && e.rationale!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 6),
                  child: Icon(Icons.auto_awesome,
                      size: 12, color: AppColors.accentGreen),
                ),
                Expanded(
                  child: Text(e.rationale!,
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary, height: 1.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final now = DateTime.now();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            // 가장 가까운 별 탭
            ConNode? hit;
            double best = 26; // px 반경
            for (final n in widget.constellation.nodes) {
              final p = _pos[n.id];
              if (p == null) continue;
              final px = Offset(p.dx * size.width, p.dy * size.height);
              final dist = (px - d.localPosition).distance;
              if (dist < best) {
                best = dist;
                hit = n;
              }
            }
            if (hit != null) _openNode(context, hit);
          },
          child: CustomPaint(
            size: size,
            painter: _MapPainter(
              nodes: widget.constellation.nodes,
              edges: widget.constellation.edges,
              pos: _pos,
              now: now,
            ),
          ),
        );
      },
    );
  }
}

Color _relColor(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return AppColors.textBright;
    case RelType.reverses:
      return AppColors.danger.withValues(alpha: 0.7);
    case RelType.echo:
      return AppColors.accentGreen.withValues(alpha: 0.5);
    case RelType.similar:
    default:
      return AppColors.textSecondary;
  }
}

String _relLabel(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return '더 밀고 나감';
    case RelType.reverses:
      return '정면으로 어긋남';
    case RelType.echo:
      return '밑바닥이 같음';
    case RelType.similar:
      return '같은 결';
    default:
      return '이어짐';
  }
}

class _MapPainter extends CustomPainter {
  final List<ConNode> nodes;
  final List<ConEdge> edges;
  final Map<String, Offset> pos;
  final DateTime now;

  _MapPainter(
      {required this.nodes,
      required this.edges,
      required this.pos,
      required this.now});

  Offset _p(String id, Size s) {
    final o = pos[id] ?? const Offset(0.5, 0.5);
    return Offset(o.dx * s.width, o.dy * s.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _nebula(canvas, size);

    // 선(별 뒤에)
    for (final e in edges) {
      if (!pos.containsKey(e.memoA) || !pos.containsKey(e.memoB)) continue;
      final a = _p(e.memoA, size), b = _p(e.memoB, size);
      final color = _relColor(e.relType);
      final width = e.relType == RelType.extends_ ||
              e.relType == RelType.reverses
          ? 1.5
          : 1.0;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = width
        ..style = PaintingStyle.stroke;
      if (e.relType == RelType.echo) {
        _dashed(canvas, a, b, paint);
      } else {
        canvas.drawLine(a, b, paint);
      }
    }

    // 별
    for (final n in nodes) {
      final p = _p(n.id, size);
      final recent = now.difference(n.createdAt).inDays < 7;
      final base = recent ? AppColors.accentGreen : AppColors.textSecondary;
      // glow
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = base.withValues(alpha: recent ? 0.22 : 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // core
      canvas.drawCircle(p, recent ? 3 : 2.4, Paint()..color = base);
    }
  }

  void _nebula(Canvas canvas, Size size) {
    // 은은한 은하수 성운(정적, 아주 낮은 알파). 파티클 없음.
    final specs = [
      [Offset(size.width * 0.32, size.height * 0.38), size.width * 0.7,
        AppColors.accentGreen.withValues(alpha: 0.05)],
      [Offset(size.width * 0.72, size.height * 0.66), size.width * 0.6,
        AppColors.nebula.withValues(alpha: 0.06)],
    ];
    for (final s in specs) {
      final center = s[0] as Offset;
      final radius = s[1] as double;
      final color = s[2] as Color;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(rect);
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0, gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final start = a + dir * d;
      final end = a + dir * math.min(d + dash, total);
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.nodes != nodes || old.edges != edges || old.pos != pos;
}
