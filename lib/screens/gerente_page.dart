import 'package:flutter/material.dart';
import '../services/backend_service.dart';

/// TELA 1: Painel da Recepção / Gerente (GerentePage)
/// Simples, ágil e intuitivo para a recepcionista adicionar e remover clientes,
/// acompanhar o horário de pico/baixa, fechar o dia e visualizar a resposta da cozinha.
class GerentePage extends StatefulWidget {
  const GerentePage({super.key});

  @override
  State<GerentePage> createState() => _GerentePageState();
}

class _GerentePageState extends State<GerentePage> {
  final TextEditingController _horarioController = TextEditingController(text: '14:30');
  final BackendService _backend = BackendService();

  int _totalClientesHoje = 0;
  int _clientes15Min = 0;
  int _minutosRestantes = 60;
  String _horarioFechamento = '14:30';
  String _nivelAlerta = 'VERDE';
  String _instrucao = 'Produção normal. Cubas fundas padronizadas.';
  String _previsaoHorario = 'HORÁRIO REGULAR';
  bool _isPico = false;
  List<dynamic> _alimentos = [];
  bool _isLoading = false;
  String _statusMensagem = '';
  List<String> _diasFuncionamento = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  List<String> _feriadosManuais = [];

  static const List<Map<String, String>> _dias = [
    {'codigo': 'seg', 'sigla': 'SEG'},
    {'codigo': 'ter', 'sigla': 'TER'},
    {'codigo': 'qua', 'sigla': 'QUA'},
    {'codigo': 'qui', 'sigla': 'QUI'},
    {'codigo': 'sex', 'sigla': 'SEX'},
    {'codigo': 'sab', 'sigla': 'SÁB'},
    {'codigo': 'dom', 'sigla': 'DOM'},
  ];

  @override
  void initState() {
    super.initState();
    _backend.init();
    _carregarStatus();

    _backend.kitchenStream.listen((data) {
      if (mounted) {
        setState(() {
          _atualizarComPayload(data);
        });
      }
    });
  }

  @override
  void dispose() {
    _horarioController.dispose();
    super.dispose();
  }

  void _atualizarComPayload(Map<String, dynamic> data) {
    _nivelAlerta = data['nivel_alerta'] ?? _nivelAlerta;
    _instrucao = data['instrucao'] ?? _instrucao;
    _minutosRestantes = data['minutos_restantes'] ?? _minutosRestantes;
    _clientes15Min = data['clientes_15min'] ?? _clientes15Min;
    _totalClientesHoje = data['total_clientes_hoje'] ?? _totalClientesHoje;
    _horarioFechamento = (data['horario_fechamento'] ?? _horarioFechamento).toString().substring(0, 5);
    _previsaoHorario = data['previsao_horario'] ?? _previsaoHorario;
    _isPico = data['is_horario_pico'] ?? false;
    if (data['alimentos'] is List) {
      _alimentos = data['alimentos'];
    }
    if (data['dias_funcionamento'] is List) {
      _diasFuncionamento = List<String>.from(data['dias_funcionamento']);
    }
    if (data['feriados_manuais'] is List) {
      _feriadosManuais = List<String>.from(data['feriados_manuais']);
    }
  }

