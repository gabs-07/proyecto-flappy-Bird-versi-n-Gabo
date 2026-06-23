import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
import '../game/obstacle.dart';
import '../game/pipe.dart';
import '../game/coin.dart';
import '../game/powerup_item.dart';
import '../game/skin.dart';
import '../providers/game_provider.dart';
import 'achievement_toast.dart';
import 'game_over_screen.dart';
import 'intro_animation.dart';
import 'parallax_background.dart';
import 'start_screen.dart';

const double kGroundH = 72.0;
const double kTopBarH = 60.0;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _cloudCtrl;

  @override
  void initState() {
    super.initState();
    _cloudCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 60))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() { _cloudCtrl.dispose(); _focusNode.dispose(); super.dispose(); }

  void _key(RawKeyEvent e, GameProvider g) {
    if (e is! RawKeyDownEvent) return;
    if (e.logicalKey == LogicalKeyboardKey.space ||
        e.logicalKey == LogicalKeyboardKey.arrowUp) g.jump();
    if (e.logicalKey == LogicalKeyboardKey.keyP) g.togglePause();
    if (e.logicalKey == LogicalKeyboardKey.keyM) g.toggleSound();
  }

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameProvider>();
    final blend = game.nightBlend;
    final shake = game.shakeAmount > 0
        ? Offset(math.sin(game.shakeAmount * math.pi * 8) * 6 * game.shakeAmount, 0)
        : Offset.zero;

    // ── Envolver todo en la animación de intro (solo primera vez) ──
    return IntroAnimation(
      // Una vez jugada la intro, no la repetimos
      key: const ValueKey('intro'),
      child: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (e) => _key(e, game),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: game.jump,
          child: Transform.translate(
            offset: shake,
            child: LayoutBuilder(builder: (ctx, cst) {
              final W = cst.maxWidth, H = cst.maxHeight;
              final playH = H - kTopBarH - kGroundH;

              return Stack(children: [
                // ── CAPA 1: Cielo con degradado (ya existente) ──────────────
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _cloudCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _SkyPainter(blend, _cloudCtrl.value),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // ── CAPA 2: Parallax 3 capas (montañas, nubes, arbustos) ────
                Positioned(
                  left: 0, right: 0,
                  top: kTopBarH,
                  height: playH,
                  child: ParallaxBackground(
                    scrollOffset: game.groundScroll,
                    blend: blend,
                  ),
                ),

                // ── CAPA 3: Suelo animado ───────────────────────────────────
                Positioned(left:0, right:0, bottom:0, height:kGroundH,
                  child: _Ground(scroll: game.groundScroll, W: W, blend: blend)),

                // ── CAPA 4: Área de juego ───────────────────────────────────
                Positioned(left:0, right:0, top:kTopBarH, height:playH,
                  child: ClipRect(child: Stack(clipBehavior: Clip.hardEdge, children: [
                    // Tubos
                    for (final p in game.pipes)
                      _PipeWidget(pipe: p, W: W, H: playH, isNight: game.isNight),
                    // Obstáculos
                    if (game.isNight)
                      for (final o in game.obstacles)
                        if (o.active) _ObstacleWidget(obs: o, W: W, H: playH),
                    // Monedas
                    for (final c in game.coins)
                      if (!c.collected) _CoinWidget(coin: c, W: W, H: playH),
                    // Power-up items
                    for (final p in game.powerUpItems)
                      if (!p.collected) _PowerUpWidget(item: p, W: W, H: playH),
                    // Pájaro
                    _BirdWidget(game: game, W: W, H: playH),
                    // Score con pop + contador animado
                    if (game.state == GameState.playing)
                      Positioned(left:0, right:0, top: playH * 0.06,
                        child: _ScoreDisplay(game: game)),
                    // Monedas sesión
                    if (game.state == GameState.playing)
                      Positioned(left: 12, top: 8,
                        child: _SessionCoins(count: game.sessionCoins)),
                    // Toast logro
                    if (game.pendingToasts.isNotEmpty)
                      Positioned(top: 12, left: 0, right: 0,
                        child: Center(
                          child: AchievementToast(
                            key: ValueKey(game.pendingToasts.first.id)))),
                  ]))),

                // ── CAPA 5: HUD ─────────────────────────────────────────────
                Positioned(left:0, right:0, top:0, height:kTopBarH,
                  child: _TopBar(game: game)),

                // Badge nivel noche
                if (game.state == GameState.playing && game.isNight)
                  Positioned(right:12, top:kTopBarH+8,
                    child: _LevelBadge(level: game.level)),

                // Indicadores power-ups
                if (game.state == GameState.playing)
                  Positioned(left:0, right:0, bottom:kGroundH+8,
                    child: _PowerUpIndicators(game: game)),

                // Overlays
                if (game.state == GameState.start)
                  const Positioned.fill(child: StartScreen()),
                if (game.state == GameState.gameOver)
                  const Positioned.fill(child: GameOverScreen()),
                if (game.isPaused && game.state == GameState.playing)
                  const Positioned.fill(child: _PauseOverlay()),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CIELO (separado de parallax para que las nubes lentas
// estén en la capa del cielo y las montañas encima)
// ─────────────────────────────────────────────────────────────
Color _blendColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

class _SkyPainter extends CustomPainter {
  final double blend, cloudT;
  _SkyPainter(this.blend, this.cloudT);

  static const _dT = Color(0xFF38B8C8), _dB = Color(0xFFB8EAF0);
  static const _nT = Color(0xFF050A1E), _nB = Color(0xFF1A2A5E);

  @override
  void paint(Canvas canvas, Size size) {
    // Degradado base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [_blendColor(_dT,_nT,blend), _blendColor(_dB,_nB,blend)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    if (blend < 0.95) _drawDay(canvas, size);
    if (blend > 0.05) _drawNight(canvas, size, blend);
  }

  void _drawDay(Canvas canvas, Size size) {
    final op = 1.0 - blend;
    // Sol con rayos
    final cx = size.width * 0.82, cy = size.height * 0.13;
    canvas.drawCircle(Offset(cx, cy), 36,
      Paint()..color = const Color(0xFFFFF176).withOpacity(0.85 * op));
    canvas.drawCircle(Offset(cx, cy), 26,
      Paint()..color = const Color(0xFFFFEE58).withOpacity(op));
    // Rayos del sol
    if (op > 0.3) {
      final rayP = Paint()
        ..color = const Color(0xFFFFF176).withOpacity(0.25 * op)
        ..strokeWidth = 2;
      for (int i = 0; i < 8; i++) {
        final ang = i * math.pi / 4;
        final x1 = cx + math.cos(ang) * 38, y1 = cy + math.sin(ang) * 38;
        final x2 = cx + math.cos(ang) * 54, y2 = cy + math.sin(ang) * 54;
        canvas.drawLine(Offset(x1,y1), Offset(x2,y2), rayP);
      }
    }
    // Nubes frontales lentas
    final cp = Paint()..color = Colors.white.withOpacity(0.88 * op);
    for (final (rx,ry,sc) in [
      (0.12,0.12,1.0),(0.47,0.18,0.75),(0.74,0.08,0.85),(0.30,0.26,0.60),(0.90,0.20,0.70)
    ]) {
      final dx = ((rx + cloudT * 0.15) % 1.2 - 0.1) * size.width;
      final r  = sc * size.width * 0.065;
      _cloud(canvas, cp, Offset(dx, ry * size.height * 0.7), r);
    }
  }

  void _drawNight(Canvas canvas, Size size, double op) {
    // Estrellas con centelleo
    final sp = Paint()..color = Colors.white.withOpacity(op);
    final stars = [
      (0.08,0.06,1.2),(0.22,0.10,0.8),(0.38,0.04,1.0),(0.55,0.08,0.9),
      (0.70,0.05,1.1),(0.85,0.12,0.7),(0.95,0.07,1.0),(0.15,0.18,0.8),
      (0.42,0.16,0.7),(0.62,0.14,0.9),(0.78,0.20,0.8),(0.30,0.22,0.6),
      (0.50,0.24,0.7),(0.88,0.26,0.9),(0.10,0.30,0.5),(0.65,0.28,0.6),
    ];
    for (final (rx,ry,sr) in stars) {
      // Centelleo: varía el radio con el tiempo
      final twinkle = 0.8 + 0.4 * math.sin(cloudT * 12 + rx * 17);
      canvas.drawCircle(
        Offset(rx * size.width, ry * size.height * 0.75),
        sr * op * twinkle, sp);
    }
    // Luna creciente
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.16), 30,
      Paint()..color = const Color(0xFFF5E87A).withOpacity(0.92 * op));
    canvas.drawCircle(Offset(size.width * 0.83, size.height * 0.14), 24,
      Paint()..color = _blendColor(_dT, _nT, blend));
    // Halo de la luna
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.16), 38,
      Paint()..color = const Color(0xFFF5E87A).withOpacity(0.08 * op));
  }

  void _cloud(Canvas canvas, Paint p, Offset c, double r) {
    canvas.drawOval(Rect.fromCenter(center: c, width: r*2.6, height: r*1.4), p);
    canvas.drawCircle(Offset(c.dx - r*0.8, c.dy + r*0.1), r*0.82, p);
    canvas.drawCircle(Offset(c.dx + r*0.8, c.dy + r*0.1), r*0.78, p);
  }

  @override
  bool shouldRepaint(_SkyPainter o) => o.blend != blend || o.cloudT != cloudT;
}

// ─────────────────────────────────────────────────────────────
// SCORE — pop animation + número grande con sombra dinámica
// ─────────────────────────────────────────────────────────────
class _ScoreDisplay extends StatefulWidget {
  final GameProvider game;
  const _ScoreDisplay({required this.game});
  @override
  State<_ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<_ScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<Color?> _color;
  int _lastScore = -1;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin:1.0, end:1.40), weight: 35),
      TweenSequenceItem(tween: Tween(begin:1.40, end:0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin:0.95, end:1.00), weight: 35),
    ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _color = ColorTween(begin: Colors.white, end: const Color(0xFFFFD700))
        .animate(CurvedAnimation(parent: _c, curve: const Interval(0,0.5)));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final score = widget.game.score;
    if (score != _lastScore) {
      _lastScore = score;
      _c.forward(from: 0);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final nightColor = const Color(0xFFF5E87A);
        final baseColor  = widget.game.isNight ? nightColor : Colors.white;
        final goldColor  = const Color(0xFFFFD700);
        final dispColor  = widget.game.doublePointsActive ? goldColor : (_color.value ?? baseColor);

        return Center(child: ScaleTransition(
          scale: _scale,
          child: Stack(alignment: Alignment.center, children: [
            // Sombra del número (desplazada)
            Text('$score', style: TextStyle(
              fontSize: 76, fontWeight: FontWeight.w900,
              foreground: Paint()
                ..color = Colors.black.withOpacity(0.35)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
              shadows: const [],
            )),
            // Número principal
            Text('$score', style: TextStyle(
              fontSize: 76, fontWeight: FontWeight.w900,
              color: dispColor,
              shadows: [
                Shadow(offset: const Offset(0,3), blurRadius:6,
                  color: Colors.black.withOpacity(0.5)),
                Shadow(offset: const Offset(0,0), blurRadius:12,
                  color: dispColor.withOpacity(0.3)),
              ],
            )),
          ]),
        ));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUELO
// ─────────────────────────────────────────────────────────────
class _Ground extends StatelessWidget {
  final double scroll, W, blend;
  const _Ground({required this.scroll, required this.W, required this.blend});
  @override
  Widget build(BuildContext context) =>
    CustomPaint(painter: _GroundPainter(scroll, W, blend), child: const SizedBox.expand());
}

class _GroundPainter extends CustomPainter {
  final double scroll, W, blend;
  _GroundPainter(this.scroll, this.W, this.blend);
  @override
  void paint(Canvas canvas, Size size) {
    final gc = Color.lerp(const Color(0xFF5D9E3B), const Color(0xFF122B0C), blend)!;
    final dc = Color.lerp(const Color(0xFFDEB887), const Color(0xFF3E2510), blend)!;
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,24), Paint()..color=gc);
    canvas.drawRect(Rect.fromLTWH(0,24,size.width,size.height-24), Paint()..color=dc);
    final bc = Color.lerp(const Color(0xFF3A7020), const Color(0xFF0A300A), blend)!;
    final bp = Paint()..color=bc..strokeWidth=2..strokeCap=StrokeCap.round;
    const sp = 18.0; final off = (scroll*W*sp)%(sp*2);
    for (double x = -(off%sp); x < size.width+sp; x+=sp)
      canvas.drawLine(Offset(x,2), Offset(x-4,20), bp);
    final sc2 = Color.lerp(const Color(0xFFC4A464), const Color(0xFF4A2D14), blend)!.withOpacity(0.55);
    const sw = 48.0; final soff = (scroll*W*sw*2)%(sw*2);
    for (double x = -sw*2+soff; x < size.width+sw; x+=sw*2)
      canvas.drawRect(Rect.fromLTWH(x,24,sw,size.height-24), Paint()..color=sc2);
    if (blend > 0.3) {
      final gp = Paint()..color=const Color(0xFF88FF44).withOpacity(0.85*blend);
      final gw = Paint()..color=const Color(0xFF88FF44).withOpacity(0.20*blend);
      for (final gx in [0.15,0.35,0.55,0.78,0.92]) {
        final fx = (gx+scroll*0.3)%1.0*size.width;
        canvas.drawCircle(Offset(fx,14),5,gw); canvas.drawCircle(Offset(fx,14),2,gp);
      }
    }
    canvas.drawLine(Offset.zero, Offset(size.width,0),
      Paint()..color=Colors.black.withOpacity(0.3)..strokeWidth=2);
  }
  @override bool shouldRepaint(_GroundPainter o) => o.scroll!=scroll||o.blend!=blend;
}

// ─────────────────────────────────────────────────────────────
// TUBO
// ─────────────────────────────────────────────────────────────
class _PipeWidget extends StatelessWidget {
  final Pipe pipe; final double W, H; final bool isNight;
  const _PipeWidget({required this.pipe, required this.W, required this.H, required this.isNight});
  @override
  Widget build(BuildContext context) {
    final pW   = W * (GameLogic.pipeWidthRatio / 2);
    final cY   = (pipe.gapY + 1) / 2 * H;
    final hG   = (pipe.gapHeight / 2) * H;
    final topH = (cY - hG).clamp(0.0, H);
    final botH = (H - (cY + hG)).clamp(0.0, H);
    final left = (pipe.x + 1) / 2 * W - pW / 2;
    final capH = (pW * 0.40).clamp(0.0, topH);
    final pref = isNight ? 'night/' : '';
    final topI = 'assets/images/${pref}pipe_top${isNight?"_night":""}.png';
    final botI = 'assets/images/${pref}pipe_bottom${isNight?"_night":""}.png';
    final capI = 'assets/images/pipe_cap.png';
    final capC  = isNight ? const Color(0xFF234E23) : const Color(0xFF52C22A);
    final bodyC = isNight ? const Color(0xFF1A3A1A) : const Color(0xFF3A8E1C);
    Widget im(String path, double w, double h, Color fb) =>
      Image.asset(path, width:w, height:h, fit:BoxFit.fill,
        errorBuilder:(_,__,___)=>Container(color:fb));
    return Positioned(left:left, top:0, child:SizedBox(width:pW, height:H,
      child:Column(children:[
        SizedBox(height:(topH-capH).clamp(0.0,H), child:im(topI,pW,topH-capH,bodyC)),
        if(capH>0) SizedBox(height:capH, child:im(capI,pW*1.12,capH,capC)),
        SizedBox(height:hG*2),
        if(capH>0) SizedBox(height:capH, child:im(capI,pW*1.12,capH,capC)),
        SizedBox(height:(botH-capH).clamp(0.0,H), child:im(botI,pW,botH-capH,bodyC)),
      ])));
  }
}

// ─────────────────────────────────────────────────────────────
// PÁJARO con skin + aura de escudo
// ─────────────────────────────────────────────────────────────
class _BirdWidget extends StatelessWidget {
  final GameProvider game; final double W, H;
  const _BirdWidget({required this.game, required this.W, required this.H});
  @override
  Widget build(BuildContext context) {
    final sz = H * GameLogic.birdSizeRatio;
    final bx = (GameLogic.birdX + 1) / 2 * W;
    final by = (game.bird.y + 1) / 2 * H;
    final bool isDead = game.state == GameState.gameOver;
    final skin = game.currentSkin;
    return Positioned(left: bx - sz/2, top: by - sz/2,
      child: Stack(alignment: Alignment.center, children: [
        if (game.shieldActive)
          Container(width: sz*1.5, height: sz*1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4488FF).withOpacity(0.7), width: 2.5),
              color: const Color(0xFF4488FF).withOpacity(0.14))),
        Transform.rotate(
          angle: game.bird.rotation,
          child: SizedBox(width: sz, height: sz,
            child: CustomPaint(
              painter: _SkinBirdPainter(skin: skin, frame: game.bird.animationFrame, dead: isDead)))),
      ]));
  }
}

