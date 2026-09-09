import 'dart:math';
import '../models/establishment_model.dart';
import '../models/food_model.dart';
import '../models/recommendation_model.dart';

class RecommendationService {
  static const int kLowTimeRemainingThresholdMinutes = 30;
  static const double kLowMovementRatio = 0.70;
  static const double kHighMovementRatio = 1.10;
  static const double kLowStockRatio = 0.25;

  static OverallSituation evaluateOverallSituation({
    required int currentGuests,
    required int expectedGuests,
    required int remainingMinutes,
    EstablishmentType type = EstablishmentType.restaurante,
  }) {
    if (expectedGuests <= 0) {
      return const OverallSituation(
        title: 'Dados em aberto',
        description: 'Defina a previsão diária para ativar as análises.',
        statusLevel: 'info',
      );
    }

    final double ratio = currentGuests / expectedGuests;

    if (remainingMinutes <= kLowTimeRemainingThresholdMinutes && currentGuests < (expectedGuests * 0.6)) {
      return OverallSituation(
        title: type == EstablishmentType.escola
            ? 'Pouca presença e fim do turno'
            : 'Pouco movimento e pouco tempo restante',
        description:
            'Aproximando-se do encerramento. Evite iniciar novos lotes de grande volume.',
        statusLevel: 'warning',
      );
    }

    if (ratio < kLowMovementRatio) {
      return OverallSituation(
        title: type == EstablishmentType.escola
            ? 'Presença abaixo do previsto'
            : 'Movimento abaixo do esperado',
        description:
            'O fluxo atual está abaixo da média estimada. Reduza os próximos preparos.',
        statusLevel: 'warning',
      );
    } else if (ratio > kHighMovementRatio) {
      return OverallSituation(
        title: type == EstablishmentType.escola
            ? 'Presença acima do previsto'
            : 'Movimento acima do previsto',
        description:
            'O fluxo ultrapassou a projeção. Acelere a reposição dos itens de maior saída.',
        statusLevel: 'alert',
      );
    } else {
      return OverallSituation(
        title: 'Movimento dentro do esperado',
        description:
            'Fluxo equilibrado com a previsão. Mantenha os lotes normais programados.',
        statusLevel: 'success',
      );
    }
  }

