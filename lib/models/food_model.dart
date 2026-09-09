class FoodModel {
  final String id;
  final String name;
  final String category;
  final double currentStock; // Em kg ou unidade principal
  final String unit; // 'kg', 'g', 'un'
  final double batchSize; // Tamanho de um lote padrão (ex: 2.0 kg)
  final double costPerUnit; // Custo em R$ por unidade/kg
  final double consumptionPerPerson; // Consumo médio por pessoa (ex: 0.08 kg ou 80g)
  final DateTime updatedAt;

  const FoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    this.unit = 'kg',
    required this.batchSize,
    required this.costPerUnit,
    required this.consumptionPerPerson,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'unit': unit,
      'batchSize': batchSize,
      'costPerUnit': costPerUnit,
      'consumptionPerPerson': consumptionPerPerson,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map, String id) {
    return FoodModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Geral',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      batchSize: (map['batchSize'] as num?)?.toDouble() ?? 1.0,
      costPerUnit: (map['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      consumptionPerPerson:
          (map['consumptionPerPerson'] as num?)?.toDouble() ?? 0.08,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FoodModel copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    String? unit,
    double? batchSize,
    double? costPerUnit,
    double? consumptionPerPerson,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      batchSize: batchSize ?? this.batchSize,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      consumptionPerPerson:
          consumptionPerPerson ?? this.consumptionPerPerson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
