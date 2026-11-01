import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// 세션은 있는데 사용자 조회가 실패했을 때. 로그인 화면으로 보내지 않고 다시 시도하게 한다.
class SplashRetryView extends StatelessWidget {
  const SplashRetryView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_horizontal.png', width: 200),
              const SizedBox(height: 40),
              Text(
                l10n.commonLoadFailed,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: l10n.commonRetry, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
