import 'package:flutter/material.dart';

/// ReassignIcon renders the exact SVG path matching the website's Reassign icon
/// (Lucide Undo2 / CornerUpLeft: top line going right, curving 180° down on the right side,
/// bottom line going left, ending with an arrowhead pointing left at the bottom left).
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

    // Arrowhead at (4,18) pointing left: polyline 9,14 -> 4,18 -> 9,22
    final arrowPath = Path()
      ..moveTo(9 * scale, 14 * scale)
      ..lineTo(4 * scale, 18 * scale)
      ..lineTo(9 * scale, 22 * scale);

    // Body: M 4,18 H 15 A 5,5 0 0,0 15,8 H 8
    // Bottom line from (4,18) right to (15,18), curves 180° UP around right side to (15,8), top line left to (8,8)
    final bodyPath = Path()
      ..moveTo(4 * scale, 18 * scale)
      ..lineTo(15 * scale, 18 * scale)
      ..arcToPoint(
        Offset(15 * scale, 8 * scale),
        radius: Radius.circular(5 * scale),
        clockwise: false,
      )
      ..lineTo(8 * scale, 8 * scale);

    canvas.drawPath(arrowPath, paint);
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ReassignIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