class _SkinBirdPainter extends CustomPainter {
  final Skin skin; final int frame; final bool dead;
  _SkinBirdPainter({required this.skin, required this.frame, required this.dead});
  static const _wingY = [-0.55, -0.30, -0.05, 0.22];
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width/2, cy = size.height/2, r = size.width * 0.46;
    canvas.drawOval(Rect.fromCenter(center:Offset(cx+2,cy+r*0.85), width:r*2.2, height:r*0.5),
      Paint()..color=Colors.black.withOpacity(0.18));
    final wy = _wingY[frame % 4];
    final wp = Path()
      ..moveTo(cx-r*0.30,cy)
      ..quadraticBezierTo(cx-r*1.20,cy+wy*r,cx-r*0.70,cy+r*0.05)..close();
    canvas.drawPath(wp, Paint()..color=Color(skin.wingColor));
    canvas.drawPath(wp, Paint()..color=Color(skin.wingColor).withOpacity(0.5)..style=PaintingStyle.stroke..strokeWidth=1.2);
    canvas.drawCircle(Offset(cx,cy), r, Paint()..color=Color(skin.bodyColor));
    canvas.drawCircle(Offset(cx,cy), r, Paint()..color=Color(skin.wingColor)..style=PaintingStyle.stroke..strokeWidth=1.5);
    canvas.drawOval(Rect.fromCenter(center:Offset(cx+r*0.10,cy+r*0.18), width:r*1.1, height:r*0.85),
      Paint()..color=Color(skin.bodyColor).withOpacity(0.4));
    canvas.drawCircle(Offset(cx+r*0.35,cy-r*0.22), r*0.36, Paint()..color=Colors.white);
    if (dead) {
      final xp = Paint()..color=Colors.red..strokeWidth=2.5..strokeCap=StrokeCap.round;
      canvas.drawLine(Offset(cx+r*0.18,cy-r*0.38),Offset(cx+r*0.52,cy-r*0.06),xp);
      canvas.drawLine(Offset(cx+r*0.52,cy-r*0.38),Offset(cx+r*0.18,cy-r*0.06),xp);
    } else {
      canvas.drawCircle(Offset(cx+r*0.44,cy-r*0.16), r*0.20, Paint()..color=Colors.black);
      canvas.drawCircle(Offset(cx+r*0.50,cy-r*0.26), r*0.09, Paint()..color=Colors.white);
    }
    final bp = Path()
      ..moveTo(cx+r*0.62,cy-r*0.08)..lineTo(cx+r*1.15,cy+r*0.04)..lineTo(cx+r*0.62,cy+r*0.22)..close();
    canvas.drawPath(bp, Paint()..color=Color(skin.beakColor));
  }
  @override bool shouldRepaint(_SkinBirdPainter o) =>
    o.frame!=frame||o.dead!=dead||o.skin.id!=skin.id;
}

