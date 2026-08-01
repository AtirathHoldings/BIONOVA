import 'package:flutter/material.dart';

/// ReassignIcon renders the exact Reverse C Arrow icon (↩) matching the website's Reassign icon
class ReassignIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const ReassignIcon({
    super.key,
    this.size = 16,
    this.color = const Color(0xFF4F46E5),
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ReassignIconPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _ReassignIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ReassignIconPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Arrowhead pointing left at (4,18)
    final arrowPath = Path()
      ..moveTo(9 * scale, 14 * scale)
      ..lineTo(4 * scale, 18 * scale)
      ..lineTo(9 * scale, 22 * scale);

    // Body: Reverse 'C' curve (Start (8,8) -> line right to (15,8) -> curve 180° down right side to (15,18) -> line left to (4,18))
    final bodyPath = Path()
      ..moveTo(8 * scale, 8 * scale)
      ..lineTo(15 * scale, 8 * scale)
      ..arcToPoint(
        Offset(15 * scale, 18 * scale),
        radius: Radius.circular(5 * scale),
        clockwise: true,
      )
      ..lineTo(4 * scale, 18 * scale);

    canvas.drawPath(arrowPath, paint);
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ReassignIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
