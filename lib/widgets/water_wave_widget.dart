import 'dart:math';
import 'package:flutter/material.dart';

class WaterWaveWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color color;

  const WaterWaveWidget({
    super.key,
    required this.progress,
    this.size = 200,
    this.color = Colors.blue,
  });

  @override
  State<WaterWaveWidget> createState() => _WaterWaveWidgetState();
}

class _WaterWaveWidgetState extends State<WaterWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WavePainter(
            progress: widget.progress.clamp(0.0, 1.0),
            wavePhase: _controller.value * 2 * pi,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip to circle
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(circlePath);

    // Draw background
    final bgPaint = Paint()..color = color.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius, bgPaint);

    // Draw wave
    final waterLevel = size.height * (1 - progress);
    final wavePath = Path();
    wavePath.moveTo(0, waterLevel);

    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel +
          sin((x / size.width * 2 * pi) + wavePhase) * 6 +
          cos((x / size.width * 3 * pi) + wavePhase * 0.8) * 3;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    final wavePaint = Paint()..color = color.withValues(alpha: 0.4);
    canvas.drawPath(wavePath, wavePaint);

    // Second wave layer
    final wavePath2 = Path();
    wavePath2.moveTo(0, waterLevel);
    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel +
          sin((x / size.width * 2 * pi) + wavePhase + 1.5) * 4 +
          cos((x / size.width * 2.5 * pi) + wavePhase * 1.2) * 3;
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(size.width, size.height);
    wavePath2.lineTo(0, size.height);
    wavePath2.close();

    final wavePaint2 = Paint()..color = color.withValues(alpha: 0.6);
    canvas.drawPath(wavePath2, wavePaint2);

    // Draw circle border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.wavePhase != wavePhase;
}
