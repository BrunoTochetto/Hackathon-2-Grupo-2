import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/recommendation_model.dart';
import '../../state/buffet_provider.dart';
import '../../services/backend_service.dart';
import '../../widgets/common/responsive_scaffold.dart';

// Conditionally import dart:html for browser fullscreen
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class KitchenScreen extends StatefulWidget {
  final bool startInFullscreen;
  const KitchenScreen({super.key, this.startInFullscreen = false});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _isFullscreen = widget.startInFullscreen;
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
    final buffet = context.watch<BuffetProvider>();
    final recs = buffet.recommendations;
    final remainingMin = buffet.remainingMinutes;
    final clients15 = buffet.clientsLast15Minutes;
    final alertLevel = buffet.productionAlertLevel;
    final alertInstruction = buffet.productionAlertInstruction;
    final panType = buffet.suggestedPanType;
    final periodDesc = buffet.currentPeriodDescription;
    final isPeak = buffet.isPeakHour;
    final demands = buffet.foodDemandForCurrentFlow;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 750;

    // Cores do painel industrial
    final Color alertBgColor;
    final Color alertBorderColor;
    final Color alertBadgeColor;
    final IconData alertIcon;

    if (alertLevel == 'VERMELHO') {
      alertBgColor = const Color(0xFF450A0A);
      alertBorderColor = Colors.redAccent;
      alertBadgeColor = Colors.red.shade700;
      alertIcon = Icons.warning_amber_rounded;
    } else if (alertLevel == 'AMARELO') {
      alertBgColor = const Color(0xFF451A03);
      alertBorderColor = Colors.amberAccent;
      alertBadgeColor = Colors.amber.shade800;
      alertIcon = Icons.change_circle_outlined;
    } else {
      alertBgColor = const Color(0xFF052E16);
      alertBorderColor = Colors.greenAccent;
      alertBadgeColor = VerTheme.primaryGreen;
      alertIcon = Icons.check_circle_outline;
    }

    final content = Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // BARRA SUPERIOR: IDENTIFICAÇÃO, TEMPO RESTANTE & BOTÃO TELA CHEIA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF020617),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.soup_kitchen, color: Colors.amberAccent, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SMARTBUFFET — DISPLAY DA COZINHA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              isPeak ? Icons.trending_up : Icons.schedule,
                              color: isPeak ? Colors.amberAccent : Colors.tealAccent,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              periodDesc,
                              style: TextStyle(
                                color: isPeak ? Colors.amberAccent : Colors.tealAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: alertBadgeColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: alertBorderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Fechamento em $remainingMin min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // BOTÃO DE TELA CHEIA SOLICITADO
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFullscreen ? Colors.amber.shade700 : Colors.blueGrey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 20),
                      label: Text(
                        _isFullscreen ? 'Sair Tela Cheia' : 'Tela Cheia',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. CARD CENTRAL: STATUS DE ALERTA & REGRA DE PRODUÇÃO
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: alertBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: alertBorderColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: alertBorderColor.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: alertBadgeColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(alertIcon, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'STATUS: $alertLevel',
                                          style: TextStyle(
                                            color: alertBorderColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          'Recipiente Recomendado: $panType',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // CONTADOR 15 MINUTOS
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'ÚLTIMOS 15 MINUTOS',
                                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800),
                                      ),
                                      Text(
                                        '$clients15 clientes',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'Total hoje: ${buffet.establishment.currentGuests}',
                                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 12),
                            // INSTRUÇÃO DA COZINHA
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DIRETRIZ DA COZINHA EM TEMPO REAL:',
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    alertInstruction,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. LINHA DE ALIMENTOS: DEMANDA CALCULADA PELO FLUXO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Linha de Servimento & Demanda Projetada',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Calculado para $clients15 clientes (15 min)',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recs.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTabletOrDesktop ? 2 : 1,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 130,
                        ),
                        itemBuilder: (context, index) {
                          final rec = recs[index];
                          final isNoBatch = rec.action == RecommendationAction.naoIniciar;
                          final isHighUrgency = rec.action == RecommendationAction.aumentar;
                          final demandKg = demands[rec.foodId] ?? (clients15 * 0.08);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHighUrgency
                                    ? Colors.redAccent
                                    : isNoBatch
                                        ? Colors.grey.shade700
                                        : Colors.greenAccent.withOpacity(0.5),
                                width: isHighUrgency ? 2.0 : 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        rec.foodName.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Estoque atual: ${rec.currentStock.toStringAsFixed(1)} ${rec.unit} | Demanda: ${demandKg.toStringAsFixed(1)} ${rec.unit}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        rec.reason,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isNoBatch
                                        ? Colors.black38
                                        : isHighUrgency
                                            ? Colors.red.shade700
                                            : VerTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    rec.shortKitchenSummary,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isNoBatch ? Colors.grey.shade400 : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // RODAPÉ: ATUALIZADO & STATUS WEBSOCKET
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            color: const Color(0xFF020617),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: BackendService().isConnected ? Colors.greenAccent : Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      BackendService().isConnected
                          ? 'WebSocket Node.js (cozinha_stream) conectado'
                          : 'Motor de Regras Inteligente Ativo (Local + Sync)',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  'Atualizado: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_isFullscreen) {
      return Scaffold(
        body: SafeArea(child: content),
      );
    }

    return ResponsiveScaffold(
      currentIndex: 3,
      title: 'Visão da Cozinha Industrial',
      body: content,
    );
  }
}
