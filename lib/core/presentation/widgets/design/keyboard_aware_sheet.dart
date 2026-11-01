import 'package:flutter/material.dart';

/// 하단에 붙는 시트(showGeneralDialog 의 transitionBuilder 용). 입력칸이 들어 있어도
/// 키보드에 가리지 않는다.
///  - 시트 전체가 키보드 높이만큼 올라온다(내용을 줄이지 않는다)
///  - 높이는 화면 비율, 단 키보드와 상태바를 뺀 남은 공간을 넘지 않는다
///  - 하단 안전영역은 키보드가 닫혀 있을 때만 더한다(키보드 위에서 이중으로 띄우지 않는다)
///
/// [fixedHeight]=true 면 [heightFactor] 높이로 고정(Expanded 입력칸이 있는 시트),
/// false 면 내용 높이에 맞추되 [heightFactor] 를 상한으로 한다.
class KeyboardAwareSheet extends StatelessWidget {
  final Widget child;
  final double heightFactor;
  final bool fixedHeight;
  final Color color;
  final double radius;

  const KeyboardAwareSheet({
    super.key,
    required this.child,
    this.heightFactor = 0.5,
    this.fixedHeight = false,
    this.color = const Color(0xFF313131),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final inset = mq.viewInsets.bottom;
    final available = mq.size.height - inset - mq.padding.top - 8;
    final h = (mq.size.height * heightFactor).clamp(0.0, available);
    final bottomSafe = inset > 0 ? 0.0 : mq.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // 시트 내부 탭은 배경 닫기로 새지 않게
            child: Container(
              width: double.infinity,
              height: fixedHeight ? h : null,
              constraints: fixedHeight ? null : BoxConstraints(maxHeight: h),
              padding: EdgeInsets.only(bottom: bottomSafe),
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
