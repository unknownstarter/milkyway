import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/others_content_refresh.dart';

/// 앱이 백그라운드에서 돌아오면 다른 사람 콘텐츠를 다시 받게 한다.
/// 마지막 새로고침 후 [othersContentRefreshInterval] 안이면 건너뛴다.
class OthersContentResumeRefresher extends ConsumerStatefulWidget {
  final Widget child;
  final DateTime Function() now;

  const OthersContentResumeRefresher({
    super.key,
    required this.child,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<OthersContentResumeRefresher> createState() =>
      _OthersContentResumeRefresherState();
}

class _OthersContentResumeRefresherState
    extends ConsumerState<OthersContentResumeRefresher> {
  late final AppLifecycleListener _listener;
  late DateTime _lastRefresh;

  @override
  void initState() {
    super.initState();
    _lastRefresh = widget.now();
    _listener = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    final now = widget.now();
    if (now.difference(_lastRefresh) < othersContentRefreshInterval) return;
    _lastRefresh = now;
    invalidateOthersContent(ref.invalidate);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
