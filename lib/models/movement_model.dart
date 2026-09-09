class MovementModel {
  final String id;
  final String establishmentId;
  final int delta;
  final int totalCount;
  final DateTime timestamp;
  final String? note;

  const MovementModel({
    required this.id,
    required this.establishmentId,
    required this.delta,
    required this.totalCount,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'delta': delta,
      'totalCount': totalCount,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory MovementModel.fromMap(Map<String, dynamic> map, String id) {
    return MovementModel(
      id: id,
      establishmentId: map['establishmentId'] ?? '',
      delta: (map['delta'] as num?)?.toInt() ?? 0,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'],
    );
  }
}
