// ============================================================
// ui/intro_animation.dart
// Animación de entrada de 1.4s al abrir la app:
//   - El pájaro vuela desde la izquierda hasta su posición
//   - El título cae desde arriba con bounce
//   - Los botones suben desde abajo
// Se muestra UNA sola vez por sesión (controlado por flag en GameProvider)
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class IntroAnimation extends StatefulWidget {
  final Widget child;
  const IntroAnimation({super.key, required this.child});

  @override
  State<IntroAnimation> createState() => _IntroAnimationState();
}

class _IntroAnimationState extends State<IntroAnimation>
    with TickerProviderStateMixin {

  late AnimationController _birdCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _btnsCtrl;

  // Pájaro: entra desde x=-1.2 hasta x=0 (centro) en 0.7s
  late Animation<double> _birdX;
  late Animation<double> _birdY; // leve arco de vuelo
  late Animation<double> _birdOpacity;

  // Título: cae desde y=-80 hasta y=0 con bounce en 0.5s (empieza a 0.3s)
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;

  // Botones: suben desde y=60 hasta y=0 en 0.4s (empieza a 0.7s)
  late Animation<Offset> _btnsSlide;
  late Animation<double> _btnsFade;

  bool _done = false;

  @override
  void initState() {
    super.initState();

    _birdCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _titleCtrl= AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _btnsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _birdX = Tween<double>(begin: -1.3, end: 0.0)
        .animate(CurvedAnimation(parent: _birdCtrl, curve: Curves.easeOut));
    _birdY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _birdCtrl, curve: Curves.easeInOut));
    _birdOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _birdCtrl, curve: const Interval(0, 0.2)));

    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.8), end: Offset.zero)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.elasticOut));
    _titleFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: const Interval(0, 0.3)));

    _btnsSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut));
    _btnsFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Pequeño delay inicial para que la app termine de cargar
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    // 1. Pájaro entra
    _birdCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 2. Título cae (solapado con el pájaro)
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 3. Botones suben
    _btnsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    // Marcar intro completada
    if (mounted) setState(() => _done = true);
    context.read<GameProvider>().markIntroPlayed();
  }

  @override
  void dispose() {
    _birdCtrl.dispose();
    _titleCtrl.dispose();
    _btnsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Una vez terminada la animación, mostrar el hijo directamente
    if (_done) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_birdCtrl, _titleCtrl, _btnsCtrl]),
      builder: (_, __) {
        return Stack(children: [
          // Fondo negro durante la transición (evita flash)
          Container(color: const Color(0xFF1A2A5E)),

          // Pájaro volando desde la izquierda
          Positioned(
            left: 0, right: 0, top: 0, bottom: 0,
            child: FractionalTranslation(
              translation: Offset(_birdX.value, 0),
              child: Opacity(
                opacity: _birdOpacity.value,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _birdY.value),
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700),
                        border: Border.all(color: const Color(0xFFCC8800), width: 3),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 20, spreadRadius: 4)
                        ],
                      ),
                      child: const Icon(Icons.flutter_dash,
                        color: Color(0xFFFF8C00), size: 42),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Título cae desde arriba
          Positioned(
            left: 0, right: 0, top: 0, bottom: 0,
            child: FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Text('FLAPPY BIRD',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 2,
                        shadows: [
                          Shadow(color: Colors.black54, offset: Offset(2,3), blurRadius:6),
                          Shadow(color: Color(0xFFFFD700), offset: Offset(0,-1), blurRadius:12),
                        ])),
                    Text('ADVENTURE',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700), letterSpacing: 7)),
                  ],
                ),
              ),
            ),
          ),

          // Botones suben desde abajo
          Positioned(
            left: 0, right: 0, bottom: 80,
            child: FadeTransition(
              opacity: _btnsFade,
              child: SlideTransition(
                position: _btnsSlide,
                child: const Center(
                  child: Text('Cargando...',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
