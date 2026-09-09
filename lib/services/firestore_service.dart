import 'dart:async';
import '../models/establishment_model.dart';
import '../models/food_model.dart';
import '../models/movement_model.dart';
import '../models/production_model.dart';
import '../models/history_model.dart';
import '../models/waste_model.dart';

/// Serviço do Firestore para gerenciar coleções multi-tenant por estabelecimento.
/// Implementa Streams reativos em tempo real e persistência em memória/cache.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initializeDefaultData();
  }

  // Stream controllers por entidade
  final StreamController<EstablishmentModel?> _establishmentStream =
      StreamController<EstablishmentModel?>.broadcast();
  final StreamController<List<FoodModel>> _foodsStream =
      StreamController<List<FoodModel>>.broadcast();
  final StreamController<List<MovementModel>> _movementsStream =
      StreamController<List<MovementModel>>.broadcast();
  final StreamController<List<ProductionRecordModel>> _productionsStream =
      StreamController<List<ProductionRecordModel>>.broadcast();
  final StreamController<List<HistoryRecordModel>> _historyStream =
      StreamController<List<HistoryRecordModel>>.broadcast();
  final StreamController<List<WasteRecordModel>> _wasteStream =
      StreamController<List<WasteRecordModel>>.broadcast();

  // Dados armazenados em cache / Firestore local
  EstablishmentModel? _currentEstablishment;
  final List<FoodModel> _foods = [];
  final List<MovementModel> _movements = [];
  final List<ProductionRecordModel> _productions = [];
  final List<HistoryRecordModel> _history = [];
  final List<WasteRecordModel> _wasteRecords = [];

  // Getters de Streams
  Stream<EstablishmentModel?> get establishmentStream => _establishmentStream.stream;
  Stream<List<FoodModel>> get foodsStream => _foodsStream.stream;
  Stream<List<MovementModel>> get movementsStream => _movementsStream.stream;
  Stream<List<ProductionRecordModel>> get productionsStream => _productionsStream.stream;
  Stream<List<HistoryRecordModel>> get historyStream => _historyStream.stream;
  Stream<List<WasteRecordModel>> get wasteStream => _wasteStream.stream;

  // Getters de dados síncronos atuais
  EstablishmentModel? get currentEstablishment => _currentEstablishment;
  List<FoodModel> get foods => List.unmodifiable(_foods);
  List<MovementModel> get movements => List.unmodifiable(_movements);
  List<ProductionRecordModel> get productions => List.unmodifiable(_productions);
  List<HistoryRecordModel> get history => List.unmodifiable(_history);
  List<WasteRecordModel> get wasteRecords => List.unmodifiable(_wasteRecords);

  void _initializeDefaultData() {
    final now = DateTime.now();
    _currentEstablishment = EstablishmentModel(
      id: 'est_default',
      name: 'Restaurante Sabor & Arte',
      type: EstablishmentType.restaurante,
      ownerId: 'user_default',
      openingTime: '11:00',
      closingTime: '14:30',
      currentGuests: 38,
      expectedGuests: 45,
      updatedAt: now,
    );

    _foods.addAll([
      FoodModel(
        id: 'f_arroz',
        name: 'Arroz Branco',
        category: 'Grãos',
        currentStock: 3.0,
        unit: 'kg',
        batchSize: 2.0,
        costPerUnit: 6.50,
        consumptionPerPerson: 0.08, // 80g
        updatedAt: now,
      ),
      FoodModel(
        id: 'f_feijao',
        name: 'Feijão Carioca',
        category: 'Grãos',
        currentStock: 2.5,
        unit: 'kg',
        batchSize: 1.5,
        costPerUnit: 8.90,
        consumptionPerPerson: 0.07, // 70g
        updatedAt: now,
      ),
      FoodModel(
        id: 'f_carne',
        name: 'Alcatra Grelhada',
        category: 'Proteínas',
        currentStock: 1.2,
        unit: 'kg',
        batchSize: 1.5,
        costPerUnit: 42.00,
        consumptionPerPerson: 0.12, // 120g
        updatedAt: now,
      ),
      FoodModel(
        id: 'f_frango',
        name: 'Filé de Frango Grelhado',
        category: 'Proteínas',
        currentStock: 2.0,
        unit: 'kg',
        batchSize: 2.0,
        costPerUnit: 22.50,
        consumptionPerPerson: 0.11, // 110g
        updatedAt: now,
      ),
      FoodModel(
        id: 'f_legumes',
        name: 'Legumes no Vapor',
        category: 'Acompanhamentos',
        currentStock: 1.8,
        unit: 'kg',
        batchSize: 1.5,
        costPerUnit: 9.80,
        consumptionPerPerson: 0.06, // 60g
        updatedAt: now,
      ),
    ]);

    // Movimentações simuladas iniciais do dia
    final baseTime = now.subtract(const Duration(minutes: 90));
    _movements.addAll([
      MovementModel(
        id: 'm1',
        establishmentId: 'est_default',
        delta: 10,
        totalCount: 10,
        timestamp: baseTime,
      ),
      MovementModel(
        id: 'm2',
        establishmentId: 'est_default',
        delta: 12,
        totalCount: 22,
        timestamp: baseTime.add(const Duration(minutes: 25)),
      ),
      MovementModel(
        id: 'm3',
        establishmentId: 'est_default',
        delta: 10,
        totalCount: 32,
        timestamp: baseTime.add(const Duration(minutes: 50)),
      ),
      MovementModel(
        id: 'm4',
        establishmentId: 'est_default',
        delta: 6,
        totalCount: 38,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    ]);

    // Histórico dos últimos 7 dias (incluindo hoje)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      _history.add(
        HistoryRecordModel(
          id: 'hist_$i',
          establishmentId: 'est_default',
          date: date,
          expectedGuests: i == 0 ? 45 : (45 + (i % 3) * 5),
          attendedGuests: i == 0 ? 38 : (42 + (i % 4) * 4),
          totalProductionKg: 28.5 + (i * 0.8),
          totalWasteKg: (1.2 + (i * 0.15)),
          totalCost: 320.0 + (i * 15),
          wasteAvoidedKg: 4.8 + (i * 0.3),
          savingsReais: 68.0 + (i * 5),
        ),
      );
    }

    // Desperdícios registrados
    _wasteRecords.addAll([
      WasteRecordModel(
        id: 'w1',
        establishmentId: 'est_default',
        foodId: 'f_arroz',
        foodName: 'Arroz Branco',
        wasteKg: 0.6,
        costReais: 3.90,
        reason: 'Sobra de rampa no fechamento',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      WasteRecordModel(
        id: 'w2',
        establishmentId: 'est_default',
        foodId: 'f_legumes',
        foodName: 'Legumes no Vapor',
        wasteKg: 0.4,
        costReais: 3.92,
        reason: 'Sobra de balcão',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  /// Define o estabelecimento ativo
  void setEstablishment(EstablishmentModel establishment) {
    _currentEstablishment = establishment;
    _establishmentStream.add(establishment);

    // Ajusta alimentos de demonstração se for escola
    if (establishment.type == EstablishmentType.escola && _foods.length <= 5) {
      _foods.clear();
      final now = DateTime.now();
      _foods.addAll([
        FoodModel(
          id: 'fe_arroz',
          name: 'Arroz Escolar Enriquecido',
          category: 'Grãos',
          currentStock: 18.0,
          unit: 'kg',
          batchSize: 10.0,
          costPerUnit: 5.20,
          consumptionPerPerson: 0.07,
          updatedAt: now,
        ),
        FoodModel(
          id: 'fe_feijao',
          name: 'Feijão Preto',
          category: 'Grãos',
          currentStock: 14.0,
          unit: 'kg',
          batchSize: 8.0,
          costPerUnit: 7.80,
          consumptionPerPerson: 0.06,
          updatedAt: now,
        ),
        FoodModel(
          id: 'fe_frango',
          name: 'Iscas de Frango com Legumes',
          category: 'Proteínas',
          currentStock: 16.0,
          unit: 'kg',
          batchSize: 12.0,
          costPerUnit: 18.00,
          consumptionPerPerson: 0.09,
          updatedAt: now,
        ),
        FoodModel(
          id: 'fe_macarrao',
          name: 'Macarrão com Molho de Tomate',
          category: 'Acompanhamentos',
          currentStock: 12.0,
          unit: 'kg',
          batchSize: 6.0,
          costPerUnit: 6.00,
          consumptionPerPerson: 0.06,
          updatedAt: now,
        ),
        FoodModel(
          id: 'fe_maca',
          name: 'Maçãs Higienizadas',
          category: 'Sobremesa',
          currentStock: 25.0,
          unit: 'kg',
          batchSize: 15.0,
          costPerUnit: 8.50,
          consumptionPerPerson: 0.08,
          updatedAt: now,
        ),
      ]);
      _foodsStream.add(_foods);
    }
  }

  /// Atualiza dados cadastrais do estabelecimento
  Future<void> updateEstablishmentDetails({
    required String name,
    required EstablishmentType type,
    required String openingTime,
    required String closingTime,
    required int expectedGuests,
  }) async {
    if (_currentEstablishment != null) {
      _currentEstablishment = _currentEstablishment!.copyWith(
        name: name,
        type: type,
        openingTime: openingTime,
        closingTime: closingTime,
        expectedGuests: expectedGuests,
        updatedAt: DateTime.now(),
      );
      _establishmentStream.add(_currentEstablishment);
    }
  }

  /// Registra alteração de movimento (+1, +5, +10, -1)
  Future<void> recordMovement(int delta, {String? note}) async {
    if (_currentEstablishment == null) return;

    final newCount = (_currentEstablishment!.currentGuests + delta).clamp(0, 9999);
    final now = DateTime.now();

    _currentEstablishment = _currentEstablishment!.copyWith(
      currentGuests: newCount,
      updatedAt: now,
    );
    _establishmentStream.add(_currentEstablishment);

    final movement = MovementModel(
      id: 'm_${now.millisecondsSinceEpoch}',
      establishmentId: _currentEstablishment!.id,
      delta: delta,
      totalCount: newCount,
      timestamp: now,
      note: note,
    );
    _movements.add(movement);
    _movementsStream.add(List.unmodifiable(_movements));
  }

  /// Adiciona registro de histórico (fechamento diário)
  Future<void> addHistoryRecord(HistoryRecordModel record) async {
    _history.insert(0, record);
    _historyStream.add(List.unmodifiable(_history));
  }

  /// Adiciona novo alimento
  Future<void> addFood(FoodModel food) async {
    _foods.add(food);
    _foodsStream.add(List.unmodifiable(_foods));
  }

  /// Edita alimento existente
  Future<void> updateFood(FoodModel updatedFood) async {
    final index = _foods.indexWhere((f) => f.id == updatedFood.id);
    if (index != -1) {
      _foods[index] = updatedFood;
      _foodsStream.add(List.unmodifiable(_foods));
    }
  }

  /// Remove alimento
  Future<void> deleteFood(String foodId) async {
    _foods.removeWhere((f) => f.id == foodId);
    _foodsStream.add(List.unmodifiable(_foods));
  }

  /// Atualiza o estoque disponível de um alimento diretamente
  Future<void> updateStock(String foodId, double newStock) async {
    final index = _foods.indexWhere((f) => f.id == foodId);
    if (index != -1) {
      _foods[index] = _foods[index].copyWith(
        currentStock: newStock.clamp(0.0, 9999.0),
        updatedAt: DateTime.now(),
      );
      _foodsStream.add(List.unmodifiable(_foods));
    }
  }

  /// Registra uma produção de lote concluída
  Future<void> recordProduction({
    required String foodId,
    required double quantity,
  }) async {
    final index = _foods.indexWhere((f) => f.id == foodId);
    if (index == -1) return;

    final food = _foods[index];
    final updatedStock = food.currentStock + quantity;
    _foods[index] = food.copyWith(
      currentStock: updatedStock,
      updatedAt: DateTime.now(),
    );
    _foodsStream.add(List.unmodifiable(_foods));

    final now = DateTime.now();
    final record = ProductionRecordModel(
      id: 'prod_${now.millisecondsSinceEpoch}',
      establishmentId: _currentEstablishment?.id ?? 'est_default',
      foodId: food.id,
      foodName: food.name,
      quantityProduced: quantity,
      unit: food.unit,
      totalCost: quantity * food.costPerUnit,
      timestamp: now,
    );

    _productions.insert(0, record);
    _productionsStream.add(List.unmodifiable(_productions));
  }

  /// Registra um descarte/desperdício de alimento
  Future<void> recordWaste({
    required String foodId,
    required double wasteKg,
    required String reason,
  }) async {
    final index = _foods.indexWhere((f) => f.id == foodId);
    if (index == -1) return;

    final food = _foods[index];
    // Subtrai do estoque se estiver descartando do balcão
    final newStock = (food.currentStock - wasteKg).clamp(0.0, 9999.0);
    _foods[index] = food.copyWith(
      currentStock: newStock,
      updatedAt: DateTime.now(),
    );
    _foodsStream.add(List.unmodifiable(_foods));

    final now = DateTime.now();
    final waste = WasteRecordModel(
      id: 'waste_${now.millisecondsSinceEpoch}',
      establishmentId: _currentEstablishment?.id ?? 'est_default',
      foodId: food.id,
      foodName: food.name,
      wasteKg: wasteKg,
      costReais: wasteKg * food.costPerUnit,
      reason: reason,
      timestamp: now,
    );

    _wasteRecords.insert(0, waste);
    _wasteStream.add(List.unmodifiable(_wasteRecords));
  }

  /// Limpa e reinicia o dia para demonstração ou novo turno
  void resetShift() {
    if (_currentEstablishment != null) {
      _currentEstablishment = _currentEstablishment!.copyWith(
        currentGuests: 0,
        updatedAt: DateTime.now(),
      );
      _establishmentStream.add(_currentEstablishment);
      _movements.clear();
      _movementsStream.add([]);
    }
  }
}
