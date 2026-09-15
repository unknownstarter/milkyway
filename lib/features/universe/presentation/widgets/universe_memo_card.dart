import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../memos/domain/models/memo.dart';
import '../../domain/universe_layout.dart';

/// 별을 눌렀을 때 올라오는 메모 카드.
///
/// 픽셀 폰트(PressStart2P)는 한글이 없다. 숫자/영문 메타에만 쓰고 본문은 앱 폰트로.
class UniverseMemoCard extends StatelessWidget {
  final String title;
  final String author;
  final int notes;
  final int colorIndex;
  final List<Memo> memos;
  final VoidCallback onClose;
  final void Function(Memo) onOpenMemo;
  final VoidCallback onWrite;

  const UniverseMemoCard({
    super.key,
    required this.title,
    required this.author,
    required this.notes,
    required this.colorIndex,
    required this.memos,
    required this.onClose,
    required this.onOpenMemo,
    required this.onWrite,
  });

  Color get _accent =>
      Color(kUniversePalette[colorIndex % kUniversePalette.length]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final memo = memos.isEmpty ? null : memos.first;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xEB09081A),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: _accent.withValues(alpha: 0.55), width: 1.6),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 40),
          BoxShadow(color: _accent.withValues(alpha: 0.22), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  memo?.page != null ? 'NOTE / P.${memo!.page}' : 'NOTE',
                  style: _pixel(10, _accent),
                ),
              ),
              if (memo != null)
                Text(DateFormat('yyyy.MM.dd').format(memo.createdAt),
                    style: _pixel(10, const Color(0xFF8A8A98))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.close, size: 18, color: Color(0xFF8A8A98)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subtitle.copyWith(color: const Color(0xFFF4F7FF))),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption),
          ],
          const SizedBox(height: 14),
          Container(height: 2, color: _accent.withValues(alpha: 0.45)),
          const SizedBox(height: 14),
          if (memo == null)
            _noMemo(l10n)
          else
            _memoBody(memo),
          if (memos.length > 1) ...[
            const SizedBox(height: 10),
            Text('+${memos.length - 1}', style: _pixel(10, _accent)),
          ],
        ],
      ),
    );
  }

  Widget _memoBody(Memo memo) => GestureDetector(
        onTap: () => onOpenMemo(memo),
        behavior: HitTestBehavior.opaque,
        child: Text(
          memo.content,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            color: const Color(0xFFDFE6FF),
            height: 1.65,
          ),
        ),
      );

  /// 메모가 없는 별 - 흐린 채로 있는 이유를 말해주고 바로 쓰게 한다.
  Widget _noMemo(AppL10n l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.universeEmptyNotesBody, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _accent.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
              onPressed: onWrite,
              child: Text(l10n.universeEmptyNotesCta,
                  style: AppTypography.bodyBold
                      .copyWith(color: _accent, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );

  TextStyle _pixel(double size, Color color) => TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: size,
        color: color,
        letterSpacing: 0.8,
        height: 1.4,
      );
}
