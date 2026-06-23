import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'achievements_screen.dart';
import 'shop_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return Container(
      color: Colors.black.withOpacity(0.40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_,__) => Transform.translate(
                offset: Offset(0, _bounce.value),
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700),
                    border: Border.all(color: const Color(0xFFCC8800), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0,6))],
                  ),
                  child: const Icon(Icons.flutter_dash, color: Color(0xFFFF8C00), size: 50),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text('FLAPPY BIRD',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2,
                shadows: [Shadow(color: Colors.black54, offset: Offset(2,3), blurRadius: 6), Shadow(color: Color(0xFFFFD700), offset: Offset(0,-1), blurRadius: 10)])),
            const Text('ADVENTURE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 6)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
              child: const Text('🌙 Modo noche activo en nivel 5', style: TextStyle(color: Color(0xFFAACCFF), fontSize: 13)),
            ),
            if (game.bestScore > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.18), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5))),
                child: Text('🏆 Récord: ${game.bestScore}', style: const TextStyle(color: Color(0xFFFFEE88), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: game.startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5DC832), Color(0xFF3A9E18)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF2E7010), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text('JUGAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(children: [
                  Text(game.currentSkin.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(game.currentSkin.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ShopScreen(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A9E18),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0,3))],
                  ),
                  child: const Text('TIENDA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AchievementsScreen(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4488FF),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0,3))],
                  ),
                  child: const Text('LOGROS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_,__) => Opacity(
                opacity: (math.sin(_ctrl.value * math.pi) * 0.4 + 0.6).clamp(0.4, 1.0),
                child: const Text('Toca o presiona ESPACIO para volar',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
