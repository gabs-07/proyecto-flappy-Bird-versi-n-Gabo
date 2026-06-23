import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});
  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)));
    Future.delayed(const Duration(milliseconds: 280), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final night = game.isNight;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.62),
        child: Center(child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: night ? const Color(0xFF0D1B3E) : const Color(0xFFF5DEB3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 24, offset: const Offset(0,10))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: night ? const Color(0xFF1A3A8A) : const Color(0xFFE05C2A),
                  borderRadius: BorderRadius.circular(14)),
                child: Text(night ? '🌙 GAME OVER' : 'GAME OVER',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
              const SizedBox(height: 14),
              Text('Nivel ${game.level} alcanzado',
                style: TextStyle(color: night ? const Color(0xFFAABBDD) : const Color(0xFF8B6914), fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: night ? const Color(0xFF1A2A5E) : const Color(0xFFD4A935),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), width: 2)),
                child: Column(children: [
                  _row('PUNTOS',  game.score,       false,          night),
                  Divider(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), height: 12),
                  _row('RÉCORD',  game.bestScore,   game.newRecord, night),
                  Divider(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), height: 12),
                  // Monedas ganadas en esta partida
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('MONEDAS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: night ? const Color(0xFFAABBDD) : const Color(0xFF5A3E10))),
                    Row(children: [
                      const Text('💰', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text('+${game.sessionCoins}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFFD700))),
                    ]),
                  ]),
                ])),
              if (game.newRecord) ...[
                const SizedBox(height: 10),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                  SizedBox(width: 6),
                  Text('¡NUEVO RÉCORD!', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                  SizedBox(width: 6),
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                ]),
              ],
              // Logros de esta partida
              if (game.unlockedAchievements.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('${game.unlockedAchievements.length} logros desbloqueados',
                  style: TextStyle(fontSize: 12, color: night ? Colors.white54 : const Color(0xFF8B6914))),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: GestureDetector(
                      onTap: game.resetGame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF5DC832), Color(0xFF3A9E18)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF2E7010), width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0,4))],
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.replay_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Flexible(child: Text('JUGAR DE NUEVO', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1))),
                        ]),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: GestureDetector(
                      onTap: game.resetGame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF5A5A5A), width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0,4))],
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.home_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text('HOME', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        )),
      ),
    );
  }

  Widget _row(String label, int val, bool highlight, bool night) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
        color: night ? const Color(0xFFAABBDD) : const Color(0xFF5A3E10))),
      Text('$val', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
        color: highlight ? const Color(0xFFFFD700) : (night ? Colors.white : const Color(0xFF3A2800)))),
    ]);
}
