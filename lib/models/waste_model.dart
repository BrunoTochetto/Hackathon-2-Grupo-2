class WasteRecordModel {
  final String id;
  final String establishmentId;
  final String foodId;
  final String foodName;
  final double wasteKg;
  final double costReais;
  final String reason;
  final DateTime timestamp;

  const WasteRecordModel({
    required this.id,
    required this.establishmentId,
    required this.foodId,
    required this.foodName,
    required this.wasteKg,
    required this.costReais,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'foodId': foodId,
      'foodName': foodName,
      'wasteKg': wasteKg,
      'costReais': costReais,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WasteRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return WasteRecordModel(
      id: id,
      establishmentId: map['establishmentId'] ?? '',
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      wasteKg: (map['wasteKg'] as num?)?.toDouble() ?? 0.0,
      costReais: (map['costReais'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? 'Sobra de balcão',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
