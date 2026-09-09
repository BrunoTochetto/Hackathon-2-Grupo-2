import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';
import '../../widgets/cards/metric_card.dart';
import '../../widgets/charts/waste_chart.dart';

class WasteScreen extends StatelessWidget {
  const WasteScreen({super.key});

  void _showRecordWasteDialog(BuildContext context) {
    final buffet = context.read<BuffetProvider>();
    if (buffet.foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre alimentos antes de registrar desperdício.'),
        ),
      );
      return;
    }

    String selectedFoodId = buffet.foods.first.id;
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(
      text: 'Sobra de rampa no fechamento',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Desperdício / Descarte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedFoodId,
                items: buffet.foods
                    .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(
                  () => selectedFoodId = val ?? selectedFoodId,
                ),
                decoration: const InputDecoration(
                  labelText: 'Alimento descartado',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantidade Descartada (kg)',
                  hintText: 'Ex: 0.8',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo do descarte',
                  hintText: 'Ex: Sobra de balcão, alimento vencido',
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
                final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
                if (qty != null && qty > 0) {
                  buffet.recordWaste(
                    selectedFoodId,
                    qty,
                    reasonCtrl.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registro de $qty kg salvo com sucesso.'),
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Salvar Registro'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final history = buffet.history;
    final wasteRecords = buffet.wasteRecords;
    final estimates = buffet.savingsEstimates;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    // Desperdício Hoje, Semana, Mês
    final wasteTodayKg = buffet.totalWasteTodayKg;
    final wasteWeekKg =
        history.take(7).fold<double>(0.0, (s, h) => s + h.totalWasteKg) +
        wasteTodayKg;
    final wasteMonthKg = wasteWeekKg * 3.8; // Projeção mensal realista

    // Desperdício evitado acumulado
    final avoidedWeekKg =
        history.take(7).fold<double>(0.0, (s, h) => s + h.wasteAvoidedKg) +
        (estimates['wasteAvoidedKg'] ?? 0.0);

    return ResponsiveScaffold(
      currentIndex: 6,
      title: 'Desperdício & Impacto',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordWasteDialog(context),
        icon: const Icon(Icons.delete_sweep),
        label: const Text('Registrar Descarte'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. CARDS DE DESPERDÍCIO (Hoje, Semana, Mês)
                GridView.count(
                  crossAxisCount: isDesktop ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: isDesktop ? 2.3 : 2.8,
                  children: [
                    MetricCard(
                      title: 'Desperdício hoje',
                      value: '${wasteTodayKg.toStringAsFixed(1)} kg',
                      subtitle: 'Descartes lançados hoje',
                      icon: Icons.delete_outline,
                      accentColor: Colors.orange.shade800,
                    ),
                    MetricCard(
                      title: 'Desperdício esta semana',
                      value: '${wasteWeekKg.toStringAsFixed(1)} kg',
                      subtitle: 'Últimos 7 dias de operação',
                      icon: Icons.date_range,
                      accentColor: Colors.red.shade700,
                    ),
                    MetricCard(
                      title: 'Desperdício este mês',
                      value: '${wasteMonthKg.toStringAsFixed(1)} kg',
                      subtitle: 'Acumulado / Projetado',
                      icon: Icons.analytics_outlined,
                      accentColor: Colors.purple.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. CARD DESTACADO: DESPERDÍCIO EVITADO & ECONOMIA ESTIMADA
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VerTheme.primaryGreen, VerTheme.darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: VerTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            color: Colors.amberAccent,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Resultados Estratégicos — SmartBuffet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cálculos baseados no déficit de demanda prevenido em relação à projeção de consumo.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Desperdício evitado na semana',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${avoidedWeekKg.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Eficiência de Planejamento',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '95.2%',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. GRÁFICO COMPARATIVO REALISTA
                WasteChart(historyRecords: history),
                const SizedBox(height: 24),

                // 4. ÚLTIMOS DESCARTE REGISTRADOS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Últimos Descartes Registrados',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (wasteRecords.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Nenhum descarte registrado hoje. Parabéns pelo controle!',
                              style: TextStyle(color: VerTheme.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wasteRecords.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final w = wasteRecords[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEBEE),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${w.foodName} — ${w.wasteKg.toStringAsFixed(2)} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Motivo: ${w.reason} • Custo: R\$ ${w.costReais.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: VerTheme.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
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