// ─────────────────────────────────────────────────────────────
// MONEDA, POWER-UP ITEM, OBSTÁCULOS (iguales a versión anterior)
// ─────────────────────────────────────────────────────────────
class _CoinWidget extends StatelessWidget {
  final Coin coin; final double W, H;
  const _CoinWidget({required this.coin, required this.W, required this.H});
  @override
  Widget build(BuildContext context) {
    const sz = 22.0;
    final cx = (coin.x+1)/2*W, cy = (coin.y+1)/2*H;
    return Positioned(left:cx-sz/2, top:cy-sz/2,
      child: Container(width:sz, height:sz,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: const Color(0xFFFFD700),
          border: Border.all(color: const Color(0xFFCC8800), width:2),
          boxShadow:[BoxShadow(color:const Color(0xFFFFD700).withOpacity(0.4),blurRadius:6)]),
        child: const Center(child:Text('\$',style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:Color(0xFF7A4A00))))));
  }
}

class _PowerUpWidget extends StatelessWidget {
  final PowerUpItem item; final double W, H;
  const _PowerUpWidget({required this.item, required this.W, required this.H});
  static const _colors = {
    PowerUpType.shield:       Color(0xFF4488FF),
    PowerUpType.slowMo:       Color(0xFFAA44FF),
    PowerUpType.doublePoints: Color(0xFFFFD700),
  };
  @override
  Widget build(BuildContext context) {
    const sz = 34.0;
    final cx=(item.x+1)/2*W, cy=(item.y+1)/2*H;
    final col=_colors[item.type]!;
    return Positioned(left:cx-sz/2, top:cy-sz/2,
      child:Container(width:sz,height:sz,
        decoration:BoxDecoration(shape:BoxShape.circle,color:col.withOpacity(0.2),
          border:Border.all(color:col,width:2),boxShadow:[BoxShadow(color:col.withOpacity(0.4),blurRadius:8)]),
        child:Center(child:Text(item.icon,
          style:TextStyle(fontSize:item.type==PowerUpType.doublePoints?11:16,color:col,fontWeight:FontWeight.bold)))));
  }
}

