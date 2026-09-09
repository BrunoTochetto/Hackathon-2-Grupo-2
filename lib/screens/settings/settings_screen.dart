import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/establishment_model.dart';
import '../../state/auth_provider.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _estNameCtrl = TextEditingController();
  final _openTimeCtrl = TextEditingController();
  final _closeTimeCtrl = TextEditingController();
  final _peakStartCtrl = TextEditingController(text: '12:00');
  final _peakEndCtrl = TextEditingController(text: '13:30');
  final _expectedCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final buffet = context.read<BuffetProvider>();
      final auth = context.read<AuthProvider>();
      _nameCtrl.text = auth.user?.name ?? 'Gestor do Buffet';
      _estNameCtrl.text = buffet.establishment.name;
      _openTimeCtrl.text = buffet.establishment.openingTime;
      _closeTimeCtrl.text = buffet.establishment.closingTime;
      _expectedCtrl.text = buffet.establishment.expectedGuests.toString();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _estNameCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    _peakStartCtrl.dispose();
    _peakEndCtrl.dispose();
    _expectedCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final buffet = context.read<BuffetProvider>();
    final auth = context.read<AuthProvider>();

    final expectedVal =
        int.tryParse(_expectedCtrl.text) ?? buffet.establishment.expectedGuests;

    buffet.updateEstablishment(
      name: _estNameCtrl.text.trim(),
      type: EstablishmentType.restaurante,
      openingTime: _openTimeCtrl.text.trim(),
      closingTime: _closeTimeCtrl.text.trim(),
      expectedGuests: expectedVal,
    );

    buffet.updateConfigHours(
      openingTime: _openTimeCtrl.text.trim(),
      closingTime: _closeTimeCtrl.text.trim(),
      peakStartTime: _peakStartCtrl.text.trim(),
      peakEndTime: _peakEndCtrl.text.trim(),
    );

    auth.updateProfileName(_nameCtrl.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas e sincronizadas com o backend!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ResponsiveScaffold(
      currentIndex: 4,
      title: 'Configurações do Buffet',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perfil e Estabelecimento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Seu Nome Completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _estNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Restaurante / Buffet',
                          prefixIcon: Icon(Icons.storefront),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Horário de Funcionamento & Horário de Pico',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Defina os horários de serviço e o intervalo de maior movimento para o algoritmo de previsão:',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _openTimeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Abertura (HH:mm)',
                                prefixIcon: Icon(Icons.login),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _closeTimeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Fechamento (HH:mm)',
                                prefixIcon: Icon(Icons.logout),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _peakStartCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Início Horário de Pico',
                                prefixIcon: Icon(Icons.trending_up),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _peakEndCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Fim Horário de Pico',
                                prefixIcon: Icon(Icons.trending_down),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _expectedCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Capacidade Estimada de Clientes no Dia',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: VerTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Salvar Configurações',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Logout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.shade100,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sessão Atual',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            auth.user?.email ?? 'Usuário conectado',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair'),
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
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
}
