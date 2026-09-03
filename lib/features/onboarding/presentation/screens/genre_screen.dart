import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../providers/onboarding_genres_provider.dart';
import '../../../../l10n/app_localizations.dart';

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
        title: Text(AppL10n.of(context).onboardingGenreTitle,
            style: AppTypography.subtitle),
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
                  Text(AppL10n.of(context).onboardingGenreHeading,
                      style: AppTypography.heading),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppL10n.of(context).onboardingGenreSubtitle,
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

  /// 저장값은 [kOnboardingGenres]의 한국어 canonical 그대로 두고 표시만 로컬라이즈.
  String _genreLabel(String genre) {
    final l10n = AppL10n.of(context);
    switch (genre) {
      case '소설':
        return l10n.onboardingGenreNovel;
      case '시':
        return l10n.onboardingGenrePoetry;
      case '에세이':
        return l10n.onboardingGenreEssay;
      case '인문':
        return l10n.onboardingGenreHumanities;
      case '철학':
        return l10n.onboardingGenrePhilosophy;
      case '과학':
        return l10n.onboardingGenreScience;
      case 'SF':
        return l10n.onboardingGenreSciFi;
      case '역사':
        return l10n.onboardingGenreHistory;
      case '예술':
        return l10n.onboardingGenreArt;
      case '심리':
        return l10n.onboardingGenrePsychology;
      case '경제경영':
        return l10n.onboardingGenreBusiness;
      case '자기계발':
        return l10n.onboardingGenreSelfHelp;
      default:
        return genre;
    }
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
          _genreLabel(genre),
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
    final l10n = AppL10n.of(context);
    final label = enabled
        ? l10n.onboardingGenreNextCount(_selected.length)
        : l10n.onboardingGenreSelectAtLeastOne;
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
