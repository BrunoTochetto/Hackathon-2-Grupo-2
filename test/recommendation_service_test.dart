import 'package:flutter_test/flutter_test.dart';
import 'package:ver/models/establishment_model.dart';
import 'package:ver/models/food_model.dart';
import 'package:ver/models/recommendation_model.dart';
import 'package:ver/services/recommendation_service.dart';

void main() {
  group('SmartBuffet - RecommendationService Engine Tests', () {
    late FoodModel baseRice;
    late FoodModel baseMeat;

    setUp(() {
      baseRice = FoodModel(
        id: 'food-rice',
        name: 'Arroz Branco',
        category: 'Grãos',
        currentStock: 3.0, // 3 kg
        unit: 'kg',
        batchSize: 2.0, // 2 kg por lote
        costPerUnit: 6.50,
        consumptionPerPerson: 0.08, // 80g por pessoa
        updatedAt: DateTime.now(),
      );

      baseMeat = FoodModel(
        id: 'food-meat',
        name: 'Carne Grelhada',
        category: 'Proteína',
        currentStock: 0.8,
        unit: 'kg',
        batchSize: 1.5,
        costPerUnit: 38.00,
        consumptionPerPerson: 0.12, // 120g por pessoa
        updatedAt: DateTime.now(),
      );
    });

    test('1. Movimento abaixo da previsão: deve recomendar reduzir produção', () {
      // Previsão 400 pessoas, movimento 200 (50%, abaixo do limiar de 70%)
      // Estoque baixo para forçar cálculo de produção, porém com ritmo reduzido
      final lowStockRice = baseRice.copyWith(currentStock: 1.0);
      final rec = RecommendationService.calculateRecommendation(
        food: lowStockRice,
        currentGuests: 200,
        expectedGuests: 400,
        remainingMinutes: 90,
      );

      expect(rec.action, equals(RecommendationAction.reduzir));
      expect(rec.recommendedQuantity, greaterThan(0));
    });

    test('2. Movimento próximo da previsão: deve recomendar produção normal', () {
      // Previsão 400, movimento 360 (90%)
      final lowStockRice = baseRice.copyWith(currentStock: 1.0);
      final rec = RecommendationService.calculateRecommendation(
        food: lowStockRice,
        currentGuests: 360,
        expectedGuests: 400,
        remainingMinutes: 70,
      );

      expect(rec.action, equals(RecommendationAction.normal));
    });

    test('3. Movimento acima da previsão: deve recomendar aumentar produção', () {
      // Previsão 200, movimento 240 (120% da previsão)
      final lowStockMeat = baseMeat.copyWith(currentStock: 0.5);
      final rec = RecommendationService.calculateRecommendation(
        food: lowStockMeat,
        currentGuests: 240,
        expectedGuests: 200,
        remainingMinutes: 60,
      );

      expect(rec.action, equals(RecommendationAction.aumentar));
      expect(rec.urgencyLevel, equals('high'));
    });

    test('4. Pouco tempo restante com déficit: deve sugerir produção mínima', () {
      // Restam 15 minutos e falta um pouco de carne
      final lowStockMeat = baseMeat.copyWith(currentStock: 0.2);
      final rec = RecommendationService.calculateRecommendation(
        food: lowStockMeat,
        currentGuests: 180,
        expectedGuests: 200,
        remainingMinutes: 15,
      );

      expect(rec.action, equals(RecommendationAction.minima));
    });

    test('5. Estoque suficiente: não deve iniciar novo lote', () {
      // Restam 20 pessoas (400 - 380), arroz precisa de 20 * 0.08 = 1.6 kg
      // Estoque tem 3.0 kg -> tem mais que suficiente!
      final rec = RecommendationService.calculateRecommendation(
        food: baseRice, // stock = 3.0
        currentGuests: 380,
        expectedGuests: 400,
        remainingMinutes: 45,
      );

      expect(rec.action, equals(RecommendationAction.naoIniciar));
      expect(rec.recommendedQuantity, equals(0.0));
    });

    test('6. Estoque crítico/baixo com demanda em andamento', () {
      // Estoque de carne está em 0.1 kg (muito abaixo de 25% do lote de 1.5kg)
      final criticalMeat = baseMeat.copyWith(currentStock: 0.1);
      final rec = RecommendationService.calculateRecommendation(
        food: criticalMeat,
        currentGuests: 190,
        expectedGuests: 200,
        remainingMinutes: 50,
      );

      expect(rec.urgencyLevel, equals('high'));
      expect(rec.action, equals(RecommendationAction.aumentar));
    });

    test('7. Movimento alto + Estoque baixo: produção de alta urgência', () {
      final criticalRice = baseRice.copyWith(currentStock: 0.2);
      final rec = RecommendationService.calculateRecommendation(
        food: criticalRice,
        currentGuests: 390,
        expectedGuests: 400,
        remainingMinutes: 40,
      );

      expect(rec.urgencyLevel, equals('high'));
      expect(rec.action, equals(RecommendationAction.aumentar));
    });

    test('8. Movimento baixo + Estoque suficiente: não produzir e economizar', () {
      // Movimento muito baixo (150 de 400) e arroz com estoque de sobra (18kg supre os 14kg projetados)
      final ampleRice = baseRice.copyWith(currentStock: 18.0);
      final rec = RecommendationService.calculateRecommendation(
        food: ampleRice,
        currentGuests: 150,
        expectedGuests: 400,
        remainingMinutes: 90,
      );

      expect(rec.action, equals(RecommendationAction.naoIniciar));
      expect(rec.recommendedQuantity, equals(0.0));
    });

    test('9. Necessidade de novo lote identificada corretamente', () {
      // Faltam 100 pessoas (200 de 300), arroz precisa de 100 * 0.08 = 8 kg.
      // Estoque tem apenas 1.0 kg -> déficit de 7 kg
      final lowRice = baseRice.copyWith(currentStock: 1.0);
      final rec = RecommendationService.calculateRecommendation(
        food: lowRice,
        currentGuests: 200,
        expectedGuests: 300,
        remainingMinutes: 80,
      );

      expect(rec.action, isNot(equals(RecommendationAction.naoIniciar)));
      expect(rec.recommendedQuantity, greaterThan(0.0));
    });

    test('10. Pouco tempo restante E estoque suficiente: trava lote para evitar sobras', () {
      // Faltam 10 minutos para o fechamento e arroz tem 2.0 kg para apenas 5 pessoas restantes
      final rec = RecommendationService.calculateRecommendation(
        food: baseRice,
        currentGuests: 395,
        expectedGuests: 400,
        remainingMinutes: 10,
      );

      expect(rec.action, equals(RecommendationAction.naoIniciar));
      expect(rec.recommendedQuantity, equals(0.0));
    });

    test('Avaliação geral da situação: Restaurante vs Escola', () {
      final sitRestaurante = RecommendationService.evaluateOverallSituation(
        currentGuests: 150,
        expectedGuests: 400,
        remainingMinutes: 20,
        type: EstablishmentType.restaurante,
      );
      expect(sitRestaurante.title, contains('Pouco movimento'));

      final sitEscola = RecommendationService.evaluateOverallSituation(
        currentGuests: 200,
        expectedGuests: 400,
        remainingMinutes: 80,
        type: EstablishmentType.escola,
      );
      expect(sitEscola.title, contains('Presença abaixo'));
    });
  });
}
