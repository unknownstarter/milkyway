import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/wrapped_data.dart';

/// 은하 회고 공유 카드(1080x1350). 화면엔 안 띄우고 공유 시 오프스크린 캡처 전용.
/// 위치는 검증된 프로토타입(marketing/generate_wrapped.py)과 동일한 절대 좌표.
class WrappedCard extends StatelessWidget {
  static const double w = 1080;
  static const double h = 1350;

  /// 회고 시그니처 색(밤하늘 보라). 오브 티어색과 별개인 회고 전용 액센트.
  static const Color accent = Color(0xFF8A7CFF);

  static const double _mx = 84;

  final WrappedData data;
  const WrappedCard({super.key, required this.data});

  static const String _f = AppTypography.fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          // 베이스 그라데이션
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF08080E), Color(0xFF0A0A12), Color(0xFF070710)],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // 상단 보라 성운 글로우
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.72),
                  radius: 0.85,
                  colors: [accent.withValues(alpha: 0.20), accent.withValues(alpha: 0.0)],
                  stops: const [0.0, 0.62],
                ),
              ),
            ),
          ),
          // 하단 청색 성운 글로우
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, 0.68),
                  radius: 0.8,
                  colors: [const Color(0xFF5A78DC).withValues(alpha: 0.12), const Color(0xFF5A78DC).withValues(alpha: 0.0)],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          // 별
          Positioned.fill(child: CustomPaint(painter: _StarsPainter())),

          // 상단: 워드마크 + 기간 배지
          Positioned(
            top: 60,
            left: _mx,
            right: _mx,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('milkyway',
                    style: TextStyle(
                        fontFamily: _f,
                        color: Color(0xFFEDEDED),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8.1,
                        fontSize: 29)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Text(data.periodLabel,
                      style: const TextStyle(
                          fontFamily: _f, color: accent, fontWeight: FontWeight.w700, fontSize: 26)),
                ),
              ],
            ),
          ),

          // 헤드
          Positioned(
            top: 150,
            left: _mx,
            right: _mx,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontFamily: _f,
                    fontWeight: FontWeight.w800,
                    fontSize: 72,
                    letterSpacing: -2.88,
                    height: 1.12,
                    color: Color(0xFFF5F5F7)),
                children: [
                  TextSpan(text: '${data.monthLabel}, 네가\n'),
                  const TextSpan(text: '멈춘 순간들', style: TextStyle(color: accent)),
                ],
              ),
            ),
          ),

          // 서브
          Positioned(
            top: 316,
            left: _mx,
            child: Text('그 자리에 남은 ${data.memoCount}개의 별',
                style: const TextStyle(
                    fontFamily: _f, color: Color(0xFF9AA0AC), fontWeight: FontWeight.w600, fontSize: 30)),
          ),

          // 3 스탯
          Positioned(
            top: 400,
            left: _mx,
            right: _mx,
            child: Row(
              children: [
                _stat('${data.memoCount}', '개', '멈춘 문장', false),
                _statDiv(),
                _stat('${data.readDays}', '일', '읽은 날', false),
                _statDiv(),
                _stat(data.topPercent != null ? '${data.topPercent}' : '-', '%', '상위', true),
              ],
            ),
          ),

          // 최애 책
          if (data.bookTitle != null)
            Positioned(top: 568, left: _mx, right: _mx, child: _bookCard()),

          // 그 달의 문장
          if (data.quote != null)
            Positioned(top: 812, left: _mx, right: _mx, child: _quoteBlock()),

          // Lyra 물음
          if (data.lyra != null)
            Positioned(top: 1018, left: _mx, right: _mx, child: _lyraBlock()),

          // 푸터
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text('너의 우주는 어떤 모양일까',
                    style: TextStyle(
                        fontFamily: _f, color: Color(0xFFEDEDED), fontWeight: FontWeight.w700, fontSize: 30)),
                const SizedBox(height: 11),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontFamily: _f, color: Color(0xFF7C828A), fontWeight: FontWeight.w600, fontSize: 23),
                    children: [
                      TextSpan(text: 'App Store / Google Play', style: TextStyle(color: Color(0xFFAEB2BB))),
                      TextSpan(text: ' 에 milkyway'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String unit, String label, bool hl) => Expanded(
        child: Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                    fontFamily: _f,
                    fontWeight: FontWeight.w800,
                    fontSize: 58,
                    letterSpacing: -1.74,
                    height: 1.0,
                    color: hl ? accent : const Color(0xFFF2F3F5)),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                      text: unit,
                      style: const TextStyle(fontSize: 30, color: Color(0xFFC7CCD4), letterSpacing: 0)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    fontFamily: _f, color: Color(0xFF8A9098), fontWeight: FontWeight.w600, fontSize: 25)),
          ],
        ),
      );

  Widget _statDiv() => Container(width: 1, height: 74, color: Colors.white.withValues(alpha: 0.09));

  Widget _bookCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 174,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A4A86), Color(0xFF20264A)],
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.auto_stories_outlined, color: Colors.white.withValues(alpha: 0.35), size: 44),
            ),
            const SizedBox(width: 26),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('가장 오래 머문 책',
                      style: TextStyle(fontFamily: _f, color: accent, fontWeight: FontWeight.w700, fontSize: 24)),
                  const SizedBox(height: 10),
                  Text(data.bookTitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _f,
                          color: Color(0xFFF0F1F3),
                          fontWeight: FontWeight.w800,
                          fontSize: 40,
                          letterSpacing: -0.8,
                          height: 1.25)),
                  if ((data.bookAuthor ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(data.bookAuthor!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _f, color: Color(0xFF9096A0), fontWeight: FontWeight.w600, fontSize: 25)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _quoteBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.quote!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: _f,
                  color: Color(0xFFEDEDED),
                  fontWeight: FontWeight.w700,
                  fontSize: 40,
                  height: 1.5,
                  letterSpacing: -0.8)),
          if ((data.quoteBook ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(data.quoteBook!,
                style: const TextStyle(
                    fontFamily: _f, color: Color(0xFF8A9098), fontWeight: FontWeight.w600, fontSize: 24)),
          ],
        ],
      );

  Widget _lyraBlock() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.auto_awesome, color: accent, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(data.lyra!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: _f, color: Color(0xFFC7CCD4), fontWeight: FontWeight.w600, fontSize: 28, height: 1.5)),
          ),
        ],
      );
}

/// 카드 배경 별. 시드 고정(캡처마다 동일).
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(9);
    final n = (size.width * size.height / 2600).round();
    final p = Paint()..color = Colors.white;
    for (var i = 0; i < n; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextBool() ? 1.0 : (rnd.nextBool() ? 1.4 : 2.0);
      final op = [0.18, 0.3, 0.45][rnd.nextInt(3)];
      canvas.drawCircle(Offset(x, y), r, p..color = Colors.white.withValues(alpha: op));
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}
