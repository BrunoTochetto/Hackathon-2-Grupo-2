import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/establishment_model.dart';
import '../models/food_model.dart';
import '../models/movement_model.dart';
import '../models/production_model.dart';
import '../models/recommendation_model.dart';
import '../models/history_model.dart';
import '../models/waste_model.dart';
import '../services/firestore_service.dart';
import '../services/recommendation_service.dart';
import '../services/backend_service.dart';

class BuffetProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final BackendService _backend = BackendService();
  StreamSubscription? _backendSub;

  EstablishmentModel? _establishment;
  List<FoodModel> _foods = [];
  List<MovementModel> _movements = [];
  List<ProductionRecordModel> _productions = [];
  List<HistoryRecordModel> _history = [];
  List<WasteRecordModel> _wasteRecords = [];

  bool _isLoading = true;

  // Propriedades recebidas e sincronizadas em tempo real com o Backend Node.js
  int _backendRemainingMin = 60;
  int _backendClients15Min = 0;
  int _backendTotalClientsToday = 0;
  String _backendAlertLevel = 'VERDE';
  String _backendInstruction = 'Produção normal. Cubas fundas padronizadas.';
  String _backendPanType = 'CUBA_FUNDA';
  String _backendPeriodDesc = 'HORÁRIO REGULAR';
  bool _backendIsPeak = false;
  Map<String, dynamic>? _backendClosingPhase;
  List<String> _openDays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  List<String> _manualHolidays = [];
  bool _isTodayHoliday = false;

  // Modo Demonstração (Hackathon)
  bool _isDemoMode = false;
  int _demoStep = 0;
  final List<Map<String, dynamic>> _demoScenarios = [
    {
      'title': 'Cenário 1 — Operação Normal',
      'expected': 120,
      'movement': 85,
      'remainingMin': 75,
      'situation': 'Normal',
      'description': 'Fluxo equilibrado com cubas fundas e reposição contínua.',
    },
    {
      'title': 'Cenário 2 — Movimento Abaixo do Previsto',
      'expected': 120,
      'movement': 40,
      'remainingMin': 45,
      'situation': 'Movimento abaixo do previsto',
      'description': 'Fluxo moderado. Reduzir para lotes médios de 2kg e cubas médias.',
    },
    {
      'title': 'Cenário 3 — Reta Final & Fechamento',
      'expected': 120,
      'movement': 18,
      'remainingMin': 20,
      'situation': 'Fechamento iminente (<= 30 min)',
      'description': 'Trocar para CUBAS RASAS e preparar exclusivamente sob demanda.',
    },
    {
      'title': 'Cenário 4 — Horário de Pico Intenso',
      'expected': 120,
      'movement': 110,
      'remainingMin': 50,
      'situation': 'Horário de pico (+35% demanda)',
      'description': 'Afluxo elevado. Aumentar ritmo de reposição no buffet.',
    },
  ];

  BuffetProvider() {
    _initData();
  }

  void _initData() {
    _establishment = _firestore.currentEstablishment;
    _foods = _firestore.foods;
    _movements = _firestore.movements;
    _productions = _firestore.productions;
    _history = _firestore.history;
    _wasteRecords = _firestore.wasteRecords;
    _isLoading = false;

    // Inicializa backend e sincroniza
    _backend.init();
    _backendSub = _backend.kitchenStream.listen((data) {
      _applyBackendPayload(data);
    });

    refreshFromBackend();
  }

  void _applyBackendPayload(Map<String, dynamic> data) {
    _backendAlertLevel = (data['nivel_alerta'] ?? _backendAlertLevel).toString().toUpperCase();
    _backendInstruction = data['instrucao'] ?? _backendInstruction;
    _backendRemainingMin = data['minutos_restantes'] ?? _backendRemainingMin;
    _backendClients15Min = data['clientes_15min'] ?? _backendClients15Min;
    _backendTotalClientsToday = data['total_clientes_hoje'] ?? _backendTotalClientsToday;
    _backendPanType = data['tipo_cuba'] ?? _backendPanType;
    _backendPeriodDesc = data['previsao_horario'] ?? _backendPeriodDesc;
    _backendIsPeak = data['is_horario_pico'] ?? false;
    _isTodayHoliday = data['is_feriado_manual'] ?? false;

    if (data['fase_fechamento'] is Map<String, dynamic>) {
      _backendClosingPhase = data['fase_fechamento'];
    }
    if (data['dias_funcionamento'] is List) {
      _openDays = List<String>.from(data['dias_funcionamento']);
    }
    if (data['feriados_manuais'] is List) {
      _manualHolidays = List<String>.from(data['feriados_manuais']);
    }

    if (data['alimentos'] is List) {
      final List<dynamic> alList = data['alimentos'];
      final List<FoodModel> updatedFoods = [];
      for (final a in alList) {
        final id = (a['id'] ?? '').toString();
        final name = a['nome'] ?? 'Alimento';
        final cat = a['categoria'] ?? 'Geral';
        final stock = (a['estoque_atual'] as num?)?.toDouble() ?? 0.0;
        final unit = a['unidade'] ?? 'kg';
        final batch = (a['tamanho_lote_padrao'] as num?)?.toDouble() ?? 2.0;
        final cons = (a['consumo_por_pessoa'] as num?)?.toDouble() ?? 0.080;

        updatedFoods.add(FoodModel(
          id: id,
          name: name,
          category: cat,
          currentStock: stock,
          unit: unit,
          batchSize: batch,
          costPerUnit: 12.0,
          consumptionPerPerson: cons,
          updatedAt: DateTime.now(),
        ));
      }
      if (updatedFoods.isNotEmpty) {
        _foods = updatedFoods;
      }
    }

    // Sincroniza dados do estabelecimento
    if (data['restaurante_nome'] != null) {
      _establishment = (_establishment ?? EstablishmentModel(
        id: 'est_1',
        name: data['restaurante_nome'],
        type: EstablishmentType.restaurante,
        ownerId: 'owner',
        updatedAt: DateTime.now(),
      )).copyWith(
        name: data['restaurante_nome'],
        closingTime: (data['horario_fechamento'] ?? '14:30').toString().substring(0, 5),
        openingTime: (data['horario_abertura'] ?? '11:00').toString().substring(0, 5),
        currentGuests: _backendTotalClientsToday,
      );
    }

    notifyListeners();
  }

  Future<void> refreshFromBackend() async {
    final status = await _backend.fetchStatus();
    if (status != null) {
      _applyBackendPayload(status);
    }
  }

  @override
  void dispose() {
    _backendSub?.cancel();
    super.dispose();
  }

  // Getters principais
  bool get isLoading => _isLoading;
  bool get isDemoMode => _isDemoMode;
  int get demoStep => _demoStep;
  Map<String, dynamic> get currentDemoScenario => _demoScenarios[_demoStep];

  EstablishmentModel get establishment {
    final est = _establishment ??
        EstablishmentModel(
          id: 'est_default',
          name: 'Restaurante Sabor & Arte',
          type: EstablishmentType.restaurante,
          ownerId: 'owner',
          openingTime: '11:00',
          closingTime: '14:30',
          currentGuests: _backendTotalClientsToday > 0 ? _backendTotalClientsToday : 38,
          expectedGuests: 120,
          updatedAt: DateTime.now(),
        );

    if (_isDemoMode) {
      final scenario = _demoScenarios[_demoStep];
      return est.copyWith(
        currentGuests: scenario['movement'] as int,
        expectedGuests: scenario['expected'] as int,
      );
    }

    return est;
  }

  List<FoodModel> get foods => _foods;
  List<MovementModel> get movements => _movements;
  List<ProductionRecordModel> get productions => _productions;
  List<HistoryRecordModel> get history => _history;
  List<WasteRecordModel> get wasteRecords => _wasteRecords;

  List<String> get openDays => _openDays;
  List<String> get manualHolidays => _manualHolidays;
  bool get isTodayHoliday => _isTodayHoliday;
  Map<String, dynamic>? get closingPhaseExplanation => _backendClosingPhase;

  /// Clientes nos últimos 15 minutos (soma do fluxo recente de entradas/saídas)
  int get clientsLast15Minutes {
    if (_isDemoMode) {
      return (_demoScenarios[_demoStep]['movement'] as int) ~/ 4;
    }
    if (_backendClients15Min > 0) return _backendClients15Min;
    final threshold = DateTime.now().subtract(const Duration(minutes: 15));
    final recent = _movements
        .where((m) => m.timestamp.isAfter(threshold))
        .fold<int>(0, (sum, m) => sum + m.delta);
    return recent > 0 ? recent : 12;
  }

  /// Identifica se o horário atual é de pico
  bool get isPeakHour {
    if (_isDemoMode) {
      return _demoStep == 3;
    }
    return _backendIsPeak;
  }

  /// Previsão do período operacional (Pico vs Baixa)
  String get currentPeriodDescription {
    if (_isDemoMode) {
      return _demoScenarios[_demoStep]['description'] as String;
    }
    return _backendPeriodDesc;
  }

  /// Nível de alerta exato do Motor de Regras: VERDE, AMARELO, VERMELHO
  String get productionAlertLevel {
    if (_isDemoMode) {
      if (_demoStep == 2) return 'VERMELHO';
      if (_demoStep == 1) return 'AMARELO';
      return 'VERDE';
    }
    return _backendAlertLevel;
  }

  /// Instrução da Cozinha em tempo real (Sem termo batch-cooking)
  String get productionAlertInstruction {
    if (_isDemoMode) {
      if (_demoStep == 2) {
        return 'Atenção: Trocar para CUBAS RASAS! Preparo sob demanda (lotes de 1kg).';
      }
      if (_demoStep == 1) {
        return 'Reduzir ritmo. Lotes médios de 2kg em cubas intermediárias.';
      }
      return 'Produção normal. Cubas fundas padronizadas.';
    }
    return _backendInstruction;
  }

  /// Tipo de cuba recomendado
  String get suggestedPanType {
    if (_isDemoMode) {
      if (_demoStep == 2) return 'CUBAS RASAS (Preparo sob Demanda)';
      if (_demoStep == 1) return 'CUBAS MÉDIAS (Lote 2kg)';
      return 'CUBAS FUNDAS (Padronizadas)';
    }
    return _backendPanType;
  }

  /// Demanda calculada pelo fluxo instantâneo de clientes
  Map<String, double> get foodDemandForCurrentFlow {
    final clientsBase = clientsLast15Minutes > 0 ? clientsLast15Minutes : 10;
    final mult = isPeakHour ? 1.35 : (remainingMinutes <= 30 ? 0.50 : 0.85);
    final Map<String, double> demands = {};
    for (final food in _foods) {
      final demandKg = clientsBase * food.consumptionPerPerson * mult;
      demands[food.id] = double.parse(demandKg.toStringAsFixed(2));
    }
    return demands;
  }

  int get remainingMinutes {
    if (_isDemoMode) {
      return _demoScenarios[_demoStep]['remainingMin'] as int;
    }
    if (_backendRemainingMin > 0) return _backendRemainingMin;
    return RecommendationService.calculateRemainingMinutes(
      closingTime: establishment.closingTime,
    );
  }

  OverallSituation get overallSituation {
    if (_isDemoMode) {
      final scenario = _demoScenarios[_demoStep];
      return OverallSituation(
        title: scenario['situation'] as String,
        description: scenario['description'] as String,
        statusLevel: _demoStep == 0
            ? 'success'
            : _demoStep == 3
                ? 'alert'
                : 'warning',
      );
    }

    return OverallSituation(
      title: 'Status: $productionAlertLevel',
      description: productionAlertInstruction,
      statusLevel: productionAlertLevel == 'VERMELHO'
          ? 'alert'
          : productionAlertLevel == 'AMARELO'
              ? 'warning'
              : 'success',
    );
  }

  List<FoodRecommendation> get recommendations {
    final curGuests = establishment.currentGuests;
    final expGuests = establishment.expectedGuests;
    final remMin = remainingMinutes;

    return _foods.map((food) {
      return RecommendationService.calculateRecommendation(
        food: food,
        currentGuests: curGuests,
        expectedGuests: expGuests,
        remainingMinutes: remMin,
      );
    }).toList();
  }

  double get totalWasteTodayKg {
    return _wasteRecords.fold<double>(0.0, (sum, item) => sum + item.wasteKg);
  }

  double get totalWasteCostToday {
    return _wasteRecords.fold<double>(0.0, (sum, item) => sum + item.costReais);
  }

  Map<String, double> get savingsEstimates => {
    'avoidedWeekKg': 14.5,
    'savingsWeekReais': 280.0,
  };

  // ==========================================
  // AÇÕES DE FLUXO & DADOS
  // ==========================================
  Future<void> recordMovement(int delta, {String? note}) async {
    if (_isDemoMode) return;

    final newTotal = (_establishment?.currentGuests ?? 0) + delta;
    final movement = MovementModel(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      establishmentId: _establishment?.id ?? 'est_1',
      delta: delta,
      totalCount: newTotal < 0 ? 0 : newTotal,
      timestamp: DateTime.now(),
      note: note ?? 'Fluxo de entrada/saída de clientes',
    );
    _movements.insert(0, movement);

    _establishment = _establishment?.copyWith(
      currentGuests: newTotal < 0 ? 0 : newTotal,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Sincroniza com backend Node.js
    await _backend.recordFluxo(quantidade: delta);
  }

  Future<void> addFood(FoodModel food) async {
    final success = await _backend.addAlimento(
      name: food.name,
      category: food.category,
      currentStock: food.currentStock,
      consumptionPerPerson: food.consumptionPerPerson,
      standardBatch: food.batchSize,
      reducedBatch: (food.batchSize * 0.5).clamp(0.5, 2.0),
      unit: food.unit,
    );

    if (!success) {
      _foods.add(food);
      notifyListeners();
    }
  }

  Future<void> updateFood(FoodModel food) async {
    final numId = int.tryParse(food.id);
    if (numId != null) {
      await _backend.updateAlimento(numId, {
        'nome': food.name,
        'categoria': food.category,
        'estoque_atual': food.currentStock,
        'consumo_por_pessoa': food.consumptionPerPerson,
        'tamanho_lote_padrao': food.batchSize,
        'unidade': food.unit,
      });
    } else {
      final index = _foods.indexWhere((f) => f.id == food.id);
      if (index != -1) {
        _foods[index] = food;
        notifyListeners();
      }
    }
  }

  Future<void> deleteFood(String foodId) async {
    final numId = int.tryParse(foodId);
    if (numId != null) {
      await _backend.deleteAlimento(numId);
    }
    _foods.removeWhere((f) => f.id == foodId);
    notifyListeners();
  }

  Future<void> updateStock(String foodId, double newStock) async {
    final numId = int.tryParse(foodId);
    if (numId != null) {
      await _backend.updateAlimento(numId, {'estoque_atual': newStock});
    }
    final index = _foods.indexWhere((f) => f.id == foodId);
    if (index != -1) {
      _foods[index] = _foods[index].copyWith(currentStock: newStock);
      notifyListeners();
    }
  }

  Future<void> recordProduction(String foodId, double quantity) async {
    final numId = int.tryParse(foodId);
    if (numId != null) {
      await _backend.updateAlimento(numId, {'estoque_atual': quantity});
    }
    notifyListeners();
  }

  Future<void> recordWaste(String foodId, double wasteKg, String reason) async {
    _wasteRecords.insert(
      0,
      WasteRecordModel(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
        establishmentId: _establishment?.id ?? 'est_1',
        foodId: foodId,
        foodName: _foods.isNotEmpty
            ? _foods.firstWhere((f) => f.id == foodId, orElse: () => _foods.first).name
            : 'Alimento',
        wasteKg: wasteKg,
        costReais: wasteKg * 15.0,
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> addHistoryRecord(HistoryRecordModel record) async {
    _history.insert(0, record);
    notifyListeners();
  }

  Future<void> updateEstablishment({
    required String name,
    required EstablishmentType type,
    required String openingTime,
    required String closingTime,
    required int expectedGuests,
  }) async {
    _establishment = (_establishment ?? EstablishmentModel(
      id: 'est_1',
      name: name,
      type: type,
      ownerId: 'owner',
      updatedAt: DateTime.now(),
    )).copyWith(
      name: name,
      type: type,
      openingTime: openingTime,
      closingTime: closingTime,
      expectedGuests: expectedGuests,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void setEstablishment(EstablishmentModel establishment) {
    _establishment = establishment;
    notifyListeners();
  }

  Future<void> updateClosingTime(String closingTime) async {
    await _backend.updateClosingTime(closingTime: closingTime);
    if (_establishment != null) {
      _establishment = _establishment!.copyWith(closingTime: closingTime);
      notifyListeners();
    }
  }

  Future<void> toggleManualHoliday(String dayCode) async {
    final updatedHolidays = List<String>.from(_manualHolidays);
    if (updatedHolidays.contains(dayCode)) {
      updatedHolidays.remove(dayCode);
    } else {
      updatedHolidays.add(dayCode);
    }
    _manualHolidays = updatedHolidays;
    notifyListeners();

    await _backend.updateConfig(manualHolidays: updatedHolidays);
  }

  Future<void> updateConfigHours({
    String? openingTime,
    String? closingTime,
    String? peakStartTime,
    String? peakEndTime,
    List<String>? openDays,
  }) async {
    await _backend.updateConfig(
      openingTime: openingTime,
      closingTime: closingTime,
      peakStartTime: peakStartTime,
      peakEndTime: peakEndTime,
      openDays: openDays,
    );
    refreshFromBackend();
  }

  // Controle do Modo Demonstração
  void toggleDemoMode() {
    _isDemoMode = !_isDemoMode;
    _demoStep = 0;
    notifyListeners();
  }

  void setDemoStep(int step) {
    if (step >= 0 && step < _demoScenarios.length) {
      _demoStep = step;
      notifyListeners();
    }
  }

  void nextDemoStep() {
    _demoStep = (_demoStep + 1) % _demoScenarios.length;
    notifyListeners();
  }
}
