import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/recommendation_model.dart';

class StatusBadge extends StatelessWidget {
  final RecommendationAction action;
  final String? customLabel;

  const StatusBadge({super.key, required this.action, this.customLabel});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    IconData icon;

    switch (action) {
      case RecommendationAction.normal:
        bg = VerTheme.statusNormal;
        icon = Icons.check_circle_outline;
        break;
      case RecommendationAction.reduzir:
        bg = VerTheme.statusReduzir;
        icon = Icons.trending_down;
        break;
      case RecommendationAction.aumentar:
        bg = VerTheme.statusAumentar;
        icon = Icons.trending_up;
        break;
      case RecommendationAction.naoIniciar:
        bg = VerTheme.statusNaoIniciar;
        icon = Icons.block;
        break;
      case RecommendationAction.minima:
        bg = VerTheme.statusMinima;
        icon = Icons.hourglass_bottom;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            customLabel ?? action.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
