class HistoryRecordModel {
  final String id;
  final String establishmentId;
  final DateTime date;
  final int expectedGuests;
  final int attendedGuests;
  final double totalProductionKg;
  final double totalWasteKg;
  final double totalCost;
  final double wasteAvoidedKg;
  final double savingsReais;

  const HistoryRecordModel({
    required this.id,
    required this.establishmentId,
    required this.date,
    required this.expectedGuests,
    required this.attendedGuests,
    required this.totalProductionKg,
    required this.totalWasteKg,
    required this.totalCost,
    required this.wasteAvoidedKg,
    required this.savingsReais,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'date': date.toIso8601String(),
      'expectedGuests': expectedGuests,
      'attendedGuests': attendedGuests,
      'totalProductionKg': totalProductionKg,
      'totalWasteKg': totalWasteKg,
      'totalCost': totalCost,
      'wasteAvoidedKg': wasteAvoidedKg,
      'savingsReais': savingsReais,
    };
  }

  factory HistoryRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return HistoryRecordModel(
      id: id,
      establishmentId: map['establishmentId'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      expectedGuests: (map['expectedGuests'] as num?)?.toInt() ?? 0,
      attendedGuests: (map['attendedGuests'] as num?)?.toInt() ?? 0,
      totalProductionKg:
          (map['totalProductionKg'] as num?)?.toDouble() ?? 0.0,
      totalWasteKg: (map['totalWasteKg'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      wasteAvoidedKg: (map['wasteAvoidedKg'] as num?)?.toDouble() ?? 0.0,
      savingsReais: (map['savingsReais'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
