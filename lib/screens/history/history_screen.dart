import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/history_model.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterDays = 7; // 1 (Hoje), 7 (7 dias), 30 (30 dias)

  String _formatDate(DateTime date) {
    try {
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      final weekdayStr = DateFormat('EEEE', 'pt_BR').format(date);
      final capitalized = weekdayStr.isNotEmpty
          ? '${weekdayStr[0].toUpperCase()}${weekdayStr.substring(1)}'
          : weekdayStr;
      return '$dateStr ($capitalized)';
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _recordDayClosure(BuildContext context, BuffetProvider buffet) async {
    final now = DateTime.now();
    final currentGuests = buffet.establishment.currentGuests;
    final expectedGuests = buffet.establishment.expectedGuests;
    final totalProd = buffet.foods.fold<double>(0.0, (sum, f) => sum + f.currentStock);
    final wasteKg = buffet.totalWasteTodayKg;
    final estimates = buffet.savingsEstimates;
    final avoidedKg = estimates['wasteAvoidedKg'] ?? 4.2;
    final savings = estimates['savingsReais'] ?? 58.0;
    final totalCost = (totalProd > 0 ? totalProd : 26.0) * 11.5;

    final record = HistoryRecordModel(
      id: 'hist_${now.millisecondsSinceEpoch}',
      establishmentId: buffet.establishment.id,
      date: now,
      expectedGuests: expectedGuests > 0 ? expectedGuests : 45,
      attendedGuests: currentGuests > 0 ? currentGuests : 38,
      totalProductionKg: totalProd > 0 ? totalProd : 28.0,
      totalWasteKg: wasteKg > 0 ? wasteKg : 0.9,
      totalCost: totalCost,
      wasteAvoidedKg: avoidedKg,
      savingsReais: savings,
    );

    await buffet.addHistoryRecord(record);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fechamento de hoje adicionado ao histórico com sucesso!'),
          backgroundColor: VerTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final allHistory = buffet.history;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Ordenação do mais recente para o mais antigo
    final sortedList = allHistory.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final filteredList = sortedList.where((item) {
      final itemDay = DateTime(item.date.year, item.date.month, item.date.day);
      if (_selectedFilterDays == 1) {
        return itemDay.isAtSameMomentAs(today);
      } else {
        final cutoff = today.subtract(Duration(days: _selectedFilterDays - 1));
        return !itemDay.isBefore(cutoff);
      }
    }).toList();

    // Métricas do período selecionado
    final totalSavings = filteredList.fold<double>(0.0, (s, h) => s + h.savingsReais);
    final totalWasteAvoided = filteredList.fold<double>(0.0, (s, h) => s + h.wasteAvoidedKg);
    final totalWaste = filteredList.fold<double>(0.0, (s, h) => s + h.totalWasteKg);
    final totalAttended = filteredList.fold<int>(0, (s, h) => s + h.attendedGuests);

    return ResponsiveScaffold(
      currentIndex: 5,
      title: 'Histórico Operacional',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de filtros e ação de fechamento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Filtrar período: ',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip('Hoje', 1),
                          const SizedBox(width: 8),
                          _buildFilterChip('7 dias', 7),
                          const SizedBox(width: 8),
                          _buildFilterChip('30 dias', 30),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _recordDayClosure(context, buffet),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Registrar Fechamento Hoje'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VerTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cards de resumo do período selecionado
                if (filteredList.isNotEmpty) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.8 : 1.6,
                        children: [
                          _buildSummaryCard(
                            title: 'Economia Total',
                            value: 'R\$ ${totalSavings.toStringAsFixed(2)}',
                            icon: Icons.savings_outlined,
                            color: VerTheme.primaryGreen,
                          ),
                          _buildSummaryCard(
                            title: 'Desp. Evitado',
                            value: '${totalWasteAvoided.toStringAsFixed(1)} kg',
                            icon: Icons.eco_outlined,
                            color: Colors.teal,
                          ),
                          _buildSummaryCard(
                            title: 'Descarte Total',
                            value: '${totalWaste.toStringAsFixed(1)} kg',
                            icon: Icons.delete_outline,
                            color: Colors.orange.shade800,
                          ),
                          _buildSummaryCard(
                            title: 'Total Atendidos',
                            value: '$totalAttended pessoas',
                            icon: Icons.people_outline,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Lista de Histórico
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: filteredList.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_toggle_off, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 14),
                              const Text(
                                'Nenhum registro no período selecionado.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Use o botão acima para registrar o fechamento do dia atual.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final record = filteredList[index];

                            return Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16, color: VerTheme.primaryGreen),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(record.date),
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Text(
                                          'Economia: R\$ ${record.savingsReais.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 8,
                                    children: [
                                      _buildStatItem('Previstos', '${record.expectedGuests}'),
                                      _buildStatItem('Atendidos', '${record.attendedGuests}'),
                                      _buildStatItem('Produção', '${record.totalProductionKg.toStringAsFixed(1)} kg'),
                                      _buildStatItem('Desperdício', '${record.totalWasteKg.toStringAsFixed(1)} kg', isAlert: record.totalWasteKg > 2.0),
                                      _buildStatItem('Desp. Evitado', '${record.wasteAvoidedKg.toStringAsFixed(1)} kg', isPositive: true),
                                      _buildStatItem('Custo Total', 'R\$ ${record.totalCost.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: VerTheme.textMuted, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int days) {
    final isSelected = _selectedFilterDays == days;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: VerTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : VerTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilterDays = days);
      },
    );
  }

  static Widget _buildStatItem(String label, String value, {bool isAlert = false, bool isPositive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: VerTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isAlert
                ? Colors.red.shade700
                : isPositive
                    ? VerTheme.primaryGreen
                    : VerTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

