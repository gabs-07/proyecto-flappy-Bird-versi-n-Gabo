class Bird {
  double y;
  double velocity;
  int animationFrame;
  int _animTick = 0;

  Bird({required this.y, required this.velocity}) : animationFrame = 0;

  void reset() {
    y = 0.0;
    velocity = 0.0;
    animationFrame = 0;
    _animTick = 0;
  }

  void applyGravity(double gravity) {
    velocity += gravity;
    // BUG 6 CORREGIDO: sin límite de velocidad el pájaro caía tan rápido
    // que atravesaba el suelo en un solo tick sin activar colisión (tunneling).
    if (velocity > 0.050) velocity = 0.050;
  }

  void jump(double jumpVelocity) {
    velocity = jumpVelocity;
  }

  void updatePosition() {
    y += velocity;
    if (y >= 1.0) {
      y = 1.0;
      velocity = 0.0;
    } else if (y <= -1.0) {
      y = -1.0;
      velocity = 0.0;
    }
  }

  void animate() {
    // Anima a ~12 fps (cada 5 ticks de 16ms ≈ 80ms por frame)
    _animTick++;
    if (_animTick >= 5) {
      _animTick = 0;
      animationFrame = (animationFrame + 1) % 3;
    }
  }

  double get rotation {
    // Rotación suave: -25° subiendo → +90° cayendo
    final double deg = velocity * 14.0;
    return deg.clamp(-1.2, 1.0); // radianes aprox.
  }
}
