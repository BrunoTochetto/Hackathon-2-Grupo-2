import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/history_model.dart';
import 'package:intl/intl.dart';

class WasteChart extends StatelessWidget {
  final List<HistoryRecordModel> historyRecords;

  const WasteChart({super.key, required this.historyRecords});

  @override
  Widget build(BuildContext context) {
    if (historyRecords.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: const Text(
          'Sem histórico de desperdício acumulado.',
          style: TextStyle(color: VerTheme.textMuted),
        ),
      );
    }

    final displayRecords = historyRecords.take(7).toList().reversed.toList();
    final maxWaste = displayRecords
        .map((r) => max(r.totalWasteKg, r.wasteAvoidedKg))
        .fold<double>(0.0, max);
    final ceiling = max(1.0, maxWaste * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
              const Text(
                'Desperdício vs Desperdício Evitado (kg)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: VerTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Descarte',
                    style: TextStyle(
                      fontSize: 11,
                      color: VerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: VerTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Evitado',
                    style: TextStyle(
                      fontSize: 11,
                      color: VerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: displayRecords.map((record) {
                final wasteHeight = (record.totalWasteKg / ceiling * 120).clamp(
                  6.0,
                  120.0,
                );
                final avoidedHeight = (record.wasteAvoidedKg / ceiling * 120)
                    .clamp(6.0, 120.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Barra Descarte
                        Container(
                          width: 12,
                          height: wasteHeight,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Barra Evitado
                        Container(
                          width: 12,
                          height: avoidedHeight,
                          decoration: BoxDecoration(
                            color: VerTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM').format(record.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: VerTheme.textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
