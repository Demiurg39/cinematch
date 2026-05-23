import 'dart:math' as math;
import 'package:flutter/material.dart';

class GenreRadarChart extends StatelessWidget {
  final Map<String, double> genreWeights;
  final double size;

  const GenreRadarChart({
    super.key,
    required this.genreWeights,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (genreWeights.isEmpty) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No genre data yet')),
      );
    }

    return SizedBox(
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _RadarChartPainter(genreWeights),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> genreWeights;

  _RadarChartPainter(this.genreWeights);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final entries = genreWeights.entries.toList();
    final n = entries.length;
    if (n < 3) return;

    final gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final dataPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final dataStrokePaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Grid rings + radial lines
    for (int ring = 1; ring <= 3; ring++) {
      final ringRadius = radius * ring / 3;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = (2 * math.pi * i / n) - math.pi / 2;
        final x = center.dx + ringRadius * math.cos(angle);
        final y = center.dy + ringRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Data polygon
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final weight = entries[i].value.clamp(0.0, 1.0);
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final r = radius * weight;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // Data points
    for (int i = 0; i < n; i++) {
      final weight = entries[i].value.clamp(0.0, 1.0);
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final r = radius * weight;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = const Color(0xFF7C4DFF)..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.genreWeights != genreWeights;
  }
}

class RadarChartLegend extends StatelessWidget {
  final Map<String, double> genreWeights;

  const RadarChartLegend({super.key, required this.genreWeights});

  @override
  Widget build(BuildContext context) {
    final sorted = genreWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: sorted.map((e) {
        return Chip(
          label: Text(
            '${e.key} ${(e.value * 100).toInt()}%',
            style: const TextStyle(fontSize: 11),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}