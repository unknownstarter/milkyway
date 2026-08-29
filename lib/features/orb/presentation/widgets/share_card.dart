import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/orb_tier.dart';
import '../../domain/share_payload.dart';
import 'orb_palette.dart';
import 'orb_view.dart';

/// 공유용 성장 카드(포스터). 고정 1080x1350(4:5)로 캡처 -> JPG 업로드.
/// 화면 UI가 아니라 포스터라 크기는 포스터 스케일 상수, 색/폰트는 앱 토큰을 따른다.
class ShareCard extends StatelessWidget {
  static const double w = 1080;
  static const double h = 1350;

  final OrbShareData data;
  final String nick;
  const ShareCard({super.key, required this.data, this.nick = '나'});

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
    final accent = orbAccentOf(data.tier);
    final name = orbTierInfo(data.tier).name;
    final idx = OrbTier.values.indexOf(data.tier);
    final nextName = idx < orbTiers.length - 1 ? orbTiers[idx + 1].name : null;

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
              _badge(name, accent),
            ],
          ),
          const SizedBox(height: 24),
          OrbView(tier: data.tier, size: 600, animate: false),
          const SizedBox(height: 20),
          Text('$nick의 우주',
              style: _t(30, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '지금은 ', style: _t(70, FontWeight.w800, AppColors.textPrimary)),
              TextSpan(text: name, style: _t(70, FontWeight.w800, accent)),
            ]),
          ),
          const SizedBox(height: 34),
          _statsPanel(accent),
          const SizedBox(height: 30),
          _progress(accent, nextName),
          const Spacer(),
          Text('너의 우주는 어떤 모양일까',
              style: _t(31, FontWeight.w700, AppColors.textPrimary, spacing: -0.01)),
          const SizedBox(height: 12),
          Text('App Store / Google Play 에 milkyway',
              style: _t(23, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
        ],
      ),
    );
  }

  Widget _badge(String name, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text('$name 단계', style: _t(24, FontWeight.w700, accent, spacing: 0)),
        ]),
      );

  Widget _statsPanel(Color accent) => Container(
        height: 188,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 1.5),
        ),
        child: Row(children: [
          _cell('${data.books}', '권', '읽은 책', AppColors.textPrimary),
          _divider(),
          _cell('${data.memos}', '개', '남긴 메모', AppColors.textPrimary),
          _divider(),
          _cell('${data.topPercent ?? '-'}', '%', '상위', accent),
          _divider(),
          _cell('${data.streakDays}', '일', '연속', AppColors.textPrimary),
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
          Text(label, style: _t(26, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
        ]),
      );

  Widget _progress(Color accent, String? nextName) {
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
                    text: '다음 단계 $nextName까지 ',
                    style: _t(26, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
                TextSpan(
                    text: '${data.pointsToNext}',
                    style: _t(26, FontWeight.w800, accent, spacing: 0)),
              ]),
            )
          : Text('가장 깊은 우주에 도달',
              style: _t(26, FontWeight.w600, AppColors.textSecondary, spacing: 0)),
    ]);
  }
}
