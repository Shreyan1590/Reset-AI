import 'package:flutter/material.dart';

/// Official Google "G" logo widget with multi-color segments
/// Blue, Red, Yellow, Green - matching Google brand guidelines
class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: CustomPaint(
        size: Size(size * 0.8, size * 0.8),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    // The Google "G" consists of 4 colored arcs
    
    // Blue arc (right side, from top to middle-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -0.9, // starting angle
      1.6,  // sweep angle
      false,
      paint,
    );

    // Green arc (bottom right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.7,
      0.95,
      false,
      paint,
    );

    // Yellow arc (bottom left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.65,
      0.95,
      false,
      paint,
    );

    // Red arc (top left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      2.6,
      0.95,
      false,
      paint,
    );

    // Blue horizontal bar (the crossbar of the G)
    paint.color = const Color(0xFF4285F4);
    paint.style = PaintingStyle.fill;
    final barHeight = strokeWidth;
    final barLeft = center.dx - strokeWidth * 0.15;
    final barTop = center.dy - barHeight / 2;
    canvas.drawRect(
      Rect.fromLTWH(barLeft, barTop, radius + strokeWidth * 0.15, barHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
