import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';

final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseService.analytics);
});
