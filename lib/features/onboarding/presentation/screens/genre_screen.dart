import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../providers/onboarding_genres_provider.dart';

/// 온보딩 장르 선택(선택 · 건너뛰기 가능). 추천 책 정렬용, 게이팅 아님.
class GenreScreen extends ConsumerStatefulWidget {
  const GenreScreen({super.key});

  @override
  ConsumerState<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends ConsumerState<GenreScreen> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('onboarding_genre');
  }

  void _toggle(String genre) {
    setState(() {
      if (!_selected.remove(genre)) _selected.add(genre);
    });
  }

  void _goNext() {
    ref.read(onboardingGenresProvider.notifier).state = _selected.toList();
    ref
        .read(analyticsProvider)
        .logEvent('click_next_in_onboarding_genre', {'count': _selected.length});
    context.pushNamed(AppRoutes.onboardingBookSavingName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('취향', style: AppTypography.subtitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.pageHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  const Text('어떤 결의 책을\n좋아하나요',
                      style: AppTypography.heading),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '취향을 알려주면 첫 책을 더 잘 골라드려요\n하나 이상 골라주세요',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final g in kOnboardingGenres) _chip(g),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: _nextButton(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String genre) {
    final on = _selected.contains(genre);
    return GestureDetector(
      onTap: () => _toggle(genre),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: on
              ? AppColors.accentGreen.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: on ? AppColors.accentGreen : AppColors.divider,
          ),
        ),
        child: Text(
          genre,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: -0.2,
            color: on ? AppColors.accentGreen : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    final enabled = _selected.isNotEmpty;
    final label = enabled ? '${_selected.length}개 고르고 다음' : '한 개 이상 골라주세요';
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: enabled ? AppColors.accentGreen : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: enabled ? _goNext : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: enabled ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