  Future<void> _carregarStatus() async {
    setState(() => _isLoading = true);
    final data = await _backend.fetchStatus();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data != null) {
          _atualizarComPayload(data);
          _horarioController.text = _horarioFechamento;
          _statusMensagem = 'Conectado ao backend SmartBuffet.';
        } else {
          _statusMensagem = 'Aguardando conexão com o backend.';
        }
      });
    }
  }

  Future<void> _enviarFluxo(int quantidade) async {
    setState(() {
      _isLoading = true;
      _statusMensagem = 'Registrando ${quantidade > 0 ? "+$quantidade" : "$quantidade"} cliente(s)...';
    });

    final sucesso = await _backend.recordFluxo(quantidade: quantidade);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (sucesso) {
          _statusMensagem = 'Fluxo de $quantidade registrado com sucesso!';
          if (_backend.lastPayload != null) {
            _atualizarComPayload(_backend.lastPayload!);
          }
        } else {
          _totalClientesHoje = (_totalClientesHoje + quantidade).clamp(0, 9999);
          _clientes15Min = (_clientes15Min + quantidade).clamp(0, 9999);
          _statusMensagem = 'Registrado em modo local.';
        }
      });
    }
  }

  Future<void> _definirHorarioFechamento([String? horarioCustomizado, int? minutosSimulados]) async {
    final horario = horarioCustomizado ?? _horarioController.text.trim();
    setState(() {
      _isLoading = true;
      _statusMensagem = 'Atualizando horário de fechamento...';
    });

    final sucesso = await _backend.updateClosingTime(
      closingTime: horarioCustomizado ?? (minutosSimulados == null ? horario : null),
      simulatedMinutes: minutosSimulados,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (sucesso) {
          _statusMensagem = 'Horário atualizado com sucesso!';
          if (_backend.lastPayload != null) {
            _atualizarComPayload(_backend.lastPayload!);
            _horarioController.text = _horarioFechamento;
          }
        } else {
          _statusMensagem = 'Falha ao atualizar horário.';
        }
      });
    }
  }

  Future<void> _toggleFeriado(String dia) async {
    final updated = List<String>.from(_feriadosManuais);
    if (updated.contains(dia)) {
      updated.remove(dia);
    } else {
      updated.add(dia);
    }
    setState(() {
      _feriadosManuais = updated;
    });
    await _backend.updateConfig(manualHolidays: updated);
  }

  Future<void> _selecionarHorarioDialog() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 30),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      final formatted = '$hh:$mm';
      _horarioController.text = formatted;
      await _definirHorarioFechamento(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBuffet — Recepção & Controle de Fluxo'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar Dados',
            onPressed: _carregarStatus,
          ),
          IconButton(
            icon: const Icon(Icons.soup_kitchen),
            tooltip: 'Abrir Display da Cozinha',
            onPressed: () => Navigator.pushNamed(context, '/cozinha'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Painel Geral Completo',
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ATALHOS DE NAVEGAÇÃO RÁPIDA
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.soup_kitchen),
                        label: const Text('Abrir Display da Cozinha (Tela Cheia)'),
                        onPressed: () => Navigator.pushNamed(context, '/cozinha'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black87),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.dashboard),
                        label: const Text('Ir para Painel Geral de Gerenciamento'),
                        onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_statusMensagem.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      _statusMensagem,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ),
                const SizedBox(height: 14),

                // =======================================================
                // 1. REGISTRO DE FLUXO (BOTÕES GRANDES E INTUITIVOS)
                // =======================================================
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Controle de Entrada e Saída de Clientes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Adicione ou remova pessoas conforme chegam ou saem do buffet. A cozinha ajusta a reposição instantaneamente:',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading ? null : () => _enviarFluxo(1),
                                child: const Text('+1 Cliente', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade900,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading ? null : () => _enviarFluxo(5),
                                child: const Text('+5 Clientes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading ? null : () => _enviarFluxo(10),
                                child: const Text('+10 Clientes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading ? null : () => _enviarFluxo(-1),
                                child: const Text('-1 Cliente', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // =======================================================
                // 2. INDICADORES DE FLUXO & HORÁRIO DE PICO/BAIXA
                // =======================================================
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. Indicadores de Demanda & Horários',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Total de Clientes Hoje', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_totalClientesHoje',
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blue.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Últimos 15 Minutos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_clientes15Min',
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.deepOrange.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: _isPico ? Colors.amber.shade100 : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _isPico ? Colors.amber.shade400 : Colors.teal.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(_isPico ? Icons.trending_up : Icons.schedule, size: 22, color: _isPico ? Colors.amber.shade900 : Colors.teal.shade900),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Previsão: $_previsaoHorario',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: _isPico ? Colors.amber.shade900 : Colors.teal.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // =======================================================
                // 3. DIAS DA SEMANA E CANCELAMENTO MANUAL DE FERIADOS
                // =======================================================
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3. Dias de Funcionamento & Folgas/Feriados Manuais',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Clique em um dia para marcar ou desmarcar feriado/folga manual:',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dias.map((d) {
                            final cod = d['codigo']!;
                            final sigla = d['sigla']!;
                            final isAberto = _diasFuncionamento.contains(cod);
                            final isFeriado = _feriadosManuais.contains(cod);

                            final Color bg;
                            final Color text;
                            final String status;

                            if (isFeriado) {
                              bg = Colors.red.shade100;
                              text = Colors.red.shade900;
                              status = 'Feriado';
                            } else if (isAberto) {
                              bg = Colors.green.shade100;
                              text = Colors.green.shade900;
                              status = 'Aberto';
                            } else {
                              bg = Colors.grey.shade200;
                              text = Colors.grey.shade700;
                              status = 'Fechado';
                            }

                            return InkWell(
                              onTap: () => _toggleFeriado(cod),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: text.withOpacity(0.4)),
                                ),
                                child: Column(
                                  children: [
                                    Text(sigla, style: TextStyle(fontWeight: FontWeight.w900, color: text)),
                                    Text(status, style: TextStyle(fontSize: 10, color: text)),
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
                const SizedBox(height: 16),

                // =======================================================
                // 4. HORÁRIO DE FECHAMENTO & SIMULAÇÃO DE FASES
                // =======================================================
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '4. Horário de Fechamento do Buffet',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('Fechamento programado: $_horarioFechamento (Restam $_minutosRestantes min para encerrar)'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _horarioController,
                                decoration: const InputDecoration(
                                  labelText: 'Horário de Fechamento (HH:mm)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _definirHorarioFechamento(),
                              child: const Text('Salvar'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _selecionarHorarioDialog,
                              icon: const Icon(Icons.access_time),
                              label: const Text('Relógio'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Atalhos de Simulação para Banca / Demonstração:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('Simular > 60 min (Status VERDE)'),
                              backgroundColor: Colors.green.shade100,
                              onPressed: () => _definirHorarioFechamento(null, 90),
                            ),
                            ActionChip(
                              label: const Text('Simular 45 min (Status AMARELO)'),
                              backgroundColor: Colors.amber.shade100,
                              onPressed: () => _definirHorarioFechamento(null, 45),
                            ),
                            ActionChip(
                              label: const Text('Simular 20 min (Status VERMELHO)'),
                              backgroundColor: Colors.red.shade100,
                              onPressed: () => _definirHorarioFechamento(null, 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // =======================================================
                // 5. DEMANDA DE ALIMENTOS
                // =======================================================
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '5. Alimentos do Buffet & Demanda Instantânea',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/menu'),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Cadastrar Comida'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_alimentos.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('Nenhum alimento cadastrado.'),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _alimentos.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final a = _alimentos[index];
                              final nome = a['nome'] ?? 'Alimento';
                              final estoque = a['estoque_atual'] ?? 0;
                              final demanda = a['demanda_estimada_kg'] ?? 0;
                              final orientacao = a['orientacao_producao'] ?? 'Normal';
                              final tipoCuba = a['tipo_cuba'] ?? 'CUBA_FUNDA';

                              return ListTile(
                                dense: true,
                                title: Text(nome.toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Estoque: $estoque kg | Demanda estimada: $demanda kg | Cuba: $tipoCuba'),
                                trailing: Text(
                                  orientacao.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: orientacao.toString().contains('Estoque suficiente')
                                        ? Colors.green.shade800
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
