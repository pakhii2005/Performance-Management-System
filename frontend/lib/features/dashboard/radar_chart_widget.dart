import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RadarChartWidget extends StatefulWidget {
  final Map<String, int> competencyScores;
  final double size;

  const RadarChartWidget({
    super.key,
    required this.competencyScores,
    this.size = 300,
  });

  @override
  State<RadarChartWidget> createState() => _RadarChartWidgetState();
}

class _RadarChartWidgetState extends State<RadarChartWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RadarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation on data change
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: RadarChartPainter(
            competencyScores: widget.competencyScores,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, int> competencyScores;
  final double animationValue;

  RadarChartPainter({
    required this.competencyScores,
    required this.animationValue,
  });

  // The 8 competencies in order
  static const List<String> competencies = [
    'Communication',
    'Technical Skills',
    'Problem Solving',
    'Leadership',
    'Teamwork',
    'Adaptability',
    'Customer Focus',
    'Innovation',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2.3;

    // Paints
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final spokePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dataPaint = Paint()
      ..color = AppTheme.accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final dataOutlinePaint = Paint()
      ..color = AppTheme.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 1. Draw grid of concentric regular octagons (representing scores 1 to 5)
    final int levels = 5;
    for (int i = 1; i <= levels; i++) {
      final radius = (i / levels) * maxRadius;
      final path = Path();
      for (int j = 0; j < competencies.length; j++) {
        final angle = j * 2 * math.pi / competencies.length - math.pi / 2;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);

      // Draw numerical labels along the first spoke (top)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(center.dx + 4, center.dy - radius - textPainter.height / 2),
      );
    }

    // 2. Draw spokes (lines from center to outer level)
    for (int j = 0; j < competencies.length; j++) {
      final angle = j * 2 * math.pi / competencies.length - math.pi / 2;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), spokePaint);

      // Draw spoke competency labels at the ends
      final label = competencies[j];
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black87, fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position the label slightly outside the maxRadius spoke end
      final labelRadius = maxRadius + 15;
      final lx = center.dx + labelRadius * math.cos(angle) - textPainter.width / 2;
      // Adjust y position to prevent overlaps
      double ly = center.dy + labelRadius * math.sin(angle) - textPainter.height / 2;
      if (angle == -math.pi / 2) {
        ly -= 4; // Top offset
      } else if (angle == math.pi / 2) {
        ly += 4; // Bottom offset
      }

      textPainter.paint(canvas, Offset(lx, ly));
    }

    // 3. Plot employee's competency data polygon
    final dataPath = Path();
    bool firstPoint = true;
    for (int j = 0; j < competencies.length; j++) {
      final label = competencies[j];
      final score = competencyScores[label] ?? 0;
      final animatedScore = score * animationValue;
      final radius = (animatedScore / levels) * maxRadius;

      final angle = j * 2 * math.pi / competencies.length - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (firstPoint) {
        dataPath.moveTo(x, y);
        firstPoint = false;
      } else {
        dataPath.lineTo(x, y);
      }
    }
    if (!firstPoint) {
      dataPath.close();
      canvas.drawPath(dataPath, dataPaint);
      canvas.drawPath(dataPath, dataOutlinePaint);

      // Draw data point circles
      final dotPaint = Paint()
        ..color = AppTheme.accentColor
        ..style = PaintingStyle.fill;
      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (int j = 0; j < competencies.length; j++) {
        final label = competencies[j];
        final score = competencyScores[label] ?? 0;
        final animatedScore = score * animationValue;
        final radius = (animatedScore / levels) * maxRadius;

        final angle = j * 2 * math.pi / competencies.length - math.pi / 2;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);

        canvas.drawCircle(Offset(x, y), 5.0, dotPaint);
        canvas.drawCircle(Offset(x, y), 5.0, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.competencyScores != competencyScores;
  }
}
