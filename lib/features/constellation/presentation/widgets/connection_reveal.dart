import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/constellation.dart';

String _relLabel(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return '확장';
    case RelType.reverses:
      return '뒤집힘';
    case RelType.echo:
      return '메아리';
    case RelType.similar:
      return '닮음';
    default:
      return '연결';
  }
}

Color _relColor(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return AppColors.textBright;
    case RelType.reverses:
      return AppColors.danger.withValues(alpha: 0.8);
    case RelType.echo:
      return AppColors.accentGreen;
    case RelType.similar:
    default:
      return AppColors.textSecondary;
  }
}

/// 첫 선 리빌 = 메모 저장 직후 연결이 잡히면 조용히 뜨는 Lyra 카드(바텀시트).
Future<void> showConnectionReveal(
  BuildContext context, {
  required RelType? relType,
  required String rationale,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 2,
                  color: _relColor(relType),
                ),
                const SizedBox(width: 8),
                Text('선이 하나 그어졌어',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Text(_relLabel(relType),
                    style: AppTypography.caption.copyWith(
                        color: _relColor(relType),
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 8),
                  child: Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.accentGreen),
                ),
                Expanded(
                  child: Text(rationale,
                      style: AppTypography.body.copyWith(
                          color: AppColors.textBright, height: 1.6)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.pushNamed(AppRoutes.constellationName);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  child: Text('별자리에서 보기',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 앱 전역에서 memo_edges insert(내 것)를 Realtime 구독 -> 연결 생기면 리빌.
/// [child]를 감싸서 트리에 상주. push, not pull.
class ConnectionRevealListener extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectionRevealListener({super.key, required this.child});

  @override
  ConsumerState<ConnectionRevealListener> createState() =>
      _ConnectionRevealListenerState();
}

class _ConnectionRevealListenerState
    extends ConsumerState<ConnectionRevealListener> {
  RealtimeChannel? _channel;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  bool _showing = false;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = ref.read(authProvider).value?.id;
    if (uid != null && uid != _userId) {
      _userId = uid;
      _subscribe(uid);
    }
  }

  void _subscribe(String uid) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('reveal:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'memo_edges',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: _onInsert,
        )
        .subscribe();
  }

  void _onInsert(PostgresChangePayload payload) {
    final row = payload.newRecord;
    final rationale = row['rationale'] as String?;
    if (rationale == null || rationale.isEmpty) return;
    // 한 메모가 여러 선을 만들어도 리빌은 하나만(첫 = 가장 강한 것). 6초 스로틀.
    final now = DateTime.now();
    if (_showing || now.difference(_lastShown).inSeconds < 6) return;
    _lastShown = now;
    _showing = true;
    final rel = relFromString(row['rel_type'] as String?);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _showing = false;
        return;
      }
      await showConnectionReveal(context, relType: rel, rationale: rationale);
      _showing = false;
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
