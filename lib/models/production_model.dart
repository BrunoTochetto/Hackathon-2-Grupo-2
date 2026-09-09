class ProductionRecordModel {
  final String id;
  final String establishmentId;
  final String foodId;
  final String foodName;
  final double quantityProduced;
  final String unit;
  final double totalCost;
  final DateTime timestamp;

  const ProductionRecordModel({
    required this.id,
    required this.establishmentId,
    required this.foodId,
    required this.foodName,
    required this.quantityProduced,
    required this.unit,
    required this.totalCost,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'foodId': foodId,
      'foodName': foodName,
      'quantityProduced': quantityProduced,
      'unit': unit,
      'totalCost': totalCost,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ProductionRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductionRecordModel(
      id: id,
      establishmentId: map['establishmentId'] ?? '',
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      quantityProduced:
          (map['quantityProduced'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
