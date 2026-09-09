import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common/app_header.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return Scaffold(
      backgroundColor: VerTheme.softBackground,
      appBar: AppHeader(
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Entrar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: VerTheme.primaryGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Criar Conta',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: isDesktop ? 60 : 36,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    VerTheme.primaryGreen.withValues(alpha: 0.08),
                    VerTheme.softBackground,
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: VerTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: VerTheme.primaryGreen,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Equipe V.E.R. — Visão Estratégica de Recursos',
                              style: TextStyle(
                                color: VerTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SmartBuffet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 48 : 34,
                          fontWeight: FontWeight.w900,
                          color: VerTheme.darkGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"Produza o necessário. Desperdice menos."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 22 : 18,
                          fontWeight: FontWeight.w600,
                          color: VerTheme.primaryGreen,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'A ferramenta inteligente para restaurantes e escolas ajustarem a produção de alimentos em tempo real, acompanhando o movimento real de pessoas para combater o desperdício e economizar recursos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: VerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/gerente'),
                            icon: const Icon(Icons.touch_app, size: 18),
                            label: const Text(
                              'Painel Gerente (POST /api/fluxo)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VerTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/cozinha'),
                            icon: const Icon(Icons.soup_kitchen, size: 18),
                            label: const Text('Display Cozinha (Socket.io)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            icon: const Icon(Icons.dashboard, size: 18),
                            label: const Text('Visão Geral Completa'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SEÇÃO: O PROBLEMA
            _buildSection(
              isDesktop: isDesktop,
              backgroundColor: Colors.white,
              tag: 'O DESAFIO',
              tagColor: Colors.red.shade700,
              title: 'O Problema da Superprodução',
              content: Column(
                children: [
                  const Text(
                    'Restaurantes e escolas precisam produzir alimentos antes de saber exatamente quantas pessoas irão consumir.\n\n'
                    'Quando produzem mais do que o necessário, parte da comida acaba sendo descartada. '
                    'O movimento pode mudar drasticamente durante o dia por motivos climáticos, horários de pico ou imprevistos.\n\n'
                    'O SmartBuffet acompanha o movimento real e utiliza esses dados dinâmicos para ajustar as recomendações de produção de forma preditiva.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: VerTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildMiniBadge(
                        Icons.warning_amber,
                        'Produção cega sem dados',
                        Colors.orange,
                      ),
                      _buildMiniBadge(
                        Icons.delete_outline,
                        'Desperdício no descarte',
                        Colors.red,
                      ),
                      _buildMiniBadge(
                        Icons.money_off,
                        'Prejuízo financeiro',
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SEÇÃO: A SOLUÇÃO
            _buildSection(
              isDesktop: isDesktop,
              backgroundColor: VerTheme.softBackground,
              tag: 'INOVAÇÃO V.E.R.',
              tagColor: VerTheme.primaryGreen,
              title: 'A Solução SmartBuffet',
              content: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 3 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.3 : 2.4,
                children: const [
                  _FeatureCard(
                    icon: Icons.sync,
                    title: 'Sincronia com o Fluxo',
                    description:
                        'Compara em tempo real o fluxo de clientes/alunos com a projeção estipulada.',
                  ),
                  _FeatureCard(
                    icon: Icons.psychology_alt,
                    title: 'Motor de Decisão',
                    description:
                        'Algoritmo determinístico que calcula porções e lotes exatos por gramatura.',
                  ),
                  _FeatureCard(
                    icon: Icons.soup_kitchen,
                    title: 'Visão da Cozinha',
                    description:
                        'Painel direto em tablets para os cozinheiros saberem o que preparar agora.',
                  ),
                ],
              ),
            ),

            // SEÇÃO: COMO FUNCIONA (01 A 04)
            _buildSection(
              isDesktop: isDesktop,
              backgroundColor: Colors.white,
              tag: 'METODOLOGIA',
              tagColor: Colors.blue.shade700,
              title: 'Como Funciona na Prática',
              content: Column(
                children: [
                  _buildStepCard(
                    step: '01',
                    title: 'Registrar o movimento',
                    description:
                        'A equipe de entrada ou catraca registra o fluxo de clientes (+1, +5, +10) ou presença de alunos.',
                    icon: Icons.touch_app,
                  ),
                  const SizedBox(height: 14),
                  _buildStepCard(
                    step: '02',
                    title: 'Comparar com a previsão',
                    description:
                        'O sistema cruza a quantidade de pessoas atendidas com a meta diária e o tempo restante de serviço.',
                    icon: Icons.compare_arrows,
                  ),
                  const SizedBox(height: 14),
                  _buildStepCard(
                    step: '03',
                    title: 'Calcular a produção necessária',
                    description:
                        'Calcula o déficit exato considerando o estoque atual de cada comida e o consumo médio por pessoa.',
                    icon: Icons.calculate,
                  ),
                  const SizedBox(height: 14),
                  _buildStepCard(
                    step: '04',
                    title: 'Ajustar a recomendação',
                    description:
                        'Disponibiliza orientações claras (Normal, Reduzir, Não Iniciar Novo Lote) na tela da cozinha.',
                    icon: Icons.tune,
                  ),
                ],
              ),
            ),

            // FOOTER V.E.R.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              color: VerTheme.darkGreen,
              child: Column(
                children: [
                  const Text(
                    'V.E.R. — Visão Estratégica de Recursos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SmartBuffet: "Produza o necessário. Desperdice menos."',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: VerTheme.primaryGreen,
                    ),
                    child: const Text('Entrar no Sistema'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isDesktop,
    required Color backgroundColor,
    required String tag,
    required Color tagColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: VerTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              content,
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMiniBadge(
    IconData icon,
    String text,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade800),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VerTheme.softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VerTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: VerTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: VerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: VerTheme.primaryGreen.withValues(alpha: 0.6),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: VerTheme.primaryGreen.withValues(alpha: 0.12),
            child: Icon(icon, color: VerTheme.primaryGreen),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: VerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: VerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
