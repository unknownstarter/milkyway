import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/constellation.dart';
import '../providers/constellation_providers.dart';

/// 별자리 = 내 사유가 이어진 순간들. 어수선한 그래프 대신 깔끔한 연결 카드 리스트.
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
          if (c.edges.isEmpty) return _empty();
          return _ConnectionList(constellation: c);
        },
      ),
    );
  }

  Widget _center(String t) => Center(
        child: Text(t,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 26, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.base),
              Text('아직 이어진 별이 없어',
                  style:
                      AppTypography.body.copyWith(color: AppColors.textBright)),
              const SizedBox(height: AppSpacing.sm),
              Text('메모가 쌓이면 서로 이어져 밤하늘이 생겨',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _ConnectionList extends StatelessWidget {
  final Constellation constellation;
  const _ConnectionList({required this.constellation});

  @override
  Widget build(BuildContext context) {
    final byId = {for (final n in constellation.nodes) n.id: n};
    // 강한 연결 우선
    final edges = [...constellation.edges]
      ..sort((a, b) => b.strength.compareTo(a.strength));
    final valid = edges
        .where((e) => byId.containsKey(e.memoA) && byId.containsKey(e.memoB))
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      itemCount: valid.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('이어진 순간 ${valid.length}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          );
        }
        return _ConnectionCard(edge: valid[i - 1], byId: byId);
      },
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final ConEdge edge;
  final Map<String, ConNode> byId;
  const _ConnectionCard({required this.edge, required this.byId});

  @override
  Widget build(BuildContext context) {
    final a = byId[edge.memoA]!;
    final b = byId[edge.memoB]!;
    // 시간순: 과거 -> 지금
    final past = a.createdAt.isBefore(b.createdAt) ? a : b;
    final now = a.createdAt.isBefore(b.createdAt) ? b : a;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 관계 라벨
          Row(
            children: [
              Container(width: 12, height: 2, color: _relColor(edge.relType)),
              const SizedBox(width: 8),
              Text(_relLabel(edge.relType),
                  style: AppTypography.caption.copyWith(
                      color: _relColor(edge.relType),
                      fontWeight: FontWeight.w600)),
            ],
          ),
          // Lyra 근거
          if (edge.rationale != null && edge.rationale!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 6),
                  child: Icon(Icons.auto_awesome,
                      size: 12, color: AppColors.accentGreen),
                ),
                Expanded(
                  child: Text(edge.rationale!,
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary, height: 1.55)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _memoMini(context, past, '그때'),
          const SizedBox(height: 8),
          _memoMini(context, now, '지금'),
        ],
      ),
    );
  }

  Widget _memoMini(BuildContext context, ConNode node, String when) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.pushNamed(AppRoutes.memoDetailName,
          pathParameters: {'id': node.id}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.cover),
        ),
        child: Row(
          children: [
            Text(when,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(node.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary, height: 1.4)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
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

Color _relColor(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return AppColors.textBright;
    case RelType.reverses:
      return AppColors.danger.withValues(alpha: 0.8);
    case RelType.echo:
      return AppColors.accentGreen;
    case RelType.similar:
    default:
      return AppColors.textSecondary;
  }
}
