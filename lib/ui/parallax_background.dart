// ============================================================
// ui/parallax_background.dart
// Parallax de 3 capas independientes:
//   Capa 1 (más lenta) — montañas o silueta de ciudad al fondo
//   Capa 2 (media)     — nubes
//   Capa 3 (rápida)    — arbustos/rocas en primer plano
// Cada capa tiene su propia velocidad relativa al scroll del suelo.
// ============================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Datos de un elemento de parallax
class _ParallaxItem {
  final double x;      // posición X [0..1] dentro del tile
  final double y;      // posición Y [0..1] dentro de la capa
  final double scale;  // tamaño relativo
  const _ParallaxItem(this.x, this.y, this.scale);
}

class ParallaxBackground extends StatelessWidget {
  final double scrollOffset; // valor de groundScroll del provider [0..1]
  final double blend;        // 0=día 1=noche

  const ParallaxBackground({
    super.key,
    required this.scrollOffset,
    required this.blend,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParallaxPainter(scrollOffset, blend),
      child: const SizedBox.expand(),
    );
  }
}

class _ParallaxPainter extends CustomPainter {
  final double scroll;
  final double blend;

  _ParallaxPainter(this.scroll, this.blend);

  // ── Capa 1: Montañas (vel 0.15× del suelo) ───────────────
  static const _mountains = [
    _ParallaxItem(0.05, 1.0, 1.2),
    _ParallaxItem(0.28, 1.0, 0.9),
    _ParallaxItem(0.50, 1.0, 1.4),
    _ParallaxItem(0.72, 1.0, 1.0),
    _ParallaxItem(0.90, 1.0, 1.1),
  ];

  // ── Capa 2: Nubes medias (vel 0.35×) ─────────────────────
  static const _midClouds = [
    _ParallaxItem(0.10, 0.20, 0.8),
    _ParallaxItem(0.38, 0.28, 0.6),
    _ParallaxItem(0.62, 0.18, 0.9),
    _ParallaxItem(0.84, 0.24, 0.7),
  ];

  // ── Capa 3: Arbustos primer plano (vel 0.90×) ─────────────
  static const _bushes = [
    _ParallaxItem(0.08, 1.0, 0.7),
    _ParallaxItem(0.25, 1.0, 0.5),
    _ParallaxItem(0.44, 1.0, 0.8),
    _ParallaxItem(0.63, 1.0, 0.6),
    _ParallaxItem(0.80, 1.0, 0.7),
    _ParallaxItem(0.95, 1.0, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawLayer1(canvas, size);  // montañas
    _drawLayer2(canvas, size);  // nubes medias
    _drawLayer3(canvas, size);  // arbustos
  }

  // ── CAPA 1: Montañas ──────────────────────────────────────
  void _drawLayer1(Canvas canvas, Size size) {
    final mtnDay   = const Color(0xFF8BCACC);
    final mtnNight = const Color(0xFF0A1428);
    final color = Color.lerp(mtnDay, mtnNight, blend)!.withOpacity(0.55 + blend * 0.15);
    final paint = Paint()..color = color;
    final speed = scroll * size.width * 0.15;

    for (final m in _mountains) {
      // Tile: los elementos se repiten desplazados
      for (int tile = -1; tile <= 1; tile++) {
        final x = ((m.x + tile) * size.width - speed % size.width);
        final h = size.height * 0.45 * m.scale;
        final base = size.height * 0.62; // base de la montaña

        // Triángulo con pico redondeado aproximado
        final path = Path()
          ..moveTo(x - h * 0.55, base)
          ..quadraticBezierTo(x - h * 0.1, base - h * 0.5, x, base - h)
          ..quadraticBezierTo(x + h * 0.1, base - h * 0.5, x + h * 0.55, base)
          ..close();
        canvas.drawPath(path, paint);

        // Nieve en el pico (solo de día)
        if (blend < 0.7) {
          final snowPaint = Paint()..color = Colors.white.withOpacity(0.4 * (1 - blend));
          final snow = Path()
            ..moveTo(x - h * 0.12, base - h * 0.78)
            ..quadraticBezierTo(x, base - h, x + h * 0.12, base - h * 0.78)
            ..close();
          canvas.drawPath(snow, snowPaint);
        }

        // Brillo lunar en las montañas de noche
        if (blend > 0.3) {
          final lunarPaint = Paint()
            ..color = const Color(0xFFF5E87A).withOpacity(0.06 * blend);
          final lunar = Path()
            ..moveTo(x, base - h)
            ..lineTo(x + h * 0.1, base - h * 0.8)
            ..lineTo(x - h * 0.05, base - h * 0.6)
            ..close();
          canvas.drawPath(lunar, lunarPaint);
        }
      }
    }
  }

  // ── CAPA 2: Nubes medias ──────────────────────────────────
  void _drawLayer2(Canvas canvas, Size size) {
    final cloudDay   = Colors.white.withOpacity(0.60);
    final cloudNight = const Color(0xFF1A2858).withOpacity(0.50);
    final color = Color.lerp(cloudDay, cloudNight, blend)!;
    final paint = Paint()..color = color;
    final speed = scroll * size.width * 0.35;

    for (final c in _midClouds) {
      for (int tile = -1; tile <= 1; tile++) {
        final x = ((c.x + tile) * size.width - speed % size.width);
        final y = size.height * c.y * 0.55;
        final r = c.scale * size.width * 0.055;
        _drawCloud(canvas, paint, Offset(x, y), r);
      }
    }
  }

  void _drawCloud(Canvas canvas, Paint p, Offset center, double r) {
    canvas.drawOval(Rect.fromCenter(center: center, width: r*2.4, height: r*1.2), p);
    canvas.drawCircle(Offset(center.dx - r*0.75, center.dy + r*0.1), r*0.78, p);
    canvas.drawCircle(Offset(center.dx + r*0.75, center.dy + r*0.1), r*0.72, p);
  }

  // ── CAPA 3: Arbustos primer plano ────────────────────────
  void _drawLayer3(Canvas canvas, Size size) {
    final bushDay   = const Color(0xFF3A7A18);
    final bushNight = const Color(0xFF0A2008);
    final color = Color.lerp(bushDay, bushNight, blend)!.withOpacity(0.85);
    final paint = Paint()..color = color;
    final speed = scroll * size.width * 0.90;
    final baseY = size.height * 0.88;

    for (final b in _bushes) {
      for (int tile = -1; tile <= 1; tile++) {
        final x = ((b.x + tile) * size.width - speed % size.width);
        final r = b.scale * size.width * 0.038;

        // Arbusto = 3 círculos solapados
        canvas.drawCircle(Offset(x, baseY - r * 0.5), r, paint);
        canvas.drawCircle(Offset(x - r * 0.85, baseY - r * 0.15), r * 0.8, paint);
        canvas.drawCircle(Offset(x + r * 0.85, baseY - r * 0.15), r * 0.75, paint);

        // Brillo superior del arbusto
        final brightPaint = Paint()
          ..color = Color.lerp(
            const Color(0xFF5AA828),
            const Color(0xFF143010),
            blend,
          )!.withOpacity(0.7);
        canvas.drawCircle(Offset(x - r * 0.1, baseY - r * 0.65), r * 0.55, brightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParallaxPainter o) =>
      o.scroll != scroll || o.blend != blend;
}
