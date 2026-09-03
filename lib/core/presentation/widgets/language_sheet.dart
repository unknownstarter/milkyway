import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locale_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// 언어 선택 바텀시트. 기기 설정/한국어/English/日本語/中文.
/// 홈 알약, 프로필 언어 메뉴 등 어디서나 재사용.
Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
  final l = AppL10n.of(context);
  final current = ref.read(localeControllerProvider)?.languageCode;
  final items = <(String?, String)>[
    (null, l.languageSystem),
    ('ko', l.languageKorean),
    ('en', l.languageEnglish),
    ('ja', l.languageJapanese),
    ('zh', l.languageChinese),
  ];
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          for (final it in items)
            ListTile(
              title: Text(it.$2, style: AppTypography.body),
              trailing: current == it.$1
                  ? const Icon(Icons.check, color: AppColors.accentGreen, size: 20)
                  : null,
              onTap: () {
                ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(it.$1 == null ? null : Locale(it.$1!));
                Navigator.pop(sheetContext);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
