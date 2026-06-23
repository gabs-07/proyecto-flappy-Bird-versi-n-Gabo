import 'dart:math';

class Coin {
  double x;
  double y;
  bool collected;
  double bobPhase; // oscilación vertical suave

  Coin({required this.x, required this.y, this.collected = false})
      : bobPhase = Random().nextDouble() * 3.14159 * 2;

  static const double radius = 0.032; // en espacio normalizado

  void update(double speed, int tick) {
    x -= speed;
    y += sin(bobPhase + tick * 0.06) * 0.0005; // bobbing sutil
  }
}
