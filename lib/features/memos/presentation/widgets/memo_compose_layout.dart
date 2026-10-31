import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// 메모 작성 본문 레이아웃. 위쪽(책 칩/Lyra 물음/에디터)은 스크롤 영역, 아래쪽(툴바/저장)은 고정.
/// 키보드가 열리면 Lyra 물음은 한 줄로 접고, 에디터는 최소 높이를 보장한다.
class MemoComposeLayout extends StatelessWidget {
  /// 키보드가 열렸는지를 받아 책 칩을 만든다 (열렸으면 compact).
  final Widget Function(bool compact) bookChipBuilder;
  final String? lyraQuestion;
  final String lyraLabel;
  final Widget editor;
  final List<Widget> bottomBars;

  /// 입력창 아래 빈 곳을 눌러도 포커스를 주기 위한 노드.
  final FocusNode? editorFocusNode;

  static const double minEditorHeight = 120;
  static const editorKey = ValueKey('memo_compose_editor');

  const MemoComposeLayout({
    super.key,
    required this.bookChipBuilder,
    required this.lyraQuestion,
    required this.lyraLabel,
    required this.editor,
    required this.bottomBars,
    this.editorFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    bookChipBuilder(keyboardOpen),
                    if (lyraQuestion != null)
                      MemoLyraQuestionBlock(
                        question: lyraQuestion!,
                        label: lyraLabel,
                        collapsed: keyboardOpen,
                      ),
                  ],
                ),
              ),
              // 남은 공간을 입력창이 채운다. 부족하면 최소 높이를 지키고 스크롤된다.
              SliverFillRemaining(
                hasScrollBody: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: editorFocusNode?.requestFocus,
                  child: ConstrainedBox(
                    key: editorKey,
                    constraints: const BoxConstraints(
                      minHeight: minEditorHeight,
                    ),
                    child: Align(alignment: Alignment.topCenter, child: editor),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...bottomBars,
      ],
    );
  }
}

/// Lyra 물음 카드. [collapsed] 이면 한 줄로 접히고, 눌러서 펼친다.
class MemoLyraQuestionBlock extends StatefulWidget {
  final String question;
  final String label;
  final bool collapsed;

  const MemoLyraQuestionBlock({
    super.key,
    required this.question,
    required this.label,
    required this.collapsed,
  });

  @override
  State<MemoLyraQuestionBlock> createState() => _MemoLyraQuestionBlockState();
}

class _MemoLyraQuestionBlockState extends State<MemoLyraQuestionBlock> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant MemoLyraQuestionBlock old) {
    super.didUpdateWidget(old);
    // 키보드가 닫히면 펼침 상태를 초기화해 다음에 열릴 때 다시 접힌다.
    if (old.collapsed && !widget.collapsed) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final folded = widget.collapsed && !_expanded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.collapsed
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: Container(
        margin: EdgeInsets.fromLTRB(20, folded ? 8 : 14, 20, 0),
        padding: EdgeInsets.all(folded ? 10 : 14),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accentGreen.withValues(alpha: 0.25),
          ),
        ),
        child: folded ? _foldedRow() : _fullColumn(),
      ),
    );
  }

  Widget _dot() => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: AppColors.accentGreen,
      shape: BoxShape.circle,
    ),
  );

  Widget _foldedRow() {
    return Row(
      children: [
        _dot(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.question,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ],
    );
  }

  Widget _fullColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dot(),
            const SizedBox(width: 7),
            Text(
              widget.label,
              style: AppTypography.caption.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.question,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
