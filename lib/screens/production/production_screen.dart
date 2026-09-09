import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/food_model.dart';
import '../../models/recommendation_model.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';
import '../../widgets/common/status_badge.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  void _showRecordProductionDialog(
    BuildContext context,
    FoodModel food,
    double recommendedQty,
  ) {
    final buffet = context.read<BuffetProvider>();
    final controller = TextEditingController(
      text: recommendedQty > 0
          ? recommendedQty.toStringAsFixed(1)
          : food.batchSize.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar Produção — ${food.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estoque disponível atual: ${food.currentStock.toStringAsFixed(1)} ${food.unit}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Quantidade Produzida (${food.unit})',
                hintText: 'Ex: ${food.batchSize}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val > 0) {
                buffet.recordProduction(food.id, val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Lote de $val ${food.unit} de ${food.name} adicionado ao estoque!',
                    ),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar Fornada'),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, FoodModel food) {
    final buffet = context.read<BuffetProvider>();
    final controller = TextEditingController(
      text: food.currentStock.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajustar Estoque — ${food.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Novo Estoque Atual (${food.unit})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val >= 0) {
                buffet.updateStock(food.id, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final recs = buffet.recommendations;

    return ResponsiveScaffold(
      currentIndex: 2,
      title: 'Controle de Produção',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/menu'),
        icon: const Icon(Icons.add),
        label: const Text('Gerenciar Alimentos'),
        backgroundColor: VerTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header descritivo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.restaurant,
                          color: VerTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Painel de Controle de Fornadas e Lotes',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Acompanhe a quantidade disponível, a sugestão de próximo lote e registre novas produções.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Lista / Cards de Produção
                if (recs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Nenhum alimento cadastrado no sistema.'),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rec = recs[index];
                      final food = buffet.foods.firstWhere(
                        (f) => f.id == rec.foodId,
                        orElse: () => FoodModel(
                          id: rec.foodId,
                          name: rec.foodName,
                          category: 'Geral',
                          currentStock: rec.currentStock,
                          batchSize: rec.batchSize,
                          costPerUnit: 10,
                          consumptionPerPerson: 0.08,
                          updatedAt: DateTime.now(),
                        ),
                      );

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rec.foodName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: VerTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Categoria: ${food.category} • Lote padrão: ${food.batchSize} ${food.unit}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: VerTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(action: rec.action),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDataBlock(
                                  'Quantidade disponível',
                                  '${food.currentStock.toStringAsFixed(1)} ${food.unit}',
                                  onEdit: () =>
                                      _showAdjustStockDialog(context, food),
                                ),
                                _buildDataBlock(
                                  'Próximo lote sugerido',
                                  rec.action == RecommendationAction.naoIniciar
                                      ? '0 ${food.unit}'
                                      : '${rec.recommendedQuantity.toStringAsFixed(1)} ${food.unit}',
                                  highlight: rec.recommendedQuantity > 0,
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showRecordProductionDialog(
                                    context,
                                    food,
                                    rec.recommendedQuantity,
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Produzir Lote'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (rec.reason.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: VerTheme.softBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Orientação do motor: ${rec.reason}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDataBlock(
    String label,
    String value, {
    VoidCallback? onEdit,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: VerTheme.textMuted),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: highlight ? VerTheme.primaryGreen : VerTheme.textPrimary,
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit,
                  size: 14,
                  color: VerTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
