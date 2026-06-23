import 'dart:math';
import 'dart:ui' show Rect;

import 'bird.dart';
import 'pipe.dart';
import 'obstacle.dart';

class GameLogic {
  // ── Física ───────────────────────────────────────────────────────────────────
  static const double baseGravity   = 0.00090;
  static const double gravityScale  = 0.000009;
  static const double jumpVelocity  = -0.038;

  // ── Velocidad de tubos ───────────────────────────────────────────────────────
  static const double basePipeSpeed = 0.0035;
  static const double speedIncrease = 0.0010;
  static const double pipeSpacing   = 0.92;

  // ── Gap ──────────────────────────────────────────────────────────────────────
  static const double minGapHeight  = 0.38;
  static const double maxGapHeight  = 0.52;

  // ── Dimensiones ──────────────────────────────────────────────────────────────
  static const double pipeWidthRatio = 0.13;
  static const double birdSizeRatio  = 0.075;
  static const double birdX          = -0.50;

  static final Random _random = Random();

  // ── Sistema de niveles ───────────────────────────────────────────────────────
  // Nivel sube cada 5 puntos: score 0-4 = lv0, 5-9 = lv1, 10-14 = lv2 ...
  static int levelFromScore(int score) => (score ~/ 5).clamp(0, 20);

  // CORREGIDO: modo noche activa a partir de score >= 5 (nivel 1+)
  // Antes pedía level >= 5, lo que requería score = 25. Ahora level >= 1.
  static bool isNightMode(int score) => levelFromScore(score) >= 1;

  // Velocidad extra por nivel nocturno (progresiva)
  static double nightSpeedBonus(int score) {
    final lvl = levelFromScore(score);
    if (lvl < 1) return 0.0;
    return (lvl - 1) * 0.00015;
  }

  // Tipos de obstáculos disponibles según nivel
  static int obstacleLevel(int score) => levelFromScore(score);

  // ── Generadores aleatorios ───────────────────────────────────────────────────
  static double randomGapY() => (_random.nextDouble() * 0.60) - 0.30;

  static double randomGapHeight(double difficulty) {
    final double target    = maxGapHeight - (maxGapHeight - minGapHeight) * difficulty.clamp(0, 1);
    final double variation = (_random.nextDouble() * 0.06) - 0.03;
    return (target + variation).clamp(minGapHeight, maxGapHeight);
  }

  // ── Escalado de dificultad ───────────────────────────────────────────────────
  static double currentSpeed(double difficulty) =>
      basePipeSpeed + (speedIncrease * difficulty.clamp(0, 1));

  static double currentGravity(double difficulty) =>
      baseGravity + (gravityScale * difficulty.clamp(0, 1));

  // ── Colisión tubos ───────────────────────────────────────────────────────────
  static bool checkCollision(Bird bird, List<Pipe> pipes) {
    const double hitboxFactor = 0.75;
    final double halfBird = birdSizeRatio * hitboxFactor / 2;
    final Rect birdBox = Rect.fromLTRB(
      birdX - halfBird, bird.y - halfBird,
      birdX + halfBird, bird.y + halfBird,
    );

    for (final pipe in pipes) {
      final double halfPipe  = pipeWidthRatio / 2;
      final double gapHalf   = pipe.gapHeight;
      final double pipeLeft  = pipe.x - halfPipe;
      final double pipeRight = pipe.x + halfPipe;
      final double gapTop    = pipe.gapY - gapHalf;
      final double gapBottom = pipe.gapY + gapHalf;

      final Rect topPipe    = Rect.fromLTRB(pipeLeft, -1.0, pipeRight, gapTop);
      final Rect bottomPipe = Rect.fromLTRB(pipeLeft, gapBottom, pipeRight, 1.0);

      if (birdBox.overlaps(topPipe) || birdBox.overlaps(bottomPipe)) return true;
    }
    return false;
  }

  // ── Colisión suelo/techo ────────────────────────────────────────────────────
  static bool checkGroundCollision(Bird bird) {
    const double hitboxFactor = 0.75;
    final double halfBird = birdSizeRatio * hitboxFactor / 2;
    // Si toca techo (y - halfBird <= -1.0) o piso (y + halfBird >= 1.0)
    return (bird.y - halfBird <= -1.0) || (bird.y + halfBird >= 1.0);
  }

  // ── Colisión obstáculos ──────────────────────────────────────────────────────
  static bool checkObstacleCollision(Bird bird, List<Obstacle> obstacles) {
    const double hitboxFactor = 0.75;
    final double halfBird = birdSizeRatio * hitboxFactor / 2;
    final double bx = birdX, by = bird.y;

    for (final obs in obstacles) {
      if (!obs.active) continue;

      if (obs.type == ObstacleType.laser) {
        final bounds = obs.laserBeamBounds;
        if (bounds == null) continue; // apagado → no hace daño
        final double obsLeft  = obs.x - 0.20;
        final double obsRight = obs.x + 0.20;
        final bool inX = (bx + halfBird) > obsLeft && (bx - halfBird) < obsRight;
        if (!inX) continue;
        final bool hitRay1 = (by - halfBird) < bounds[1] && (by + halfBird) > bounds[0];
        final bool hitRay2 = (by - halfBird) < bounds[3] && (by + halfBird) > bounds[2];
        if (hitRay1 || hitRay2) return true;
      } else {
        final double dx   = bx - obs.x;
        final double dy   = by - obs.y;
        final double dist = sqrt(dx * dx + dy * dy);
        if (dist < halfBird + obs.hitRadius) return true;
      }
    }
    return false;
  }
}
