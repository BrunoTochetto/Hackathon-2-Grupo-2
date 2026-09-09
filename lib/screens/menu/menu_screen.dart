import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/food_model.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _showFoodFormDialog(BuildContext context, {FoodModel? existingFood}) {
    final buffet = context.read<BuffetProvider>();
    final isEditing = existingFood != null;

    final nameCtrl = TextEditingController(text: existingFood?.name ?? '');
    final categoryCtrl = TextEditingController(
      text: existingFood?.category ?? 'Prato Principal',
    );
    final stockCtrl = TextEditingController(
      text: existingFood?.currentStock.toString() ?? '2.0',
    );
    final batchCtrl = TextEditingController(
      text: existingFood?.batchSize.toString() ?? '2.0',
    );
    final costCtrl = TextEditingController(
      text: existingFood?.costPerUnit.toString() ?? '15.0',
    );
    final consumptionCtrl = TextEditingController(
      text: existingFood != null
          ? (existingFood.consumptionPerPerson * 1000).toStringAsFixed(0)
          : '80',
    );
    String unit = existingFood?.unit ?? 'kg';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'Editar Alimento' : 'Novo Alimento no Cardápio',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Alimento (ex: Arroz Integral)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Categoria (ex: Grãos, Carnes, Saladas)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Estoque Atual',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'un', child: Text('un')),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => unit = val ?? 'kg'),
                        decoration: const InputDecoration(labelText: 'Un.'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tamanho do Lote Padrão ($unit)',
                    hintText: 'Ex: 2.0 para fornadas de 2kg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Custo por Unidade / kg (R\$)',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: consumptionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Consumo Médio por Pessoa (gramas)',
                    hintText: 'Ex: 80 para 80g por pessoa',
                    suffixText: 'g',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final stock =
                    double.tryParse(stockCtrl.text.replaceAll(',', '.')) ?? 0.0;
                final batch =
                    double.tryParse(batchCtrl.text.replaceAll(',', '.')) ?? 1.0;
                final cost =
                    double.tryParse(costCtrl.text.replaceAll(',', '.')) ?? 0.0;
                final consumptionGrams =
                    double.tryParse(
                      consumptionCtrl.text.replaceAll(',', '.'),
                    ) ??
                    80.0;

                final food = FoodModel(
                  id:
                      existingFood?.id ??
                      'food_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  category: categoryCtrl.text.trim().isEmpty
                      ? 'Geral'
                      : categoryCtrl.text.trim(),
                  currentStock: stock,
                  unit: unit,
                  batchSize: batch,
                  costPerUnit: cost,
                  consumptionPerPerson:
                      consumptionGrams / 1000.0, // converte g para kg
                  updatedAt: DateTime.now(),
                );

                if (isEditing) {
                  buffet.updateFood(food);
                } else {
                  buffet.addFood(food);
                }
                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Atualizar' : 'Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FoodModel food) {
    final buffet = context.read<BuffetProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Alimento'),
        content: Text('Deseja realmente remover "${food.name}" do cardápio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              buffet.deleteFood(food.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final foods = buffet.foods;

    return ResponsiveScaffold(
      currentIndex: 3,
      title: 'Cardápio & Alimentos',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFoodFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Alimento'),
        backgroundColor: VerTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          Icons.menu_book,
                          color: VerTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestão de Itens e Fichas Técnicas',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Os dados de lote, custo e consumo médio por pessoa alimentam o algoritmo preditivo de produção.',
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

                if (foods.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: Text('Nenhum alimento cadastrado.')),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: foods.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      final consumptionGrams =
                          (food.consumptionPerPerson * 1000).toStringAsFixed(0);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: VerTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.fastfood,
                                color: VerTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        food.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          food.category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: VerTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Estoque: ${food.currentStock} ${food.unit} • Lote: ${food.batchSize} ${food.unit} • Custo: R\$ ${food.costPerUnit.toStringAsFixed(2)}/${food.unit} • Média: ${consumptionGrams}g/pessoa',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: VerTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: VerTheme.textSecondary,
                              ),
                              onPressed: () => _showFoodFormDialog(
                                context,
                                existingFood: food,
                              ),
                              tooltip: 'Editar alimento',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDelete(context, food),
                              tooltip: 'Excluir alimento',
                            ),
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
}
