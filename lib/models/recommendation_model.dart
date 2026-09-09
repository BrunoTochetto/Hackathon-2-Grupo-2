enum RecommendationAction {
  normal('Produção normal'),
  reduzir('Reduzir produção'),
  aumentar('Aumentar produção'),
  naoIniciar('Não iniciar novo lote'),
  minima('Produção mínima');

  final String label;
  const RecommendationAction(this.label);
}

class FoodRecommendation {
  final String foodId;
  final String foodName;
  final RecommendationAction action;
  final double recommendedQuantity; // ex: 1.0 (kg) ou 0.0
  final String unit;
  final String reason;
  final String urgencyLevel; // 'low', 'normal', 'high'
  final double currentStock;
  final double batchSize;

  const FoodRecommendation({
    required this.foodId,
    required this.foodName,
    required this.action,
    required this.recommendedQuantity,
    this.unit = 'kg',
    required this.reason,
    this.urgencyLevel = 'normal',
    required this.currentStock,
    required this.batchSize,
  });

  String get formattedAdvice {
    if (action == RecommendationAction.naoIniciar) {
      return 'Não produzir';
    }
    if (recommendedQuantity <= 0) {
      return action.label;
    }
    if (unit == 'kg' && recommendedQuantity < 1.0) {
      return '${action.label} (${(recommendedQuantity * 1000).toStringAsFixed(0)} g)';
    }
    return '${action.label} (${recommendedQuantity.toStringAsFixed(1)} $unit)';
  }

  String get shortKitchenSummary {
    if (action == RecommendationAction.naoIniciar) {
      return 'Não produzir';
    }
    if (unit == 'kg' && recommendedQuantity < 1.0 && recommendedQuantity > 0) {
      return 'Produzir ${(recommendedQuantity * 1000).toStringAsFixed(0)} g';
    } else if (recommendedQuantity > 0) {
      return 'Produzir ${recommendedQuantity.toStringAsFixed(1)} $unit';
    }
    return action.label;
  }
}

class OverallSituation {
  final String title;
  final String description;
  final String statusLevel; // 'success', 'warning', 'info', 'alert'

  const OverallSituation({
    required this.title,
    required this.description,
    required this.statusLevel,
  });
}
