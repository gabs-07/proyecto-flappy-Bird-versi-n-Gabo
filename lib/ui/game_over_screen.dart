import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'leaderboard_screen.dart';
import 'replay_screen.dart';

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

  void _openLeaderboard(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(height: MediaQuery.of(ctx).size.height * 0.92, child: const LeaderboardScreen()));
  }

  void _openReplay(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ReplayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameProvider>();
    final night = game.isNight;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.62),
        child: Center(child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 310,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            decoration: BoxDecoration(
              color: night ? const Color(0xFF0D1B3E) : const Color(0xFFF5DEB3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 24, offset: const Offset(0,10))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Título
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: night ? const Color(0xFF1A3A8A) : const Color(0xFFE05C2A),
                  borderRadius: BorderRadius.circular(14)),
                child: Text(night ? '🌙 GAME OVER' : 'GAME OVER',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
              const SizedBox(height: 12),
              Text('Nivel ${game.level} alcanzado',
                style: TextStyle(color: night ? const Color(0xFFAABBDD) : const Color(0xFF8B6914), fontSize: 13)),
              const SizedBox(height: 10),
              // Panel de puntaje
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: night ? const Color(0xFF1A2A5E) : const Color(0xFFD4A935),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), width: 2)),
                child: Column(children: [
                  _row('PUNTOS',  game.score,       false,          night),
                  Divider(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), height: 10),
                  _row('RÉCORD',  game.bestScore,   game.newRecord, night),
                  Divider(color: night ? const Color(0xFF2A4A8A) : const Color(0xFF8B6914), height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('MONEDAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: night ? const Color(0xFFAABBDD) : const Color(0xFF5A3E10))),
                    Row(children: [
                      const Text('💰', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 4),
                      Text('+${game.sessionCoins}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFFFD700))),
                    ]),
                  ]),
                ])),
              if (game.newRecord) ...[
                const SizedBox(height: 8),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                  SizedBox(width: 5),
                  Text('¡NUEVO RÉCORD!', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                  SizedBox(width: 5),
                  Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                ]),
              ],
              const SizedBox(height: 16),

              // ── Botones en grid 2×2 ────────────────────────
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.8,
                children: [
                  // Jugar de nuevo
                  _GameBtn(
                    label: 'JUGAR', icon: Icons.replay_rounded,
                    gradient: const [Color(0xFF5DC832), Color(0xFF3A9E18)],
                    border: const Color(0xFF2E7010),
                    onTap: game.resetGame),
                  // Replay
                  _GameBtn(
                    label: 'REPLAY', icon: Icons.play_circle_outline_rounded,
                    gradient: const [Color(0xFF1A3A8A), Color(0xFF0D1B5E)],
                    border: const Color(0xFFF5E87A),
                    onTap: () => _openReplay(context)),
                  // Ranking
                  _GameBtn(
                    label: 'RANKING', icon: Icons.emoji_events_rounded,
                    gradient: const [Color(0xFF8B6914), Color(0xFF5A4008)],
                    border: const Color(0xFFFFD700),
                    onTap: () => _openLeaderboard(context)),
                  // Home
                  _GameBtn(
                    label: 'HOME', icon: Icons.home_rounded,
                    gradient: [const Color(0xFF3A3A3A), const Color(0xFF222222)],
                    border: const Color(0xFF5A5A5A),
                    onTap: game.resetGame),
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
      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: night ? const Color(0xFFAABBDD) : const Color(0xFF5A3E10))),
      Text('$val', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900,
          color: highlight ? const Color(0xFFFFD700) : (night ? Colors.white : const Color(0xFF3A2800)))),
    ]);
}

class _GameBtn extends StatelessWidget {
  final String label; final IconData icon;
  final List<Color> gradient; final Color border;
  final VoidCallback onTap;
  const _GameBtn({required this.label, required this.icon, required this.gradient, required this.border, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0,3))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
      ])));
}
