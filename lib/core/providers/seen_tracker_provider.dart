import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/seen_tracker.dart';

/// 기기 로컬 '봤음' 시각 추적 서비스 provider.
/// 책별(홈 링/책탭 점) + 탭별(하단 네비 점) 판정에 공용으로 쓰인다.
final seenTrackerProvider = Provider<SeenTracker>((ref) => SeenTracker());
