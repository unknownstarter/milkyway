import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// 공유 링크를 받은 사람에게 보여주는 '그때 -> 지금'.
///
/// 오브만 덩그러니 있으면 모르는 사람이 반응할 이유가 없다. milkyway 는 책 읽다
/// 멈춘 순간이 전부라, 그 순간 두 개와 Lyra 가 본 연결을 보여준다.
///
/// **여기 오는 문장은 둘 다 공개 메모인 경우뿐이다**(발행 시점에 걸러진다).
class ConnectionBlock extends StatelessWidget {
  final String past;
  final String now;
  final DateTime? pastDate;
  final DateTime? nowDate;
  final String? rationale;
  final Color accent;

  const ConnectionBlock({
    super.key,
    required this.past,
    required this.now,
    required this.accent,
    this.pastDate,
    this.nowDate,
    this.rationale,
  });

  static ConnectionBlock? fromPayload(
      Map<String, dynamic>? payload, Color accent) {
    final c = payload?['connection'];
    if (c is! Map) return null;
    final past = (c['past'] as String?)?.trim() ?? '';
    final now = (c['now'] as String?)?.trim() ?? '';
    if (past.isEmpty || now.isEmpty) return null;
    DateTime? parse(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return ConnectionBlock(
      past: past,
      now: now,
      pastDate: parse(c['past_date']),
      nowDate: parse(c['now_date']),
      rationale: (c['rationale'] as String?)?.trim(),
      accent: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _quote(l10n.shareConnectionThen, past, pastDate, dim: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(width: 18, height: 1, color: accent.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_downward, size: 14, color: accent),
                const SizedBox(width: 8),
                Expanded(
                    child: Container(
                        height: 1, color: accent.withValues(alpha: 0.18))),
              ],
            ),
          ),
          _quote(l10n.shareConnectionNow, now, nowDate, dim: false),
          if (rationale != null && rationale!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(rationale!,
                      style: AppTypography.bodySmall
                          .copyWith(color: accent.withValues(alpha: 0.95))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quote(String label, String text, DateTime? date, {required bool dim}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: AppTypography.caption.copyWith(
                      color: dim ? AppColors.textSecondary : accent,
                      fontWeight: FontWeight.w800)),
              if (date != null) ...[
                const SizedBox(width: 6),
                Text(DateFormat('yyyy.MM.dd').format(date),
                    style: AppTypography.caption),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: dim ? AppColors.textSecondary : AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      );
}
