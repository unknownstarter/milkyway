import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/pill_policy.dart';
import 'dismissible_pill.dart';

/// 플로팅 알약 한 개의 정의. 경로 · 텍스트 · 노출 정책을 여기서만 정한다.
///
/// 탭 동작은 [routeName](네임드 라우트) 또는 [onTap](직접 동작) 중 하나.
/// 둘 다 주면 [onTap]이 이긴다.
class FloatingPillSpec {
  /// 저장 키(정책 기록에 쓰임). 알약마다 고유해야 한다.
  final String id;
  final String label;
  final IconData? icon;
  final PillFrequency frequency;

  final String? routeName;
  final Map<String, String> pathParameters;
  final Map<String, String> queryParameters;
  final Future<void> Function(BuildContext context)? onTap;

  /// 본체를 눌러 목적을 달성하면 영구 종료할지. 기본 true
  /// (언어를 바꾼 사람에게 "언어 변경"을 또 권할 이유가 없다).
  final bool dismissOnTap;

  /// 이 정책 도입 전에 쓰던 닫힘 플래그. 이미 닫은 사용자에게 되살아나지 않게 한다.
  final String? legacyDismissedKey;

  const FloatingPillSpec({
    required this.id,
    required this.label,
    required this.frequency,
    this.icon,
    this.routeName,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.onTap,
    this.dismissOnTap = true,
    this.legacyDismissedKey,
  });
}

/// 디자인 시스템: 화면 위에 떠 있는 알약.
///
/// - **레이아웃을 밀지 않는다.** `Stack`의 자식으로 두고 [top]으로 띄울 높이만 준다.
///   콘텐츠 흐름 밖이라 닫혀도 아래가 튀지 않는다.
/// - **가로 가운데.** 기준선은 호출부가 [top]으로 정한다(홈은 좌상단 로고와 같은 밴드).
/// - **줄바꿈 없이 내용만큼 늘어난다.** 화면을 넘을 때만 말줄임.
/// - 노출/종료는 [PillPolicy]가 전담. X = 영구 종료(빈도 무관).
class FloatingPill extends StatefulWidget {
  final FloatingPillSpec spec;

  /// Stack 기준 띄울 y.
  final double top;

  const FloatingPill({super.key, required this.spec, required this.top});

  @override
  State<FloatingPill> createState() => _FloatingPillState();
}

class _FloatingPillState extends State<FloatingPill> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final spec = widget.spec;
    final show = await PillPolicy.shouldShow(
      spec.id,
      spec.frequency,
      legacyDismissedKey: spec.legacyDismissedKey,
    );
    if (!mounted || !show) return;
    await PillPolicy.markShown(spec.id);
    if (mounted) setState(() => _visible = true);
  }

  Future<void> _close() async {
    if (_visible) setState(() => _visible = false);
    await PillPolicy.dismissForever(widget.spec.id);
  }

  Future<void> _tap() async {
    final spec = widget.spec;
    if (spec.onTap != null) {
      await spec.onTap!(context);
    } else if (spec.routeName != null && mounted) {
      await context.pushNamed(
        spec.routeName!,
        pathParameters: spec.pathParameters,
        queryParameters: spec.queryParameters,
      );
    }
    if (spec.dismissOnTap) {
      await _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Positioned(
      top: widget.top,
      left: 0,
      right: 0,
      child: Center(
        child: Padding(
          // 화면 끝에 닿지 않게. 이 안에서는 내용만큼 늘어난다.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: DismissiblePill(
              icon: widget.spec.icon,
              label: widget.spec.label,
              onTap: _tap,
              onClose: _close,
            ),
          ),
        ),
      ),
    );
  }
}
