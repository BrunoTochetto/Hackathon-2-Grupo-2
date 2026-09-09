import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backend_service.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// TELA 2: Display da Cozinha (CozinhaPage)
/// Simples, de alta legibilidade para operadores na cozinha, com modo Tela Cheia nativo.
class CozinhaPage extends StatefulWidget {
  const CozinhaPage({super.key});

  @override
  State<CozinhaPage> createState() => _CozinhaPageState();
}

class _CozinhaPageState extends State<CozinhaPage> {
  final BackendService _backend = BackendService();

  String _nivelAlerta = 'VERDE'; // VERDE, AMARELO, VERMELHO
  String _instrucao = 'Produção normal. Cubas fundas padronizadas.';
  int _minutosRestantes = 60;
  int _clientes15Min = 0;
  int _totalClientesHoje = 0;
  String _tipoCuba = 'CUBA_FUNDA';
  String _previsaoHorario = 'HORÁRIO REGULAR';
  bool _isPico = false;
  List<dynamic> _alimentos = [];
  DateTime _ultimaAtualizacao = DateTime.now();
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _backend.init();
    _carregarStatusInicial();

    // Escuta em tempo real o canal 'cozinha_stream' via Socket.io
    _backend.kitchenStream.listen((data) {
      if (mounted) {
        setState(() {
          _aplicarPayload(data);
        });
      }
    });
  }

  void _aplicarPayload(Map<String, dynamic> data) {
    _nivelAlerta = (data['nivel_alerta'] ?? _nivelAlerta).toString().toUpperCase();
    _instrucao = data['instrucao'] ?? _instrucao;
    _minutosRestantes = data['minutos_restantes'] ?? _minutosRestantes;
    _clientes15Min = data['clientes_15min'] ?? _clientes15Min;
    _totalClientesHoje = data['total_clientes_hoje'] ?? _totalClientesHoje;
    _tipoCuba = data['tipo_cuba'] ?? _tipoCuba;
    _previsaoHorario = data['previsao_horario'] ?? _previsaoHorario;
    _isPico = data['is_horario_pico'] ?? false;
    if (data['alimentos'] is List) {
      _alimentos = data['alimentos'];
    }
    _ultimaAtualizacao = DateTime.now();
  }

  Future<void> _carregarStatusInicial() async {
    final data = await _backend.fetchStatus(restauranteId: 1);
    if (mounted && data != null) {
      setState(() {
        _aplicarPayload(data);
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (kIsWeb) {
      try {
        if (_isFullscreen) {
          html.document.documentElement?.requestFullscreen();
        } else {
          if (html.document.fullscreenElement != null) {
            html.document.exitFullscreen();
          }
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardBgColor;
    final Color textColor;
    final Color badgeColor;

    switch (_nivelAlerta) {
      case 'VERMELHO':
        cardBgColor = Colors.red.shade700;
        textColor = Colors.white;
        badgeColor = Colors.red.shade900;
        break;
      case 'AMARELO':
        cardBgColor = Colors.amber.shade700;
        textColor = Colors.black87;
        badgeColor = Colors.amber.shade900;
        break;
      case 'VERDE':
      default:
        cardBgColor = Colors.green.shade700;
        textColor = Colors.white;
        badgeColor = Colors.green.shade900;
        break;
    }

    final bodyWidget = SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BARRA DE AÇÃO / TELA CHEIA E NAVEGAÇÃO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar à Recepção'),
                    onPressed: () => Navigator.pushNamed(context, '/gerente'),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black54),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.dashboard),
                        label: const Text('Painel Geral'),
                        onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFullscreen ? Colors.red.shade700 : Colors.indigo.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                        label: Text(
                          _isFullscreen ? 'Sair Tela Cheia' : 'Abrir Tela Cheia',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD CENTRALIZADO EM DESTAQUE COM O NÍVEL DE ALERTA
              Card(
                color: cardBgColor,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'STATUS ATUAL: $_nivelAlerta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _instrucao,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recipiente: $_tipoCuba • ${_isPico ? "HORÁRIO DE PICO (+35%)" : "HORÁRIO REGULAR"}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // INDICADORES DE CONTEXTO
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Tempo Restante', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$_minutosRestantes min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Clientes (15 min)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$_clientes15Min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Total Hoje', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$_totalClientesHoje', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // TABELA DE O QUE DEVE SER FEITO NA COZINHA
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alimentos & O Que a Cozinha Deve Fazer:',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Atualizado: ${DateFormat('HH:mm:ss').format(_ultimaAtualizacao)}',
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_alimentos.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Nenhum alimento retornado.'),
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
                            final isSuficiente = orientacao.toString().contains('Estoque suficiente');

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              title: Text(
                                nome.toString().toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              subtitle: Text(
                                'Estoque: $estoque kg | Demanda: $demanda kg',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSuficiente ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSuficiente ? Colors.green : Colors.orange),
                                ),
                                child: Text(
                                  orientacao.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSuficiente ? Colors.green.shade900 : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        body: SafeArea(child: bodyWidget),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBuffet — Display da Cozinha'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sincronizar via REST',
            onPressed: _carregarStatusInicial,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Abrir Tela Cheia',
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade300,
      body: bodyWidget,
    );
  }
}
