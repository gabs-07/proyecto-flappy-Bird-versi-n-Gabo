// ============================================================
// ui/replay_screen.dart
// Visualización del replay de la última partida
// Muestra la posición del pájaro y los tubos cuadro a cuadro
// ============================================================
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_logic.dart';
import '../providers/game_provider.dart';
import '../services/replay_recorder.dart';

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key});
  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen>
    with SingleTickerProviderStateMixin {
  late ReplayPlayer _player;
  late AnimationController _birdCtrl;
  Timer? _timer;
  ReplayFrame? _frame;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final recorder = ReplayRecorder();
    _player = ReplayPlayer(frames: recorder.frames, loop: true);

    _birdCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))..repeat();

    // Arrancar reproducción automáticamente
    _player.play();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final frame = _player.tick();
      if (frame != null) setState(() => _frame = frame);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _birdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recorder = ReplayRecorder();
    if (!recorder.hasReplay) {
      return _NoReplayView(onClose: () => Navigator.pop(context));
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          // ── Canvas del replay ──────────────────────────
          LayoutBuilder(builder: (ctx, cst) {
            final W = cst.maxWidth, H = cst.maxHeight;
            return _frame == null
                ? const SizedBox.expand()
                : _ReplayCanvas(frame: _frame!, W: W, H: H, birdAnim: _birdCtrl);
          }),

          // ── Overlay de controles ───────────────────────
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _ControlsOverlay(
              player: _player,
              finalScore: recorder.finalScore,
              progress: _player.progress,
              onClose: () => Navigator.pop(context),
              onPlayPause: () => setState(() =>
                  _player.isPlaying ? _player.pause() : _player.play()),
              onRestart: () => setState(() => _player.reset()),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Canvas: dibuja el estado del replay ──────────────────────
class _ReplayCanvas extends StatelessWidget {
  final ReplayFrame frame;
  final double W, H;
  final Animation<double> birdAnim;

  const _ReplayCanvas({required this.frame, required this.W, required this.H, required this.birdAnim});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(W, H),
      painter: _ReplayPainter(frame: frame, birdAnim: birdAnim.value),
    );
  }
}

class _ReplayPainter extends CustomPainter {
  final ReplayFrame frame;
  final double birdAnim;
  _ReplayPainter({required this.frame, required this.birdAnim});

  @override
  void paint(Canvas canvas, Size size) {
    final blend = frame.nightBlend;

    // ── Fondo ──────────────────────────────────────────
    final skyTop = Color.lerp(const Color(0xFF38B8C8), const Color(0xFF050A1E), blend)!;
    final skyBot = Color.lerp(const Color(0xFFB8EAF0), const Color(0xFF1A2A5E), blend)!;
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height), Paint()
      ..shader = LinearGradient(begin:Alignment.topCenter, end:Alignment.bottomCenter,
          colors:[skyTop, skyBot]).createShader(Rect.fromLTWH(0,0,size.width,size.height)));

    // ── "REPLAY" watermark ────────────────────────────
    final tp = TextPainter(
      text: const TextSpan(text: '◉ REPLAY',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0x44FFFFFF), letterSpacing: 2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 16, 16));

    // ── Suelo ─────────────────────────────────────────
    const kGroundH = 72.0;
    final playH = size.height - kGroundH;
    canvas.drawRect(Rect.fromLTWH(0, playH, size.width, 24),
      Paint()..color = Color.lerp(const Color(0xFF5D9E3B), const Color(0xFF122B0C), blend)!);
    canvas.drawRect(Rect.fromLTWH(0, playH + 24, size.width, kGroundH - 24),
      Paint()..color = Color.lerp(const Color(0xFFDEB887), const Color(0xFF3E2510), blend)!);

    // ── Tubos ─────────────────────────────────────────
    for (final pipe in frame.pipes) {
      _drawPipe(canvas, pipe.x, pipe.gapY, pipe.gapHeight, size.width, playH, blend);
    }

    // ── Pájaro ────────────────────────────────────────
    final birdSize = playH * GameLogic.birdSizeRatio;
    final bx = (GameLogic.birdX + 1) / 2 * size.width;
    final by = (frame.birdY + 1) / 2 * playH;
    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(frame.birdRotation);
    _drawBird(canvas, birdSize, frame.birdFrame, blend);
    canvas.restore();

    // ── Score ─────────────────────────────────────────
    final scorePainter = TextPainter(
      text: TextSpan(text: '${frame.score}',
        style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white,
          shadows: [Shadow(offset: Offset(2,3), blurRadius:6, color: Colors.black54)])),
      textDirection: TextDirection.ltr,
    )..layout();
    scorePainter.paint(canvas, Offset(size.width/2 - scorePainter.width/2, playH * 0.06));
  }

  void _drawPipe(Canvas canvas, double nx, double gapY, double gapHeight,
      double sw, double playH, double blend) {
    final pW      = sw * (GameLogic.pipeWidthRatio / 2);
    final centerY = (gapY + 1) / 2 * playH;
    final halfG   = (gapHeight / 2) * playH;
    final left    = (nx + 1) / 2 * sw - pW / 2;
    final topH    = (centerY - halfG).clamp(0.0, playH);
    final botY    = centerY + halfG;
    final botH    = (playH - botY).clamp(0.0, playH);
    final bodyC   = Color.lerp(const Color(0xFF3A8E1C), const Color(0xFF1A3A1A), blend)!;
    final capC    = Color.lerp(const Color(0xFF52C22A), const Color(0xFF234E23),  blend)!;
    final capH    = (pW * 0.40).clamp(0.0, topH);
    final p       = Paint()..color = bodyC;
    final cp      = Paint()..color = capC;

    if (topH > capH) canvas.drawRect(Rect.fromLTWH(left, 0, pW, topH - capH), p);
    if (capH > 0)    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(left - 4, topH - capH, pW + 8, capH),
        bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4)), cp);
    if (botH > capH) {
      if (capH > 0) canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(left - 4, botY, pW + 8, capH),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), cp);
      canvas.drawRect(Rect.fromLTWH(left, botY + capH, pW, botH - capH), p);
    }
  }

  void _drawBird(Canvas canvas, double sz, int wingFrame, double blend) {
    final r = sz * 0.46;
    // Color del pájaro cambia con la noche
    final bodyC = Color.lerp(const Color(0xFFFFD700), const Color(0xFF3A90D8), blend)!;
    final wingC = Color.lerp(const Color(0xFFE8A800), const Color(0xFF1A5A9E),  blend)!;

    // Ala
    final wingY = [-0.55, -0.30, -0.05, 0.22][wingFrame % 4];
    final wp = Path()
      ..moveTo(-r*0.30, 0)
      ..quadraticBezierTo(-r*1.20, wingY*r, -r*0.70, r*0.05)..close();
    canvas.drawPath(wp, Paint()..color = wingC);

    // Cuerpo
    canvas.drawCircle(Offset.zero, r, Paint()..color = bodyC);
    canvas.drawCircle(Offset.zero, r, Paint()..color = wingC..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Ojo
    canvas.drawCircle(Offset(r*0.35, -r*0.22), r*0.36, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(r*0.44, -r*0.16), r*0.20, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(r*0.50, -r*0.26), r*0.09, Paint()..color = Colors.white);

    // Pico
    canvas.drawPath(Path()
      ..moveTo(r*0.62, -r*0.08)..lineTo(r*1.15, r*0.04)..lineTo(r*0.62, r*0.22)..close(),
      Paint()..color = const Color(0xFFFF8C00));
  }

  @override
  bool shouldRepaint(_ReplayPainter o) => o.frame != frame;
}

