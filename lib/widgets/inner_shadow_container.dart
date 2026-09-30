import 'package:flutter/material.dart';

/// Sebuah Container custom dengan warna background kustom (#e1d9cf) 
/// dan efek Inner Shadow (Shadow di Dalam) sehingga input menyatu dengan bg template card.
class InnerShadowContainer extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color shadowColor;
  final double blurRadius;
  final Offset offset;
  final Widget child;

  const InnerShadowContainer({
    super.key,
    this.width,
    this.height = 45.0,
    this.borderRadius = 10.0,
    this.backgroundColor = const Color(0xFFE1D9CF),
    this.shadowColor = const Color(0x403E2723), // Shadow cokelat tua subtle di bagian dalam atas/kiri
    this.blurRadius = 4.0,
    this.offset = const Offset(2.0, 2.5),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _InnerShadowPainter(
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          shadowColor: shadowColor,
          blurRadius: blurRadius,
          offset: offset,
        ),
        child: child,
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final double borderRadius;
  final Color backgroundColor;
  final Color shadowColor;
  final double blurRadius;
  final Offset offset;

  _InnerShadowPainter({
    required this.borderRadius,
    required this.backgroundColor,
    required this.shadowColor,
    required this.blurRadius,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Gambar background utama (#e1d9cf)
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(rrect, bgPaint);

    // 2. Clip canvas sesuai batas border radius container
    canvas.save();
    canvas.clipRRect(rrect);

    // 3. Gambar inner shadow di bagian dalam (top-left offset)
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    final shadowPath = Path()
      ..addRect(rect.inflate(20.0))
      ..addRRect(rrect.shift(offset))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(shadowPath, shadowPaint);

    // 4. Subtle inner highlight (garis bagian bawah/kanan agar memberi kedalaman 3D)
    final highlightPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.offset != offset;
  }
}
