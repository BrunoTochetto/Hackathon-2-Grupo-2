import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common/responsive_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentIndex: 9,
      title: 'Sobre a V.E.R.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CARD PRINCIPAL INSTITUCIONAL
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: VerTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility,
                          size: 56,
                          color: VerTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Visão Estratégica de Recursos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: VerTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Equipe V.E.R.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: VerTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'A V.E.R. é uma equipe que busca utilizar tecnologia para encontrar formas mais eficientes de administrar recursos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: VerTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nosso primeiro projeto é o SmartBuffet, uma ferramenta criada para ajudar escolas e restaurantes a reduzir a superprodução de alimentos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: VerTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ESTRUTURA MODULAR PARA INTEGRANTES (conforme especificado sem inventar nomes)
                Container(
                  padding: const EdgeInsets.all(24),
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
                        'Integrantes da Equipe V.E.R.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Estrutura preparada para inclusão oficial dos membros do projeto:',
                        style: TextStyle(
                          fontSize: 13,
                          color: VerTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildMemberSlot(
                        title: 'Membro 1 — Desenvolvimento & Arquitetura',
                        subtitle: 'Disponível para identificação do integrante',
                      ),
                      const Divider(height: 16),
                      _buildMemberSlot(
                        title: 'Membro 2 — UX/UI & Pesquisa Estratégica',
                        subtitle: 'Disponível para identificação do integrante',
                      ),
                      const Divider(height: 16),
                      _buildMemberSlot(
                        title: 'Membro 3 — Gestão de Recursos & Apresentação',
                        subtitle: 'Disponível para identificação do integrante',
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

  static Widget _buildMemberSlot({
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFF1F5F9),
        child: Icon(Icons.person, color: VerTheme.primaryGreen),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: VerTheme.textMuted),
      ),
    );
  }
}
