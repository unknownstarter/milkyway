import 'package:flutter/material.dart';
import '../../domain/orb_tier.dart';

/// 티어별 액센트/글로우 색. 오브 자산 아우라와 매칭.
/// 앱 글로벌 액센트(형광 초록)와 별개인 오브 전용 팔레트.
const Map<OrbTier, Color> _orbAccent = {
  OrbTier.t1: Color(0xFF9DB4FF),
  OrbTier.t2: Color(0xFFA99CFF),
  OrbTier.t3: Color(0xFF9A8CFF),
  OrbTier.t4: Color(0xFFC48CFF),
  OrbTier.t5: Color(0xFFFF9ECB),
  OrbTier.t6: Color(0xFFFFC24D),
};

Color orbAccentOf(OrbTier tier) => _orbAccent[tier]!;
