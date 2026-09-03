import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/orb_tier.dart';
import '../../domain/share_payload.dart';
import '../orb_tier_l10n.dart';
import 'orb_palette.dart';
import 'orb_view.dart';

/// 공유용 성장 카드(포스터). 고정 1080x1350(4:5)로 캡처 -> JPG 업로드.
/// 화면 UI가 아니라 포스터라 크기는 포스터 스케일 상수, 색/폰트는 앱 토큰을 따른다.
class ShareCard extends StatelessWidget {
  static const double w = 1080;
  static const double h = 1350;

  final OrbShareData data;
  /// null이면 현재 언어의 기본 호칭(예: '나')을 쓴다.
  final String? nick;
  const ShareCard({super.key, required this.data, this.nick});

  TextStyle _t(double size, FontWeight weight, Color color,
          {double spacing = -0.03}) =>
      TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: size * spacing,
        height: 1.15,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final accent = orbAccentOf(data.tier);
    final name = orbTierName(l10n, data.tier);
    final idx = OrbTier.values.indexOf(data.tier);
    final nextName = idx < orbTiers.length - 1
        ? orbTierName(l10n, orbTiers[idx + 1].tier)
        : null;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.10), const Color(0xFF0A0A10)),
            const Color(0xFF0B0B12),
            const Color(0xFF08080E),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(80, 56, 80, 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 상단: 브랜드 + 티어 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('milkyway',
                  style: _t(30, FontWeight.w800, AppColors.textPrimary, spacing: 0.09)),
              _badge(l10n, name, accent),
            ],
          ),
          const SizedBox(height: 24),
          OrbView(tier: data.tier, size: 600, animate: false),
          const SizedBox(height: 20),
          Text(l10n.shareCardOwnerUniverse(nick ?? l10n.shareCardDefaultNick),
              style: _t(30, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
          const SizedBox(height: 10),
          // 언어별로 등급명 길이가 달라도(EN 'Star Cluster' 등) 항상 한 줄.
          // 넘칠 때만 축소해 포스터 세로 레이아웃이 밀리지 않게 한다.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              maxLines: 1,
              text: TextSpan(children: [
                TextSpan(
                    text: l10n.orbNowPrefix,
                    style: _t(70, FontWeight.w800, AppColors.textPrimary)),
                TextSpan(text: name, style: _t(70, FontWeight.w800, accent)),
              ]),
            ),
          ),
          const SizedBox(height: 34),
          _statsPanel(l10n, accent),
          const SizedBox(height: 30),
          _progress(l10n, accent, nextName),
          const Spacer(),
          Text(l10n.shareCardTagline,
              style: _t(31, FontWeight.w700, AppColors.textPrimary, spacing: -0.01)),
          const SizedBox(height: 12),
          Text(l10n.shareCardStoreHint,
              style: _t(23, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
        ],
      ),
    );
  }

  Widget _badge(AppL10n l10n, String name, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(l10n.orbTierBadge(name), style: _t(24, FontWeight.w700, accent, spacing: 0)),
        ]),
      );

  Widget _statsPanel(AppL10n l10n, Color accent) => Container(
        height: 188,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 1.5),
        ),
        child: Row(children: [
          _cell('${data.books}', l10n.unitBooks, l10n.statBooksRead,
              AppColors.textPrimary),
          _divider(),
          _cell('${data.memos}', l10n.unitCount, l10n.statMemosLeft,
              AppColors.textPrimary),
          _divider(),
          _cell('${data.topPercent ?? '-'}', '%', l10n.statTopPercent, accent),
          _divider(),
          _cell('${data.streakDays}', l10n.unitDays, l10n.statStreak,
              AppColors.textPrimary),
        ]),
      );

  Widget _divider() =>
      Container(width: 1, height: 70, color: Colors.white.withValues(alpha: 0.09));

  Widget _cell(String value, String unit, String label, Color valueColor) => Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(text: value, style: _t(52, FontWeight.w800, valueColor)),
              TextSpan(text: unit, style: _t(30, FontWeight.w700, AppColors.textBright, spacing: 0)),
            ]),
          ),
          const SizedBox(height: 12),
          // 라벨은 언어와 무관하게 한 줄(칸 폭보다 길면 축소).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                maxLines: 1,
                style: _t(26, FontWeight.w600, AppColors.textSecondary,
                    spacing: 0)),
          ),
        ]),
      );

  Widget _progress(AppL10n l10n, Color accent, String? nextName) {
    final pts = orbPoints(data.books, data.memos);
    final curLo = orbTierInfo(data.tier).lo;
    final idx = OrbTier.values.indexOf(data.tier);
    final nextLo = idx < orbTiers.length - 1 ? orbTiers[idx + 1].lo : null;
    final band = nextLo != null
        ? ((pts - curLo) / (nextLo - curLo)).clamp(0.04, 1.0)
        : 1.0;
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: band.toDouble(),
          minHeight: 12,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation(accent),
        ),
      ),
      const SizedBox(height: 14),
      nextName != null
          ? RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: l10n.orbToNextTier(nextName),
                    style: _t(26, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
                TextSpan(
                    text: '${data.pointsToNext}',
                    style: _t(26, FontWeight.w800, accent, spacing: 0)),
              ]),
            )
          : Text(l10n.orbDeepestReached,
              style: _t(26, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
    ]);
  }
}