class _ObstacleWidget extends StatelessWidget {
  final Obstacle obs; final double W, H;
  const _ObstacleWidget({required this.obs, required this.W, required this.H});
  @override
  Widget build(BuildContext context) {
    final cx=(obs.x+1)/2*W, cy=(obs.y+1)/2*H;
    switch(obs.type){
      case ObstacleType.meteor:
        return Positioned(left:cx-36,top:cy-36,child:Transform.rotate(angle:obs.rotation,
          child:Image.asset('assets/images/obstacles/meteor.png',width:72,height:72,
            errorBuilder:(_,__,___)=>CustomPaint(size:const Size(72,72),painter:_MeteorP()))));
      case ObstacleType.bat:
        return Positioned(left:cx-45,top:cy-26,
          child:Image.asset('assets/images/obstacles/bat_enemy.png',width:90,height:52,
            errorBuilder:(_,__,___)=>CustomPaint(size:const Size(90,52),painter:_BatP())));
      case ObstacleType.laser:
        return Positioned(left:cx-100,top:cy-30,
          child:CustomPaint(size:const Size(200,60),painter:_LaserP(on:obs.laserOn)));
      case ObstacleType.ufo:
        return Positioned(left:cx-50,top:cy-20,
          child:Image.asset('assets/images/obstacles/ufo_enemy.png',width:100,height:80,
            errorBuilder:(_,__,___)=>CustomPaint(size:const Size(100,80),painter:_UfoP())));
      case ObstacleType.ghost:
        return Positioned(left:cx-32,top:cy-32,
          child:Opacity(opacity:0.55,child:Image.asset('assets/images/obstacles/ghost_enemy.png',
            width:64,height:64,errorBuilder:(_,__,___)=>CustomPaint(size:const Size(64,64),painter:_GhostP()))));
    }
  }
}
class _MeteorP extends CustomPainter{@override void paint(Canvas c,Size s){final cx=s.width/2,cy=s.height*0.4;for(int i=0;i<8;i++){final r=(8-i)*2.5;c.drawCircle(Offset(cx,cy+i*5.0),r.toDouble(),Paint()..color=Color.lerp(const Color(0xFFFF6600),Colors.transparent,i/8)!);}c.drawCircle(Offset(cx,cy),22,Paint()..color=const Color(0xFF5A5A7A));c.drawCircle(Offset(cx,cy),22,Paint()..color=const Color(0xFFFF6A00)..style=PaintingStyle.stroke..strokeWidth=2);}@override bool shouldRepaint(_)=>false;}
class _BatP extends CustomPainter{@override void paint(Canvas c,Size s){final cx=s.width/2,cy=s.height*0.6;final wp=Paint()..color=const Color(0xFF3A1060);c.drawPath(Path()..moveTo(cx,cy)..quadraticBezierTo(cx-30,cy-28,cx-44,cy-14)..quadraticBezierTo(cx-38,cy+2,cx,cy+4),wp);c.drawPath(Path()..moveTo(cx,cy)..quadraticBezierTo(cx+30,cy-28,cx+44,cy-14)..quadraticBezierTo(cx+38,cy+2,cx,cy+4),wp);c.drawOval(Rect.fromCenter(center:Offset(cx,cy),width:28,height:22),Paint()..color=const Color(0xFF2A0848));c.drawOval(Rect.fromCenter(center:Offset(cx,cy-14),width:22,height:18),Paint()..color=const Color(0xFF2A0848));for(final ex in [cx-6.0,cx+6.0]){c.drawCircle(Offset(ex,cy-14),4,Paint()..color=const Color(0xFFFF0000));c.drawCircle(Offset(ex,cy-14),2,Paint()..color=const Color(0xFFFF8888));}}@override bool shouldRepaint(_)=>false;}
class _LaserP extends CustomPainter{final bool on;_LaserP({required this.on});@override void paint(Canvas c,Size s){for(final ex in [20.0,s.width-20]){c.drawCircle(Offset(ex,s.height*0.35),on?9.0:6.0,Paint()..color=on?const Color(0xFFFF2020):const Color(0xFF440000));if(on)c.drawCircle(Offset(ex,s.height*0.35),5,Paint()..color=const Color(0xFFFF8888));}if(on){c.drawRect(Rect.fromLTWH(20,s.height*0.31,s.width-40,3),Paint()..color=const Color(0xFFFF4444));c.drawRect(Rect.fromLTWH(20,s.height*0.63,s.width-40,3),Paint()..color=const Color(0xFFFF4444));}}@override bool shouldRepaint(_LaserP o)=>o.on!=on;}
class _UfoP extends CustomPainter{@override void paint(Canvas c,Size s){final cx=s.width/2,cy=s.height*0.38;c.drawPath(Path()..moveTo(cx-28,cy+10)..lineTo(cx+28,cy+10)..lineTo(cx+44,s.height)..lineTo(cx-44,s.height)..close(),Paint()..color=const Color(0x2244FFAA));c.drawOval(Rect.fromCenter(center:Offset(cx,cy+6),width:80,height:20),Paint()..color=const Color(0xFF404858));c.drawOval(Rect.fromCenter(center:Offset(cx,cy-4),width:38,height:28),Paint()..color=const Color(0xFF303848));c.drawOval(Rect.fromCenter(center:Offset(cx,cy-6),width:26,height:18),Paint()..color=const Color(0xFF44DDFF).withOpacity(0.6));final lc=[const Color(0xFFFF4444),const Color(0xFFFFFF44),const Color(0xFF44FF44),const Color(0xFF44FFFF),const Color(0xFF4444FF)];for(int i=0;i<5;i++)c.drawCircle(Offset(cx-20+i*10,cy+6),3,Paint()..color=lc[i]);}@override bool shouldRepaint(_)=>false;}
class _GhostP extends CustomPainter{@override void paint(Canvas c,Size s){final cx=s.width/2;final p=Path()..moveTo(cx-22,s.height)..lineTo(cx-22,s.height*0.35)..quadraticBezierTo(cx,s.height*0.1,cx+22,s.height*0.35)..lineTo(cx+22,s.height)..quadraticBezierTo(cx+14,s.height-10,cx+6,s.height)..quadraticBezierTo(cx,s.height-14,cx-6,s.height)..quadraticBezierTo(cx-14,s.height-10,cx-22,s.height)..close();c.drawPath(p,Paint()..color=const Color(0xBBCCCCFF));for(final ex in [cx-8.0,cx+8.0]){c.drawCircle(Offset(ex,s.height*0.45),7,Paint()..color=const Color(0xFFFFFF44));c.drawCircle(Offset(ex,s.height*0.45),4,Paint()..color=const Color(0xFFFF8800));c.drawCircle(Offset(ex,s.height*0.45),2,Paint()..color=Colors.black);}}@override bool shouldRepaint(_)=>false;}

