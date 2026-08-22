/// 별자리 그래프: 노드(별=메모) + 엣지(선=관계). get_constellation RPC 결과.
class ConNode {
  final String id;
  final String preview;
  final DateTime createdAt;

  ConNode({required this.id, required this.preview, required this.createdAt});

  factory ConNode.fromJson(Map<String, dynamic> j) => ConNode(
        id: j['id'] as String,
        preview: (j['preview'] as String?)?.trim() ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// 관계 4종.
enum RelType { similar, extends_, reverses, echo }

RelType? relFromString(String? s) {
  switch (s) {
    case 'similar':
      return RelType.similar;
    case 'extends':
      return RelType.extends_;
    case 'reverses':
      return RelType.reverses;
    case 'echo':
      return RelType.echo;
    default:
      return null;
  }
}

class ConEdge {
  final String memoA;
  final String memoB;
  final RelType? relType;
  final double strength;
  final String? rationale;

  ConEdge({
    required this.memoA,
    required this.memoB,
    required this.relType,
    required this.strength,
    this.rationale,
  });

  factory ConEdge.fromJson(Map<String, dynamic> j) => ConEdge(
        memoA: j['memo_a'] as String,
        memoB: j['memo_b'] as String,
        relType: relFromString(j['rel_type'] as String?),
        strength: (j['strength'] as num).toDouble(),
        rationale: j['rationale'] as String?,
      );
}

class Constellation {
  final List<ConNode> nodes;
  final List<ConEdge> edges;

  Constellation({required this.nodes, required this.edges});

  bool get isEmpty => nodes.isEmpty;

  factory Constellation.fromJson(Map<String, dynamic> j) => Constellation(
        nodes: ((j['nodes'] as List?) ?? [])
            .map((e) => ConNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        edges: ((j['edges'] as List?) ?? [])
            .map((e) => ConEdge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
