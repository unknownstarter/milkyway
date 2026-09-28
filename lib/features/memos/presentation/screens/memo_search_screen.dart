import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/memo.dart';
import '../memo_l10n.dart';
import '../providers/memo_search_provider.dart';

/// 내 메모 검색. 키워드는 무료(PRD v2 §8 Free), 의미 검색은 그 위에 얹었다(§10).
///
/// 한 화면에 둘을 섞지 않고 위아래로 나눈다. 위는 내가 쓴 단어가 실제로 들어 있는
/// 메모, 아래는 단어는 달라도 뜻이 가까운 메모다. 섞으면 왜 이게 걸렸는지 설명이
/// 안 되고, 나중에 의미 검색만 유료로 잠글 때 잘라낼 경계도 사라진다.
class MemoSearchScreen extends ConsumerStatefulWidget {
  const MemoSearchScreen({super.key});

  @override
  ConsumerState<MemoSearchScreen> createState() => _MemoSearchScreenState();
}

class _MemoSearchScreenState extends ConsumerState<MemoSearchScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('memo_search');
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(memoSearchProvider.notifier).loadMore();
    }
  }

  void _openDetail(Memo memo, {required bool fromSemantic}) {
    if (fromSemantic) {
      ref.read(analyticsProvider).logEvent('semantic_search_result_clicked', {
        'query_length': ref.read(memoSearchProvider).query.length,
      });
    }
    context.pushNamed(
      AppRoutes.memoDetailName,
      pathParameters: {'id': memo.id},
      extra: memo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final state = ref.watch(memoSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        leading: const BackButton(color: AppColors.textSecondary),
        title: _field(l10n),
        actions: [
          if (state.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close,
                  size: 20, color: AppColors.textSecondary),
              onPressed: () {
                _controller.clear();
                ref.read(memoSearchProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: _body(l10n, state, glassTopPadding(context)),
    );
  }

  Widget _field(AppL10n l10n) {
    return TextField(
      controller: _controller,
      autofocus: true,
      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      cursorColor: Colors.white,
      textInputAction: TextInputAction.search,
      onChanged: ref.read(memoSearchProvider.notifier).onQueryChanged,
      onSubmitted: ref.read(memoSearchProvider.notifier).search,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: l10n.memoSearchHint,
        hintStyle:
            AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _body(AppL10n l10n, MemoSearchState state, double topPadding) {
    if (state.isIdle) return _message(l10n.memoSearchPrompt, topPadding);

    return state.results.when(
      skipLoadingOnReload: true,
      loading: () => _spinner(topPadding),
      error: (_, __) => _message(l10n.memoSearchFailed, topPadding),
      data: (memos) => _results(l10n, state, memos, topPadding),
    );
  }

  Widget _results(AppL10n l10n, MemoSearchState state, List<Memo> memos,
      double topPadding) {
    final semantic = state.semanticOnly;
    final extra = semantic.value ?? const <Memo>[];

    // 키워드가 0건일 땐 의미 검색을 기다린다. 먼저 "없어요"를 띄운 뒤 아래에 결과가
    // 붙으면 화면이 자기 말을 뒤집는다.
    if (memos.isEmpty && extra.isEmpty) {
      if (semantic.isLoading) return _spinner(topPadding);
      return _message(l10n.memoSearchEmpty, topPadding);
    }

    // 키워드를 다 불러온 뒤에만 의미 섹션을 붙인다. 더 불러올 게 남은 동안 붙이면
    // 페이지가 추가될 때마다 섹션이 리스트 중간에서 밀려 내려간다.
    final showSemantic = extra.isNotEmpty && !state.hasMore;

    final rows = <_Row>[
      for (final m in memos) _MemoRow(m, fromSemantic: false),
      if (state.hasMore) _LoaderRow(),
      if (showSemantic) ...[
        _HeaderRow(l10n.memoSearchSemanticTitle),
        for (final m in extra) _MemoRow(m, fromSemantic: true),
      ],
    ];

    return ListView.separated(
      controller: _scroll,
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, topPadding, AppSpacing.lg, 110),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final row = rows[i];
        return switch (row) {
          _MemoRow(:final memo, :final fromSemantic) =>
            _card(l10n, memo, fromSemantic: fromSemantic),
          _HeaderRow(:final text) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 4),
              child: Text(text, style: AppTypography.title),
            ),
          _LoaderRow() => _spinner(null),
        };
      },
    );
  }

  Widget _spinner(double? topPadding) => Padding(
        padding: topPadding == null
            ? const EdgeInsets.symmetric(vertical: 16)
            : EdgeInsets.only(top: topPadding),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.textSecondary),
          ),
        ),
      );

  Widget _card(AppL10n l10n, Memo memo, {required bool fromSemantic}) {
    final edited = memo.isEdited;
    final date = edited ? memo.updatedAt! : memo.createdAt;
    return MemoCard(
      // 의미 검색 결과에는 보통 검색어가 안 들어 있다. 그건 그대로 둔다.
      // 어쩌다 겹치면 강조되는 것이고, 안 겹치면 아무 일도 안 일어난다.
      highlight: ref.read(memoSearchProvider).query,
      content: memo.content,
      authorName: memo.userNickname ?? l10n.memoAuthorFallback,
      authorImageUrl: memo.userAvatarUrl,
      dateText: memoRelativeDate(l10n, date),
      edited: edited,
      bookTitle: memo.bookTitle,
      page: memo.page,
      imageUrl: memo.imageUrl,
      commentCount: memo.commentCount,
      lyraQuestion: memo.lyraQuestion,
      onTap: () => _openDetail(memo, fromSemantic: fromSemantic),
    );
  }

  Widget _message(String text, double topPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topPadding + AppSpacing.xl, AppSpacing.lg, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// 리스트 한 줄의 정체. 키워드 결과와 의미 결과를 한 ListView 에 담되, 탭했을 때
/// 어느 쪽에서 왔는지는 잃지 않는다(`semantic_search_result_clicked`).
sealed class _Row {}

class _MemoRow extends _Row {
  _MemoRow(this.memo, {required this.fromSemantic});

  final Memo memo;
  final bool fromSemantic;
}

class _HeaderRow extends _Row {
  _HeaderRow(this.text);

  final String text;
}

class _LoaderRow extends _Row {}