// ─────────────────────────────────────────────────────────────
// HUD y widgets auxiliares
// ─────────────────────────────────────────────────────────────
class _SessionCoins extends StatelessWidget {
  final int count; const _SessionCoins({required this.count});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),
    decoration: BoxDecoration(color:Colors.black.withOpacity(0.4),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFFFD700).withOpacity(0.5))),
    child: Row(mainAxisSize:MainAxisSize.min,children:[
      const Text('💰',style:TextStyle(fontSize:14)),const SizedBox(width:4),
      Text('$count',style:const TextStyle(color:Color(0xFFFFD700),fontSize:14,fontWeight:FontWeight.bold))]));
}

class _PowerUpIndicators extends StatelessWidget {
  final GameProvider game; const _PowerUpIndicators({required this.game});
  @override Widget build(BuildContext context) => Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    if(game.shieldActive)       _PUBar('🛡',game.shieldTimer,5.0,const Color(0xFF4488FF)),
    if(game.slowMoActive)       _PUBar('⏱',game.slowMoTimer,5.0,const Color(0xFFAA44FF)),
    if(game.doublePointsActive) _PUBar('×2',game.doubleTimer,8.0,const Color(0xFFFFD700))]);
}

class _PUBar extends StatelessWidget {
  final String icon; final double timer,maxTime; final Color color;
  const _PUBar(this.icon,this.timer,this.maxTime,this.color);
  @override Widget build(BuildContext context)=>Container(
    margin:const EdgeInsets.symmetric(horizontal:4),padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
    decoration:BoxDecoration(color:Colors.black.withOpacity(0.55),borderRadius:BorderRadius.circular(10),border:Border.all(color:color.withOpacity(0.7))),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Text(icon,style:const TextStyle(fontSize:14)),const SizedBox(width:4),
      SizedBox(width:40,height:6,child:ClipRRect(borderRadius:BorderRadius.circular(3),
        child:LinearProgressIndicator(value:(timer/maxTime).clamp(0,1),backgroundColor:Colors.white12,valueColor:AlwaysStoppedAnimation(color))))]));
}

