enum EstablishmentType {
  restaurante,
  escola;

  String get displayName {
    switch (this) {
      case EstablishmentType.restaurante:
        return 'Restaurante';
      case EstablishmentType.escola:
        return 'Escola';
    }
  }

  String get description {
    switch (this) {
      case EstablishmentType.restaurante:
        return 'Controle a produção do buffet de acordo com o movimento.';
      case EstablishmentType.escola:
        return 'Planeje as refeições de acordo com a presença dos alunos.';
    }
  }

  String get metricLabel {
    switch (this) {
      case EstablishmentType.restaurante:
        return 'Clientes';
      case EstablishmentType.escola:
        return 'Alunos presentes';
    }
  }

  String get expectedMetricLabel {
    switch (this) {
      case EstablishmentType.restaurante:
        return 'Previsão de clientes';
      case EstablishmentType.escola:
        return 'Alunos previstos';
    }
  }
}

class EstablishmentModel {
  final String id;
  final String name;
  final EstablishmentType type;
  final String ownerId;
  final String openingTime;
  final String closingTime;
  final int currentGuests;
  final int expectedGuests;
  final DateTime updatedAt;

  const EstablishmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    this.openingTime = '11:00',
    this.closingTime = '14:30',
    this.currentGuests = 0,
    this.expectedGuests = 100,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'ownerId': ownerId,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'currentGuests': currentGuests,
      'expectedGuests': expectedGuests,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EstablishmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EstablishmentModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] == 'escola'
          ? EstablishmentType.escola
          : EstablishmentType.restaurante,
      ownerId: map['ownerId'] ?? '',
      openingTime: map['openingTime'] ?? '11:00',
      closingTime: map['closingTime'] ?? '14:30',
      currentGuests: (map['currentGuests'] as num?)?.toInt() ?? 0,
      expectedGuests: (map['expectedGuests'] as num?)?.toInt() ?? 100,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  EstablishmentModel copyWith({
    String? id,
    String? name,
    EstablishmentType? type,
    String? ownerId,
    String? openingTime,
    String? closingTime,
    int? currentGuests,
    int? expectedGuests,
    DateTime? updatedAt,
  }) {
    return EstablishmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      currentGuests: currentGuests ?? this.currentGuests,
      expectedGuests: expectedGuests ?? this.expectedGuests,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
