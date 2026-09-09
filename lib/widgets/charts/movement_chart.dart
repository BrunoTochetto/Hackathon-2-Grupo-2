import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/movement_model.dart';
import 'package:intl/intl.dart';

class MovementChart extends StatelessWidget {
  final List<MovementModel> movements;
  final int expectedGuests;

  const MovementChart({
    super.key,
    required this.movements,
    required this.expectedGuests,
  });

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: const Text(
          'Nenhum movimento registrado hoje ainda.',
          style: TextStyle(color: VerTheme.textMuted, fontSize: 14),
        ),
      );
    }

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
                'Evolução do Movimento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VerTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: VerTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Real',
                    style: TextStyle(
                      fontSize: 12,
                      color: VerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 12, height: 2, color: Colors.orange),
                  const SizedBox(width: 4),
                  const Text(
                    'Previsão',
                    style: TextStyle(
                      fontSize: 12,
                      color: VerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: CustomPaint(
              size: const Size(double.infinity, 170),
              painter: _MovementChartPainter(
                movements: movements,
                expectedGuests: expectedGuests,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('HH:mm').format(movements.first.timestamp),
                style: const TextStyle(fontSize: 11, color: VerTheme.textMuted),
              ),
              const Text(
                'Tempo Real',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: VerTheme.primaryGreen,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(movements.last.timestamp),
                style: const TextStyle(fontSize: 11, color: VerTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementChartPainter extends CustomPainter {
  final List<MovementModel> movements;
  final int expectedGuests;

  _MovementChartPainter({
    required this.movements,
    required this.expectedGuests,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxCount = max(
      expectedGuests,
      movements.map((m) => m.totalCount).fold<int>(0, max),
    );
    final ceiling = max(10, (maxCount * 1.25).ceil());

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // Linhas horizontais de grade
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (1.0 - (i / 4.0));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Linha de previsão tracejada
    final forecastY =
        size.height * (1.0 - (expectedGuests / ceiling).clamp(0.0, 1.0));
    final forecastPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, forecastY),
        Offset(startX + 6, forecastY),
        forecastPaint,
      );
      startX += 12;
    }

    // Pontos do movimento real
    final points = <Offset>[];
    for (int i = 0; i < movements.length; i++) {
      final x = movements.length == 1
          ? size.width / 2
          : (size.width / (movements.length - 1)) * i;
      final y =
          size.height *
          (1.0 - (movements[i].totalCount / ceiling).clamp(0.0, 1.0));
      points.add(Offset(x, y));
    }

    // Gradiente abaixo da linha
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    for (final pt in points) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          VerTheme.primaryGreen.withValues(alpha: 0.35),
          VerTheme.primaryGreen.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fillPaint);

    // Linha principal verde
    final linePaint = Paint()
      ..color = VerTheme.primaryGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Círculos nos pontos
    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = VerTheme.primaryGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MovementChartPainter oldDelegate) {
    return oldDelegate.movements != movements ||
        oldDelegate.expectedGuests != expectedGuests;
  }
}
