import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class AuthLandscapeFooter extends StatelessWidget {
  const AuthLandscapeFooter({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      height: height + bottomInset,
      width: double.infinity,
      child: const CustomPaint(
        painter: SoftTreesPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class SoftTreesPainter extends CustomPainter {
  const SoftTreesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, sky);

    final ground = Paint()..color = const Color(0xFFD7E6DC);
    final groundPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.58,
        size.width * 0.7,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.76,
        size.width,
        size.height * 0.66,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPath, ground);

    void tree(double x, double baseY, double crownR, double trunkH) {
      final trunk = Paint()..color = const Color(0xFF9BB5A4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, baseY - trunkH / 2),
            width: 4,
            height: trunkH,
          ),
          const Radius.circular(2),
        ),
        trunk,
      );

      final light = Paint()..color = const Color(0xFFB7D0C2);
      final dark = Paint()..color = const Color(0xFF9FBEB0);
      canvas.drawCircle(
        Offset(x - crownR * 0.15, baseY - trunkH - crownR * 0.2),
        crownR,
        light,
      );
      canvas.drawCircle(
        Offset(x + crownR * 0.2, baseY - trunkH - crownR * 0.1),
        crownR * 0.85,
        dark,
      );
    }

    final base = size.height * 0.78;
    tree(size.width * 0.08, base, 18, 18);
    tree(size.width * 0.2, base, 26, 24);
    tree(size.width * 0.34, base, 20, 20);
    tree(size.width * 0.48, base, 28, 26);
    tree(size.width * 0.62, base, 22, 22);
    tree(size.width * 0.76, base, 30, 28);
    tree(size.width * 0.9, base, 24, 22);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
