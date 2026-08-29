import '../../constellation/data/models/constellation.dart';
import '../domain/share_payload.dart';

/// 별자리 엣지 중 '가장 드라마틱한' 연결 1개를 공유 카드 블록으로 매핑.
/// 우선순위: rationale 있음 -> strength 높음 -> 관계(달라짐 > 확장 > 다시 떠오름 > 닮음).
/// data 계층 매핑(presentation은 이 결과만 소비).
OrbConnection? pickOrbConnection(Constellation con) {
  final byId = {for (final n in con.nodes) n.id: n};
  final valid = con.edges
      .where((e) =>
          (e.rationale?.isNotEmpty ?? false) &&
          byId.containsKey(e.memoA) &&
          byId.containsKey(e.memoB))
      .toList();
  if (valid.isEmpty) return null;

  valid.sort((a, b) {
    final s = b.strength.compareTo(a.strength);
    if (s != 0) return s;
    return _relRank(a.relType).compareTo(_relRank(b.relType));
  });

  final e = valid.first;
  final a = byId[e.memoA]!;
  final b = byId[e.memoB]!;
  final past = a.createdAt.isBefore(b.createdAt) ? a : b;
  final now = a.createdAt.isBefore(b.createdAt) ? b : a;

  return OrbConnection(
    pastPreview: past.preview,
    nowPreview: now.preview,
    pastDate: past.createdAt,
    nowDate: now.createdAt,
    relLabel: _relLabel(e.relType),
    rationale: e.rationale,
  );
}

int _relRank(RelType? t) {
  switch (t) {
    case RelType.reverses:
      return 0;
    case RelType.extends_:
      return 1;
    case RelType.echo:
      return 2;
    case RelType.similar:
      return 3;
    default:
      return 4;
  }
}

String _relLabel(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return '확장';
    case RelType.reverses:
      return '달라짐';
    case RelType.echo:
      return '다시 떠오름';
    case RelType.similar:
      return '닮음';
    default:
      return '연결';
  }
}
