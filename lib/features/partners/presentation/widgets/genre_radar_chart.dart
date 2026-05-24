import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/genre_harmony_data.dart';

class GenreRadarChart extends StatelessWidget {
  final GenreHarmonyData data;
  final double size;

  const GenreRadarChart({
    super.key,
    required this.data,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No genre data yet')),
      );
    }

    return SizedBox(
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _RadarChartPainter(data),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final GenreHarmonyData data;

  _RadarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final genres = data.allGenres.toList()..sort();
    final n = genres.length;
    if (n < 3) return;

    final gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Grid rings + radial lines
    for (int ring = 1; ring <= 3; ring++) {
      final ringRadius = radius * ring / 3;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = (2 * math.pi * i / n) - math.pi / 2;
        final x = center.dx + ringRadius * math.cos(angle);
        final y = center.dy + ringRadius * math.sin(angle);
        if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
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

    // Draw 3 layers: user (blue), partner (pink), shared (purple)
    _drawLayer(canvas, center, radius, genres, data.userWeights,
        const Color(0xFF448AFF).withValues(alpha: 0.2),
        const Color(0xFF448AFF));
    _drawLayer(canvas, center, radius, genres, data.partnerWeights,
        const Color(0xFFFF4081).withValues(alpha: 0.2),
        const Color(0xFFFF4081));
    _drawLayer(canvas, center, radius, genres, data.sharedWeights,
        const Color(0xFF7C4DFF).withValues(alpha: 0.3),
        const Color(0xFF7C4DFF));
  }

  void _drawLayer(Canvas canvas, Offset center, double radius, List<String> genres,
      Map<String, double> weights, Color fillColor, Color strokeColor) {
    if (weights.isEmpty) return;

    final dataPath = Path();
    bool hasPoints = false;

    for (int i = 0; i < genres.length; i++) {
      final weight = (weights[genres[i]] ?? 0.0).clamp(0.0, 1.0);
      if (weight == 0 && i == 0) continue;
      final angle = (2 * math.pi * i / genres.length) - math.pi / 2;
      final r = radius * weight;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (!hasPoints) {
        dataPath.moveTo(x, y);
        hasPoints = true;
      } else {
        dataPath.lineTo(x, y);
      }
    }

    if (!hasPoints) return;
    dataPath.close();

    canvas.drawPath(dataPath, Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill);
    canvas.drawPath(dataPath, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Data points
    for (int i = 0; i < genres.length; i++) {
      final weight = (weights[genres[i]] ?? 0.0).clamp(0.0, 1.0);
      if (weight == 0) continue;
      final angle = (2 * math.pi * i / genres.length) - math.pi / 2;
      final r = radius * weight;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3,
          Paint()..color = strokeColor..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class RadarChartLegend extends StatelessWidget {
  final GenreHarmonyData data;

  const RadarChartLegend({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final allGenres = data.allGenres.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(const Color(0xFF448AFF), 'You'),
            const SizedBox(width: 16),
            _LegendDot(const Color(0xFFFF4081), 'Partner'),
            const SizedBox(width: 16),
            _LegendDot(const Color(0xFF7C4DFF), 'Shared'),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: allGenres.map((genre) {
            final userVal = (data.userWeights[genre] ?? 0) * 100;
            final partnerVal = (data.partnerWeights[genre] ?? 0) * 100;
            return Chip(
              label: Text('$genre  U:${userVal.toInt()}% P:${partnerVal.toInt()}%',
                  style: const TextStyle(fontSize: 10)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
        )),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}