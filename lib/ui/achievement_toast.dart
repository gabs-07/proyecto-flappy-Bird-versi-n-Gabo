import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// Toast animado que aparece cuando se desbloquea un logro.
/// Se muestra en la parte superior del área de juego.
class AchievementToast extends StatefulWidget {
  const AchievementToast({super.key});
  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double>  _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)));
    _ctrl.forward();

    // Auto-dismiss después de 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) {
            context.read<GameProvider>().dismissToast();
          }
        });
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    if (game.pendingToasts.isEmpty) return const SizedBox.shrink();
    final ach = game.pendingToasts.first;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A0A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.7), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 12, spreadRadius: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ach.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('¡Logro desbloqueado!',
                  style: TextStyle(fontSize: 11, color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(ach.title,
                  style: const TextStyle(fontSize: 15, color: Colors.white,
                    fontWeight: FontWeight.w900)),
                Text(ach.desc,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
