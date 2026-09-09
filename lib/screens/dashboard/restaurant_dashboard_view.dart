import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/recommendation_model.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/cards/metric_card.dart';
import '../../widgets/common/status_badge.dart';

class RestaurantDashboardView extends StatelessWidget {
  const RestaurantDashboardView({super.key});

  static const List<Map<String, String>> _diasSemanaInfo = [
    {'codigo': 'seg', 'sigla': 'SEG', 'nome': 'Segunda'},
    {'codigo': 'ter', 'sigla': 'TER', 'nome': 'Terça'},
    {'codigo': 'qua', 'sigla': 'QUA', 'nome': 'Quarta'},
    {'codigo': 'qui', 'sigla': 'QUI', 'nome': 'Quinta'},
    {'codigo': 'sex', 'sigla': 'SEX', 'nome': 'Sexta'},
    {'codigo': 'sab', 'sigla': 'SÁB', 'nome': 'Sábado'},
    {'codigo': 'dom', 'sigla': 'DOM', 'nome': 'Domingo'},
  ];

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final recs = buffet.recommendations;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    final remainingMin = buffet.remainingMinutes;
    final clients15 = buffet.clientsLast15Minutes;
    final alertLevel = buffet.productionAlertLevel;
    final alertInstruction = buffet.productionAlertInstruction;
    final panType = buffet.suggestedPanType;
    final periodDesc = buffet.currentPeriodDescription;
    final isPeak = buffet.isPeakHour;
    final demands = buffet.foodDemandForCurrentFlow;
    final closingPhase = buffet.closingPhaseExplanation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =======================================================
              // 1. CARDS DE MÉTRICAS PRINCIPAIS (ZERO OVERFLOW GARANTIDO)
              // =======================================================
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 115,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return MetricCard(
                      title: 'Clientes no Buffet Hoje',
                      value: '${buffet.establishment.currentGuests}',
                      subtitle: 'Fluxo acumulado no dia',
                      icon: Icons.people_alt,
                      accentColor: VerTheme.primaryGreen,
                    );
                  } else if (index == 1) {
                    return MetricCard(
                      title: 'Fluxo Últimos 15 Minutos',
                      value: '$clients15 clientes',
                      subtitle: 'Base do cálculo de insumos',
                      icon: Icons.speed,
                      accentColor: Colors.deepOrange,
                    );
                  } else {
                    return MetricCard(
                      title: 'Tempo até o Fechamento',
                      value: '$remainingMin min',
                      subtitle: 'Fechamento às ${buffet.establishment.closingTime}',
                      icon: Icons.timer,
                      accentColor: remainingMin <= 30
                          ? Colors.red.shade700
                          : remainingMin <= 60
                              ? Colors.amber.shade800
                              : Colors.teal,
                    );
                  }
                },
              ),
              const SizedBox(height: 18),

              // =======================================================
              // 2. DIRETRIZ EM TEMPO REAL DA COZINHA (STATUS OPERACIONAL)
              // =======================================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: alertLevel == 'VERMELHO'
                      ? Colors.red.shade50
                      : alertLevel == 'AMARELO'
                          ? Colors.amber.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: alertLevel == 'VERMELHO'
                        ? Colors.red.shade400
                        : alertLevel == 'AMARELO'
                            ? Colors.amber.shade400
                            : Colors.green.shade400,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: alertLevel == 'VERMELHO'
                            ? Colors.red.shade700
                            : alertLevel == 'AMARELO'
                                ? Colors.amber.shade800
                                : VerTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        alertLevel == 'VERMELHO'
                            ? Icons.warning_amber_rounded
                            : alertLevel == 'AMARELO'
                                ? Icons.change_circle_outlined
                                : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'STATUS DA COZINHA: $alertLevel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: alertLevel == 'VERMELHO'
                                      ? Colors.red.shade900
                                      : alertLevel == 'AMARELO'
                                          ? Colors.amber.shade900
                                          : VerTheme.darkGreen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  panType,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alertInstruction,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: VerTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Abrir Display Cozinha em Tela Cheia',
                      onPressed: () => Navigator.pushNamed(context, '/cozinha'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // =======================================================
              // 3. ANÁLISE DE HORÁRIOS: PICO, BAIXA E FASE DE FECHAMENTO
              // =======================================================
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPeak ? Icons.trending_up : Icons.schedule,
                                color: isPeak ? Colors.amber.shade800 : Colors.teal.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Previsão de Horário & Ritmo de Produção',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPeak ? Colors.amber.shade100 : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPeak ? 'HORÁRIO DE PICO' : 'HORÁRIO REGULAR/BAIXA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isPeak ? Colors.amber.shade900 : Colors.teal.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        periodDesc,
                        style: const TextStyle(fontSize: 13, color: VerTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Explicação das fases de fechamento
                      const Text(
                        'Fase Atual de Encerramento do Restaurante:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          closingPhase != null
                              ? '${closingPhase['fase']}: ${closingPhase['detalhe']}'
                              : (remainingMin <= 30
                                  ? 'Fase de Encerramento (<= 30 min): Produção apenas sob demanda com cubas rasas para não sobrar comida.'
                                  : remainingMin <= 60
                                      ? 'Fase de Desaceleração (30 a 60 min): Passar para lotes médios (2kg) e diminuir reposição.'
                                      : 'Fase de Operação Regular (> 60 min): Produção contínua e cubas fundas abastecidas.'),
                          style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // =======================================================
              // 4. DIAS DA SEMANA & CONTROLE DE FERIADOS MANUAIS
              // =======================================================
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_month, color: VerTheme.primaryGreen, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Dias de Funcionamento & Feriados Manuais',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          Text(
                            'Clique no dia para ativar/cancelar folga manual',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _diasSemanaInfo.map((dia) {
                          final codigo = dia['codigo']!;
                          final sigla = dia['sigla']!;
                          final isAberto = buffet.openDays.contains(codigo);
                          final isFeriadoManual = buffet.manualHolidays.contains(codigo);

                          final Color bg;
                          final Color border;
                          final Color textColor;
                          final String statusTexto;

                          if (isFeriadoManual) {
                            bg = Colors.red.shade100;
                            border = Colors.red.shade400;
                            textColor = Colors.red.shade900;
                            statusTexto = 'Feriado';
                          } else if (isAberto) {
                            bg = Colors.green.shade50;
                            border = Colors.green.shade400;
                            textColor = Colors.green.shade900;
                            statusTexto = 'Aberto';
                          } else {
                            bg = Colors.grey.shade200;
                            border = Colors.grey.shade400;
                            textColor = Colors.grey.shade700;
                            statusTexto = 'Folga';
                          }

                          return InkWell(
                            onTap: () => buffet.toggleManualHoliday(codigo),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border, width: 1.2),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    sigla,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    statusTexto,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: textColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // =======================================================
              // 5. REGISTRO ÁGIL DE FLUXO DE CLIENTES (ENTRADA / SAÍDA)
              // =======================================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: VerTheme.primaryGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
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
                            Icon(Icons.touch_app, color: VerTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'Registro Rápido de Fluxo (Recepção)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Text(
                          'Ajusta o cálculo de insumos na cozinha em tempo real',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => buffet.recordMovement(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VerTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('+1 Cliente', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => buffet.recordMovement(5),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VerTheme.darkGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('+5 Clientes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => buffet.recordMovement(10),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('+10 Clientes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => buffet.recordMovement(-1),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('-1 Cliente', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // =======================================================
              // 6. LINHA DE SERVIMENTO & PROJEÇÃO DE INSUMOS
              // =======================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cardápio & Projeção de Insumos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: VerTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/menu'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Cadastrar Alimento'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/cozinha'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.soup_kitchen, size: 16),
                        label: const Text('Display da Cozinha'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (recs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Nenhum alimento cadastrado no cardápio.'),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rec = recs[index];
                    final demandKg = demands[rec.foodId] ?? (clients15 * 0.08);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'Estoque atual: ${rec.currentStock.toStringAsFixed(1)} ${rec.unit} | Demanda estimada: ${demandKg.toStringAsFixed(1)} ${rec.unit}',
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    rec.shortKitchenSummary,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: rec.action == RecommendationAction.naoIniciar
                                          ? Colors.grey.shade600
                                          : VerTheme.darkGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusBadge(action: rec.action),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