// ── Overlay de controles ──────────────────────────────────────
class _ControlsOverlay extends StatelessWidget {
  final ReplayPlayer player;
  final int finalScore;
  final double progress;
  final VoidCallback onClose, onPlayPause, onRestart;
  const _ControlsOverlay({
    required this.player, required this.finalScore, required this.progress,
    required this.onClose, required this.onPlayPause, required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Top bar
      Container(
        color: Colors.black54,
        padding: const EdgeInsets.fromLTRB(12, 40, 12, 10),
        child: Row(children: [
          GestureDetector(
            onTap: onClose,
            child: Container(padding:const EdgeInsets.all(8),
              decoration:BoxDecoration(color:Colors.white10,shape:BoxShape.circle,border:Border.all(color:Colors.white24)),
              child:const Icon(Icons.close_rounded,color:Colors.white,size:20))),
          const SizedBox(width:12),
          const Text('REPLAY', style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:2)),
          const Spacer(),
          Text('$finalScore pts', style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Color(0xFFF5E87A))),
        ]),
      ),
      const Spacer(),
      // Barra de progreso y controles
      Container(
        color: Colors.black54,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(children: [
          // Progress bar
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF5E87A)))),
          const SizedBox(height: 14),
          // Botones
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CtrlBtn(icon: Icons.replay_rounded, onTap: onRestart, label: 'Reiniciar'),
            const SizedBox(width: 20),
            _CtrlBtn(
              icon: player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onTap: onPlayPause, label: player.isPlaying ? 'Pausa' : 'Play', large: true),
            const SizedBox(width: 20),
            _CtrlBtn(icon: Icons.close_rounded, onTap: onClose, label: 'Cerrar'),
          ]),
          const SizedBox(height: 8),
          const Text('Toca la pantalla para mostrar/ocultar controles',
            style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    ]);
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final String label; final bool large;
  const _CtrlBtn({required this.icon, required this.onTap, required this.label, this.large = false});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize:MainAxisSize.min, children:[
      Container(width:large?56:44, height:large?56:44,
        decoration:BoxDecoration(color:Colors.white.withOpacity(0.15),shape:BoxShape.circle,border:Border.all(color:Colors.white30)),
        child:Icon(icon,color:Colors.white,size:large?28:20)),
      const SizedBox(height:4),
      Text(label,style:const TextStyle(color:Colors.white54,fontSize:10)),
    ]));
}

class _NoReplayView extends StatelessWidget {
  final VoidCallback onClose;
  const _NoReplayView({required this.onClose});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050A1E),
    body: Center(child: Column(mainAxisSize:MainAxisSize.min, children:[
      const Text('🎬',style:TextStyle(fontSize:64)),const SizedBox(height:16),
      const Text('No hay replay disponible',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      const Text('Juega una partida para grabar tu replay',style:TextStyle(color:Colors.white54,fontSize:14)),
      const SizedBox(height:28),
      GestureDetector(onTap:onClose,child:Container(padding:const EdgeInsets.symmetric(horizontal:32,vertical:14),
        decoration:BoxDecoration(color:const Color(0xFF1A3A8A),borderRadius:BorderRadius.circular(30),border:Border.all(color:const Color(0xFFF5E87A).withOpacity(0.5))),
        child:const Text('Cerrar',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:16)))),
    ])));
}
