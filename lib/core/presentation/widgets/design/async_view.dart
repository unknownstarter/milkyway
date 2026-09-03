import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// 디자인 시스템 표준: 비동기 콘텐츠를 '부드럽게' 렌더한다.
///
/// 리스트/섹션의 로딩을 직접 스피너로 박지 말고 반드시 이걸 쓴다(어디서나 동일).
/// 강제하는 3규칙:
///  1. 갱신/재로드 중엔 이전 데이터를 유지 -> 깜빡임 없음(skipLoadingOnReload/Refresh)
///  2. 최초 로딩은 고정 높이 placeholder -> 섹션이 줄었다 늘어나는 점프 방지
///  3. 상태 교체는 부드러운 크로스페이드(AnimatedSwitcher)
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  /// 빈 상태(선택). [isEmpty]가 true를 반환하면 [emptyBuilder]를 그린다.
  final bool Function(T data)? isEmpty;
  final Widget Function()? emptyBuilder;

  /// null이면 공용 기본 문구(commonLoadFailed)를 쓴다.
  final String? errorText;

  /// 재시도 콜백(선택). 주면 에러 상태에 '다시 시도' 버튼이 뜬다.
  /// raw 에러는 절대 노출하지 않음([errorText]만). 원본 에러는 repository/provider에서 log로 적재.
  final VoidCallback? onRetry;

  /// 최초 로딩 시 고정 높이(섹션 점프 방지). 전체 화면 로딩이면 크게.
  final double loadingHeight;
  final Duration duration;

  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyBuilder,
    this.errorText,
    this.onRetry,
    this.loadingHeight = 140,
    this.duration = const Duration(milliseconds: 180),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: value.when(
        // 1. 재로드/갱신 중엔 이전 데이터 유지(깜빡임 없음)
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (d) {
          if ((isEmpty?.call(d) ?? false) && emptyBuilder != null) {
            return KeyedSubtree(
                key: const ValueKey('async-empty'), child: emptyBuilder!());
          }
          return KeyedSubtree(
              key: const ValueKey('async-data'), child: builder(d));
        },
        // 2. 최초 로딩 = 고정 높이
        loading: () => SizedBox(
          key: const ValueKey('async-loading'),
          height: loadingHeight,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.textSecondary),
            ),
          ),
        ),
        // raw 에러는 노출 금지 - 친화 문구 + (있으면) 재시도 버튼만.
        error: (_, __) => Padding(
          key: const ValueKey('async-error'),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorText ?? l10n.commonLoadFailed,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    child:
                        Text(l10n.commonRetry, style: AppTypography.bodySmall),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
