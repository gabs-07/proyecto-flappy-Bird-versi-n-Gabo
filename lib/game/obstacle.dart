import 'dart:math';

enum ObstacleType { meteor, bat, laser, ufo, ghost }

class Obstacle {
  ObstacleType type;
  double x, y, vx, vy, phase, rotation;
  bool active, scored, laserOn;
  double laserTimer;

  static const double laserOnDur  = 1.5;
  static const double laserOffDur = 0.8;

  Obstacle({
    required this.type,
    required this.x,
    required this.y,
    required this.vx,
    this.vy        = 0.0,
    this.phase     = 0.0,
    this.rotation  = 0.0,
    this.active    = true,
    this.scored    = false,
    this.laserOn   = true,
    this.laserTimer= 0.0,
  });

  static final Random _rng = Random();

  factory Obstacle.random(int level) {
    // CORREGIDO: niveles de desbloqueo más bajos para que se vean desde el principio
    // nivel 1 → solo meteor y bat
    // nivel 2 → + laser
    // nivel 3 → + ufo
    // nivel 5 → + ghost
    final types = _availableTypes(level);
    final type  = types[_rng.nextInt(types.length)];
    final startX = 1.3 + _rng.nextDouble() * 0.4;

    switch (type) {
      case ObstacleType.meteor:
        return Obstacle(
          type: type, x: startX,
          y: -1.0 + _rng.nextDouble() * 0.5,
          vx: -(0.006 + _rng.nextDouble() * 0.004),
          vy:  0.003 + _rng.nextDouble() * 0.002,
        );
      case ObstacleType.bat:
        return Obstacle(
          type: type, x: startX,
          y: -0.5 + _rng.nextDouble() * 0.8,
          vx: -(0.004 + _rng.nextDouble() * 0.003),
          phase: _rng.nextDouble() * pi * 2,
        );
      case ObstacleType.laser:
        return Obstacle(
          type: type, x: startX,
          y: -0.4 + _rng.nextDouble() * 0.5,
          vx: -(0.003 + _rng.nextDouble() * 0.002),
          laserOn: true, laserTimer: 0.0,
        );
      case ObstacleType.ufo:
        return Obstacle(
          type: type, x: startX,
          y: -0.6 + _rng.nextDouble() * 0.4,
          vx: -(0.0025 + _rng.nextDouble() * 0.0015),
          phase: _rng.nextDouble() * pi * 2,
        );
      case ObstacleType.ghost:
        return Obstacle(
          type: type, x: startX,
          y: -0.3 + _rng.nextDouble() * 0.6,
          vx: -(0.005 + _rng.nextDouble() * 0.003),
          phase: _rng.nextDouble() * pi * 2,
        );
    }
  }

  static List<ObstacleType> _availableTypes(int level) {
    // Desbloqueo progresivo desde nivel 1
    if (level >= 5) return ObstacleType.values;
    if (level >= 3) return [ObstacleType.meteor, ObstacleType.bat, ObstacleType.laser, ObstacleType.ufo];
    if (level >= 2) return [ObstacleType.meteor, ObstacleType.bat, ObstacleType.laser];
    return             [ObstacleType.meteor, ObstacleType.bat];
  }

  void update(double dt, int tick) {
    switch (type) {
      case ObstacleType.meteor:
        x += vx; y += vy; rotation += 0.03;
        if (y > 1.2) active = false;
      case ObstacleType.bat:
        x += vx;
        y += sin(phase + tick * 0.04) * 0.004;
      case ObstacleType.laser:
        x += vx;
        laserTimer += dt;
        if (laserOn  && laserTimer >= laserOnDur)  { laserOn = false; laserTimer = 0.0; }
        if (!laserOn && laserTimer >= laserOffDur)  { laserOn = true;  laserTimer = 0.0; }
      case ObstacleType.ufo:
        x += vx;
        y += sin(phase + tick * 0.02) * 0.0018;
      case ObstacleType.ghost:
        x += vx;
        y += sin(phase + tick * 0.05) * 0.003;
    }
    if (x < -1.6) active = false;
  }

  double get hitRadius {
    switch (type) {
      case ObstacleType.meteor: return 0.07;
      case ObstacleType.bat:    return 0.06;
      case ObstacleType.laser:  return 0.0;
      case ObstacleType.ufo:    return 0.08;
      case ObstacleType.ghost:  return 0.05;
    }
  }

  List<double>? get laserBeamBounds {
    if (type != ObstacleType.laser || !laserOn) return null;
    return [y - 0.26, y - 0.09, y + 0.09, y + 0.26];
  }
}