class _TopBar extends StatelessWidget {
  final GameProvider game; const _TopBar({required this.game});
  @override Widget build(BuildContext context){
    final night=game.isNight;
    return Container(color:Colors.black.withOpacity(0.28),padding:const EdgeInsets.symmetric(horizontal:16),
      child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('🏆 ${game.bestScore}',style:const TextStyle(color:Colors.white70,fontSize:13,fontWeight:FontWeight.w600)),
          Text(game.state==GameState.start?'Toca para volar':game.isPaused?'Pausado':night?'🌙 Nivel ${game.level}':'☀️ Día',
            style:TextStyle(color:night?const Color(0xFFF5E87A):Colors.white,fontSize:12,fontWeight:FontWeight.w500))]),
        Row(children:[
          _HBtn(icon:game.isPaused?Icons.play_arrow_rounded:Icons.pause_rounded,onTap:game.togglePause),
          const SizedBox(width:4),
          _HBtn(icon:game.soundOn?Icons.volume_up_rounded:Icons.volume_off_rounded,onTap:game.toggleSound)])]));
  }
}
class _HBtn extends StatelessWidget{final IconData icon;final VoidCallback onTap;const _HBtn({required this.icon,required this.onTap});@override Widget build(BuildContext context)=>GestureDetector(onTap:onTap,child:Container(width:36,height:36,decoration:BoxDecoration(color:Colors.white.withOpacity(0.15),shape:BoxShape.circle,border:Border.all(color:Colors.white30)),child:Icon(icon,color:Colors.white,size:18)));}
class _LevelBadge extends StatelessWidget{final int level;const _LevelBadge({required this.level});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),decoration:BoxDecoration(color:const Color(0xFF1A2A5E).withOpacity(0.85),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFF5E87A).withOpacity(0.6))),child:Text('Nv. $level',style:const TextStyle(color:Color(0xFFF5E87A),fontSize:12,fontWeight:FontWeight.bold)));}
class _PauseOverlay extends StatelessWidget{const _PauseOverlay();@override Widget build(BuildContext context)=>Container(color:Colors.black.withOpacity(0.55),child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.pause_circle_filled_rounded,color:Colors.white,size:72),SizedBox(height:12),Text('PAUSADO',style:TextStyle(fontSize:36,fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:4)),SizedBox(height:8),Text('Toca o presiona P para continuar',style:TextStyle(color:Colors.white70,fontSize:14))])));}
