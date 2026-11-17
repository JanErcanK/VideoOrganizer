import 'dart:math' as math;
import 'package:flutter/material.dart';

const ink = Color(0xff1e3029);
const pine = Color(0xff234B3D);
const muted = Color(0xff64736B);
const paper = Color(0xffF8F9F5);
const line = Color(0xffDCE2D9);
const folderColors = [
  Color(0xffB4CDB1),
  Color(0xffF0C29F),
  Color(0xffAFCADA),
  Color(0xffC7BBDF),
  Color(0xffE6D393),
];
const folderIcons = [
  Icons.fitness_center_rounded,
  Icons.restaurant_rounded,
  Icons.directions_run_rounded,
  Icons.lightbulb_outline_rounded,
  Icons.bookmark_outline_rounded,
];

TextStyle headline(double size) => TextStyle(
  color: ink,
  fontSize: size,
  fontWeight: FontWeight.w700,
  letterSpacing: -size * .045,
  height: 1.13,
);
ThemeData clipTheme() {
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: pine,
      primary: pine,
      surface: paper,
    ),
    scaffoldBackgroundColor: paper,
  );
  return theme.copyWith(
    textTheme: theme.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: pine,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xffD5E7D3),
      side: const BorderSide(color: line),
      shape: const StadiumBorder(),
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: pine,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.video_library_rounded,
          color: Color(0xffDFEDC7),
          size: 20,
        ),
      ),
      const SizedBox(width: 9),
      Text('Clipfolio', style: headline(22)),
    ],
  );
}

class FolderGlyph extends StatelessWidget {
  const FolderGlyph(this.index, {super.key});
  final int index;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70,
    height: 52,
    child: CustomPaint(
      painter: _FolderPainter(folderColors[index % folderColors.length]),
      child: Align(
        alignment: const Alignment(-.27, .37),
        child: Icon(
          folderIcons[index < 4 ? index : 4],
          color: ink.withValues(alpha: .64),
          size: 16,
        ),
      ),
    ),
  );
}

class _FolderPainter extends CustomPainter {
  _FolderPainter(this.tint);
  final Color tint;
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 70, s.height / 52);
    final p = Paint();
    final back = Path()
      ..moveTo(4, 44)
      ..lineTo(4, 12)
      ..quadraticBezierTo(4, 7, 9, 7)
      ..lineTo(24, 7)
      ..lineTo(29, 12)
      ..lineTo(58, 12)
      ..quadraticBezierTo(64, 12, 64, 18)
      ..lineTo(64, 44)
      ..close();
    c.drawPath(back, p..color = Color.lerp(tint, ink, .24)!);
    c.save();
    c.rotate(-.045);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 17, 51, 25),
        const Radius.circular(3),
      ),
      p..color = Colors.white,
    );
    c.restore();
    final front = Path()
      ..moveTo(4, 18)
      ..quadraticBezierTo(6, 16, 10, 17)
      ..lineTo(62, 17)
      ..quadraticBezierTo(67, 17, 66, 22)
      ..lineTo(63, 42)
      ..quadraticBezierTo(62, 47, 57, 47)
      ..lineTo(11, 47)
      ..quadraticBezierTo(6, 47, 5, 42)
      ..close();
    c.drawShadow(front, ink.withValues(alpha: .22), 2, false);
    c.drawPath(front, p..color = tint);
  }

  @override
  bool shouldRepaint(_FolderPainter old) => old.tint != tint;
}

// Staggered film cards are drawn at the available resolution.
class ArchiveArt extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 220, size.height / 160);
    final p = Paint()..isAntiAlias = true;
    void card(double x, double y, double angle, Color color, bool front) {
      c.save();
      c.translate(x, y);
      c.rotate(angle * math.pi / 180);
      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-49, -55, 98, 110),
        const Radius.circular(8),
      );
      c.drawShadow(
        Path()..addRRect(rect),
        Colors.black.withValues(alpha: .6),
        6,
        true,
      );
      c.drawRRect(rect, p..color = color);
      if (front) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-40, -45, 80, 71),
            const Radius.circular(4),
          ),
          p..color = const Color(0xff43705A),
        );
        c.save();
        c.clipRect(const Rect.fromLTWH(-40, -45, 80, 71));
        for (var i = 0; i < 12; i++) {
          final path = Path()
            ..moveTo(-65, 15 + i * 6)
            ..cubicTo(-19, -70 + i * 6, 2, 40 + i * 6, 66, -34 + i * 6);
          c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .9
              ..color = const Color(0xff8DAE7E),
          );
        }
        c.restore();
        c.drawCircle(
          const Offset(0, -9),
          16,
          p..color = const Color(0xffE8F2D3),
        );
        c.drawPath(
          Path()
            ..moveTo(-4, -16)
            ..lineTo(7, -9)
            ..lineTo(-4, -2)
            ..close(),
          p..color = pine,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-38, 37, 39, 3),
            const Radius.circular(2),
          ),
          p..color = const Color(0xff7C8B70),
        );
        c.drawCircle(
          const Offset(36, 39),
          3,
          p..color = const Color(0xff7C8B70),
        );
      } else {
        for (var i = 0; i < 5; i++) {
          c.drawCircle(
            Offset(-34 + i * 17, -42),
            2,
            p..color = ink.withValues(alpha: .35),
          );
        }
      }
      c.restore();
    }

    card(103, 75, -20, const Color(0xff98AE88), false);
    card(149, 89, 21, const Color(0xffA8C6B8), false);
    card(123, 86, -6, const Color(0xffE6EDD3), true);
  }

  @override
  bool shouldRepaint(ArchiveArt old) => false;
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: headline(23))),
      ?action,
    ],
  );
}
