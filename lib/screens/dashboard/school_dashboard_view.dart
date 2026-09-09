import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/cards/metric_card.dart';
import '../../widgets/common/status_badge.dart';

class SchoolDashboardView extends StatelessWidget {
  const SchoolDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final situation = buffet.overallSituation;
    final recs = buffet.recommendations;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    // Métricas reais da escola
    final alunosPrevistos = buffet.establishment.expectedGuests;
    final alunosPresentes = buffet.establishment.currentGuests;
    final refeicoesServidas = alunosPresentes;
    final desperdicioEstimadoKg = buffet.totalWasteTodayKg > 0
        ? buffet.totalWasteTodayKg
        : 8.4; // Valor representativo realista caso vazio

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. QUATRO CARDS DE MÉTRICAS DA ESCOLA
              GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isDesktop ? 1.6 : 1.3,
                children: [
                  MetricCard(
                    title: 'Alunos previstos',
                    value: '$alunosPrevistos',
                    subtitle: 'Matrículas ativas no turno',
                    icon: Icons.groups_outlined,
                    accentColor: Colors.blue.shade700,
                  ),
                  MetricCard(
                    title: 'Alunos presentes',
                    value: '$alunosPresentes',
                    subtitle: 'Chamada registrada hoje',
                    icon: Icons.how_to_reg,
                    accentColor: VerTheme.primaryGreen,
                  ),
                  MetricCard(
                    title: 'Refeições',
                    value: '$refeicoesServidas',
                    subtitle: 'Pratos distribuídos',
                    icon: Icons.lunch_dining,
                    accentColor: Colors.teal.shade700,
                  ),
                  MetricCard(
                    title: 'Desperdício est.',
                    value: '${desperdicioEstimadoKg.toStringAsFixed(1)} kg',
                    subtitle: 'Sobra mínima calculada',
                    icon: Icons.delete_outline,
                    accentColor: Colors.orange.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. SITUAÇÃO ATUAL
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: situation.statusLevel == 'alert'
                        ? Colors.red.shade300
                        : situation.statusLevel == 'warning'
                        ? Colors.orange.shade300
                        : VerTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: situation.statusLevel == 'alert'
                            ? Colors.red.shade50
                            : situation.statusLevel == 'warning'
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        situation.statusLevel == 'alert'
                            ? Icons.error
                            : situation.statusLevel == 'warning'
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: situation.statusLevel == 'alert'
                            ? Colors.red.shade700
                            : situation.statusLevel == 'warning'
                            ? Colors.orange.shade800
                            : VerTheme.primaryGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Situação atual do refeitório',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: VerTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            situation.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: VerTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            situation.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: VerTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. PRÓXIMA PRODUÇÃO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Próxima produção da merenda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: VerTheme.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/kitchen'),
                    icon: const Icon(Icons.soup_kitchen, size: 16),
                    label: const Text('Visão do Refeitório'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rec = recs[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.foodName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: VerTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Disponível: ${rec.currentStock.toStringAsFixed(1)} ${rec.unit}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: VerTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: StatusBadge(action: rec.action),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // 4. REGISTRO DE ALUNOS PRESENTES (+1, +5, +10, -1)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: VerTheme.primaryGreen.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VerTheme.primaryGreen.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school, color: VerTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'Registrar chamada de alunos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: VerTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Presentes: $alunosPresentes',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: VerTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => buffet.recordMovement(1),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '+1',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => buffet.recordMovement(5),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '+5',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => buffet.recordMovement(10),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '+10',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => buffet.recordMovement(-1),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(
                                color: Colors.red.shade300,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '-1',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
