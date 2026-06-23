import 'dart:math';

enum PowerUpType { shield, slowMo, doublePoints }

class PowerUpItem {
  final PowerUpType type;
  double x;
  double y;
  bool collected;
  double bobPhase;

  PowerUpItem({required this.type, required this.x, required this.y})
      : collected = false,
        bobPhase = Random().nextDouble() * 3.14159 * 2;

  static const double radius = 0.045;

  void update(double speed, int tick) {
    x -= speed;
    y += sin(bobPhase + tick * 0.05) * 0.0008;
  }

  String get icon {
    switch (type) {
      case PowerUpType.shield:       return '🛡';
      case PowerUpType.slowMo:       return '⏱';
      case PowerUpType.doublePoints: return '×2';
    }
  }

  String get label {
    switch (type) {
      case PowerUpType.shield:       return 'ESCUDO';
      case PowerUpType.slowMo:       return 'SLOW-MO';
      case PowerUpType.doublePoints: return 'X2 PUNTOS';
    }
  }
}
