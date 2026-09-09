import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';
import '../../widgets/cards/metric_card.dart';
import '../../widgets/common/status_badge.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final isDemoActive = buffet.isDemoMode;
    final currentStep = buffet.demoStep;
    final scenario = buffet.currentDemoScenario;
    final recs = buffet.recommendations;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return ResponsiveScaffold(
      currentIndex: 7,
      title: 'Modo Apresentação / Hackathon',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BANNER DO MODO DEMO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDemoActive ? Colors.amber.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDemoActive
                          ? Colors.amber.shade700
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDemoActive
                              ? Colors.amber.shade700
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.slideshow,
                          color: isDemoActive
                              ? Colors.white
                              : Colors.grey.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDemoActive
                                  ? 'Modo Demonstração Ativado'
                                  : 'Modo Demonstração Desativado',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDemoActive
                                  ? 'Apresentando cenários controlados em tempo real para a banca avaliadora.'
                                  : 'Ative para navegar pelos 4 cenários oficiais do pitch sem alterar os dados reais.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => buffet.toggleDemoMode(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDemoActive
                              ? Colors.amber.shade900
                              : VerTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          isDemoActive ? 'Desativar Demo' : 'Iniciar Demo',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isDemoActive) ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.touch_app,
                          size: 48,
                          color: VerTheme.primaryGreen,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Preparado para o Pitch da Equipe V.E.R.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Clique em "Iniciar Demo" acima para simular a mudança de fluxo de pessoas e verificar como o motor ajusta automaticamente as recomendações de produção para a cozinha.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: VerTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // BARRA DE PROGRESSO DOS 4 CENÁRIOS
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          'Selecione o cenário da apresentação:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildStepTab(
                              0,
                              '1. Normal',
                              currentStep == 0,
                              () => buffet.setDemoStep(0),
                            ),
                            const SizedBox(width: 8),
                            _buildStepTab(
                              1,
                              '2. Reduzir',
                              currentStep == 1,
                              () => buffet.setDemoStep(1),
                            ),
                            const SizedBox(width: 8),
                            _buildStepTab(
                              2,
                              '3. Não Iniciar',
                              currentStep == 2,
                              () => buffet.setDemoStep(2),
                            ),
                            const SizedBox(width: 8),
                            _buildStepTab(
                              3,
                              '4. Aumentar',
                              currentStep == 3,
                              () => buffet.setDemoStep(3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DETALHES DO CENÁRIO SELECIONADO
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: VerTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              scenario['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: VerTheme.primaryGreen,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => buffet.nextDemoStep(),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Próximo Cenário'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VerTheme.primaryGreen,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scenario['description'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: VerTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: isDesktop ? 3 : 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: isDesktop ? 2.5 : 3.0,
                          children: [
                            MetricCard(
                              title: 'Previsão Estabelecida',
                              value: '${scenario["expected"]}',
                              icon: Icons.flag,
                            ),
                            MetricCard(
                              title: 'Movimento Registrado',
                              value: '${scenario["movement"]}',
                              icon: Icons.people,
                              accentColor: VerTheme.primaryGreen,
                            ),
                            MetricCard(
                              title: 'Tempo Restante',
                              value: '${scenario["remainingMin"]} min',
                              icon: Icons.timer,
                              accentColor: Colors.orange.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // RESULTADOS DAS RECOMENDAÇÕES PARA A COZINHA NESTE CENÁRIO
                  const Text(
                    'Recomendações Emitidas para a Cozinha:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final rec = recs[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec.foodName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rec.reason,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: VerTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            StatusBadge(action: rec.action),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTab(
    int stepIndex,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? VerTheme.primaryGreen : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