  static FoodRecommendation calculateRecommendation({
    required FoodModel food,
    required int currentGuests,
    required int expectedGuests,
    required int remainingMinutes,
  }) {
    final bool isLowTimeRemaining = remainingMinutes <= kLowTimeRemainingThresholdMinutes;

    // Se o movimento ultrapassou a previsão e ainda há tempo de serviço
    final bool isOverCapacity = expectedGuests > 0 && currentGuests > (expectedGuests * kHighMovementRatio);
    final bool isUnderCapacity = expectedGuests > 0 && currentGuests < (expectedGuests * kLowMovementRatio);

    // Quantidade de pessoas adicionais esperadas
    int projectedRemainingGuests;
    if (isOverCapacity && remainingMinutes > 10) {
      // Fluxo em alta: estima que continuarão entrando cerca de 15% a mais de clientes
      projectedRemainingGuests = max(15, ((currentGuests - expectedGuests) + (remainingMinutes ~/ 5)));
    } else {
      projectedRemainingGuests = max(0, expectedGuests - currentGuests);
    }

    // Demanda projetada
    double projectedDemand = projectedRemainingGuests * food.consumptionPerPerson;
    if (isUnderCapacity) {
      projectedDemand *= 0.70; // Reduz a projeção em ritmo baixo
    }

    final bool hasEnoughFood = food.currentStock >= projectedDemand && projectedDemand >= 0;
    final bool isLowStock = food.currentStock <= (food.batchSize * kLowStockRatio);
    final double deficit = projectedDemand - food.currentStock;

    // REGRA 1: Estoque suficiente cobre tudo até o final -> NÃO INICIAR NOVO LOTE
    if (hasEnoughFood) {
      return FoodRecommendation(
        foodId: food.id,
        foodName: food.name,
        action: RecommendationAction.naoIniciar,
        recommendedQuantity: 0.0,
        unit: food.unit,
        reason: isLowTimeRemaining
            ? 'Restam apenas $remainingMinutes min e o estoque disponível (${food.currentStock.toStringAsFixed(1)} ${food.unit}) supre a demanda restante.'
            : 'Estoque disponível supre com segurança a demanda estimada.',
        urgencyLevel: 'low',
        currentStock: food.currentStock,
        batchSize: food.batchSize,
      );
    }

    // REGRA 2: Pouco tempo restante e déficit pequeno -> PRODUÇÃO MÍNIMA
    if (isLowTimeRemaining && deficit > 0) {
      final double minQty = roundToReasonableStep(min(deficit, food.batchSize * 0.4), 0.2);
      return FoodRecommendation(
        foodId: food.id,
        foodName: food.name,
        action: RecommendationAction.minima,
        recommendedQuantity: max(minQty, 0.3),
        unit: food.unit,
        reason: 'Restam apenas $remainingMinutes min. Produzir lote mínimo para evitar sobras no fechamento.',
        urgencyLevel: 'normal',
        currentStock: food.currentStock,
        batchSize: food.batchSize,
      );
    }

    // REGRA 3: Estoque baixo E movimento alto / Acima da previsão -> AUMENTAR PRODUÇÃO
    if (isOverCapacity || (isLowStock && currentGuests > (expectedGuests * 0.75))) {
      final double qty = max(food.batchSize, roundToReasonableStep(deficit * 1.2, food.batchSize));
      return FoodRecommendation(
        foodId: food.id,
        foodName: food.name,
        action: RecommendationAction.aumentar,
        recommendedQuantity: qty,
        unit: food.unit,
        reason: isOverCapacity
            ? 'Movimento acima do previsto. Aumentar produção e antecipar reposição.'
            : 'Estoque baixo e alta rotação. Reposição imediata recomendada.',
        urgencyLevel: 'high',
        currentStock: food.currentStock,
        batchSize: food.batchSize,
      );
    }

    // REGRA 4: Movimento abaixo da previsão -> REDUZIR PRODUÇÃO
    if (isUnderCapacity) {
      final double reducedBatch = max(food.batchSize * 0.5, deficit);
      final double qty = roundToReasonableStep(reducedBatch, food.batchSize * 0.5);
      return FoodRecommendation(
        foodId: food.id,
        foodName: food.name,
        action: RecommendationAction.reduzir,
        recommendedQuantity: qty > 0 ? qty : 0.0,
        unit: food.unit,
        reason: 'Movimento abaixo do previsto. Reduzir produção para evitar sobras.',
        urgencyLevel: 'normal',
        currentStock: food.currentStock,
        batchSize: food.batchSize,
      );
    }

    // REGRA 5: Movimento normal / próximo da previsão -> PRODUÇÃO NORMAL
    final double standardQty = roundToReasonableStep(max(food.batchSize, deficit), food.batchSize);
    return FoodRecommendation(
      foodId: food.id,
      foodName: food.name,
      action: RecommendationAction.normal,
      recommendedQuantity: standardQty,
      unit: food.unit,
      reason: 'Ritmo de consumo estável e compatível com a previsão. Manter lote padrão.',
      urgencyLevel: 'normal',
      currentStock: food.currentStock,
      batchSize: food.batchSize,
    );
  }

  static double roundToReasonableStep(double value, double minStep) {
    if (value <= 0) return 0.0;
    if (value < 1.0) {
      return (value * 10).ceil() / 10.0;
    }
    return (value * 2).ceil() / 2.0;
  }

  static int calculateRemainingMinutes({
    required String closingTime,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final parts = closingTime.split(':');
    if (parts.length < 2) return 60;

    final closeHour = int.tryParse(parts[0]) ?? 14;
    final closeMinute = int.tryParse(parts[1]) ?? 30;

    final closeDateTime = DateTime(
      current.year,
      current.month,
      current.day,
      closeHour,
      closeMinute,
    );

    final difference = closeDateTime.difference(current).inMinutes;
    return max(0, difference);
  }

  static Map<String, double> calculateSavingsEstimates({
    required List<FoodModel> foods,
    required int totalAttended,
    required int totalExpected,
  }) {
    if (totalExpected <= 0 || foods.isEmpty) {
      return {'wasteAvoidedKg': 0.0, 'savingsReais': 0.0};
    }

    double totalWasteAvoidedKg = 0.0;
    double totalSavingsReais = 0.0;

    final int preventedOverproductionGuests = max(0, totalExpected - totalAttended);

    for (final food in foods) {
      final double foodPreventedKg = preventedOverproductionGuests * food.consumptionPerPerson * 0.85;
      final double savings = foodPreventedKg * food.costPerUnit;

      totalWasteAvoidedKg += foodPreventedKg;
      totalSavingsReais += savings;
    }

    return {
      'wasteAvoidedKg': double.parse(totalWasteAvoidedKg.toStringAsFixed(2)),
      'savingsReais': double.parse(totalSavingsReais.toStringAsFixed(2)),
    };
  }
}
