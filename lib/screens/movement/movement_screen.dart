import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/establishment_model.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';
import '../../widgets/charts/movement_chart.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key});

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final _customInputController = TextEditingController();

  @override
  void dispose() {
    _customInputController.dispose();
    super.dispose();
  }

  void _showCustomInputDialog(BuildContext context) {
    final buffet = context.read<BuffetProvider>();
    _customInputController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Quantidade Específica'),
        content: TextField(
          controller: _customInputController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade de pessoas',
            hintText: 'Ex: 25',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_customInputController.text);
              if (val != null && val != 0) {
                buffet.recordMovement(val, note: 'Entrada avulsa');
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();
    final est = buffet.establishment;
    final isEscola = est.type == EstablishmentType.escola;
    final movements = buffet.movements;

    return ResponsiveScaffold(
      currentIndex: 1,
      title: isEscola ? 'Movimento — Alunos' : 'Movimento — Clientes',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. CARD PRINCIPAL DE CONTAGEM E BOTÕES RÁPIDOS
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isEscola
                            ? 'Total de Alunos Presentes Hoje'
                            : 'Total de Clientes no Buffet Hoje',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${est.currentGuests}',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: VerTheme.primaryGreen,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Meta diária prevista: ${est.expectedGuests} pessoas',
                        style: const TextStyle(
                          fontSize: 13,
                          color: VerTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botões +1, +5, +10, -1
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildActionButton(
                            context,
                            '+1',
                            () => buffet.recordMovement(1),
                            color: VerTheme.primaryGreen,
                          ),
                          _buildActionButton(
                            context,
                            '+5',
                            () => buffet.recordMovement(5),
                            color: VerTheme.primaryGreen,
                          ),
                          _buildActionButton(
                            context,
                            '+10',
                            () => buffet.recordMovement(10),
                            color: VerTheme.primaryGreen,
                          ),
                          _buildActionButton(
                            context,
                            '-1',
                            () => buffet.recordMovement(-1),
                            color: Colors.red.shade600,
                            isOutlined: true,
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showCustomInputDialog(context),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Digitar valor'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. GRÁFICO DE EVOLUÇÃO EM TEMPO REAL
                MovementChart(
                  movements: movements,
                  expectedGuests: est.expectedGuests,
                ),
                const SizedBox(height: 24),

                // 3. TABELA / HISTÓRICO DE ENTRADAS
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Histórico de Entradas Registradas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: VerTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${movements.length} lançamentos',
                            style: const TextStyle(
                              fontSize: 12,
                              color: VerTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (movements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Nenhuma entrada registrada nesta sessão.',
                              style: TextStyle(color: VerTheme.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: movements.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = movements[movements.length - 1 - index];
                            final isPositive = m.delta > 0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isPositive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                child: Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 18,
                                  color: isPositive
                                      ? VerTheme.primaryGreen
                                      : Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                '${isPositive ? "+" : ""}${m.delta} ${isEscola ? "alunos" : "clientes"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('HH:mm:ss').format(m.timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: VerTheme.textMuted,
                                ),
                              ),
                              trailing: Text(
                                'Total: ${m.totalCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: VerTheme.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    required Color color,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}
