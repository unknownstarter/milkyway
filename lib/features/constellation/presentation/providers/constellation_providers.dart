import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/constellation_repository.dart';
import '../../data/models/constellation.dart';

final constellationRepositoryProvider = Provider<ConstellationRepository>(
  (ref) => ConstellationRepository(Supabase.instance.client),
);

/// 내 별자리. 재진입마다 최신(autoDispose).
final constellationProvider = FutureProvider.autoDispose<Constellation>(
  (ref) => ref.watch(constellationRepositoryProvider).getConstellation(),
);
