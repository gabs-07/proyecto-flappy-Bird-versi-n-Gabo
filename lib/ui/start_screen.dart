import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'shop_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;
  final _nameCtrl = TextEditingController();
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

  void _openSheet(BuildContext ctx, Widget screen) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(height: MediaQuery.of(ctx).size.height * 0.88, child: screen));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    if (_nameCtrl.text.isEmpty && game.playerName.isNotEmpty) {
      _nameCtrl.text = game.playerName;
    }

    return Container(
      color: Colors.black.withOpacity(0.42),
      child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Pájaro animado
            AnimatedBuilder(
              animation: _bounce,
              builder: (_,__) => Transform.translate(
                offset: Offset(0, _bounce.value),
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: const Color(0xFFFFD700),
                    border: Border.all(color: const Color(0xFFCC8800), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0,6))]),
                  child: const Icon(Icons.flutter_dash, color: Color(0xFFFF8C00), size: 50)),
              ),
            ),
            const SizedBox(height: 18),
            // Título
            const Text('FLAPPY BIRD',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2,
                shadows: [Shadow(color: Colors.black54, offset: Offset(2,3), blurRadius:6),
                          Shadow(color: Color(0xFFFFD700), offset: Offset(0,-1), blurRadius:10)])),
            const Text('ADVENTURE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 7)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
              child: const Text('🌙 Modo noche en nivel 1 · Obstáculos desde nivel 1',
                style: TextStyle(color: Color(0xFFAACCFF), fontSize: 12))),
            // Récord
            if (game.bestScore > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5))),
                child: Text('🏆 Récord: ${game.bestScore}',
                  style: const TextStyle(color: Color(0xFFFFEE88), fontSize: 15, fontWeight: FontWeight.w600))),
            ],
            const SizedBox(height: 16),

            // ── Campo de nombre ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _editingName
                  ? Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          maxLength: 16,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Tu nombre para el ranking',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true, fillColor: Colors.white10,
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          onSubmitted: (v) {
                            game.setPlayerName(v);
                            setState(() => _editingName = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          game.setPlayerName(_nameCtrl.text);
                          setState(() => _editingName = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF5DC832), shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18)),
                      ),
                    ])
                  : GestureDetector(
                      onTap: () => setState(() => _editingName = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.person_outline_rounded, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            game.playerName.isEmpty ? 'Toca para poner tu nombre (ranking)' : '👤 ${game.playerName}',
                            style: TextStyle(
                              color: game.playerName.isEmpty ? Colors.white38 : Colors.white70,
                              fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, color: Colors.white24, size: 14),
                        ]),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // ── Botón JUGAR ────────────────────────────────
            GestureDetector(
              onTap: game.startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5DC832), Color(0xFF3A9E18)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF2E7010), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text('JUGAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                ]))),
            const SizedBox(height: 14),

            // ── Botones secundarios (4 en fila) ────────────
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: [
                _SecBtn(icon: '🎨', label: game.currentSkin.name, onTap: () => _openSheet(context, const ShopScreen())),
                _SecBtn(icon: '🏆', label: 'RANKING',    onTap: () => _openSheet(context, const LeaderboardScreen())),
                _SecBtn(icon: '⭐', label: 'LOGROS',     onTap: () => _openSheet(context, const AchievementsScreen())),
              ],
            ),
            const SizedBox(height: 18),

            // Hint parpadeante
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_,__) => Opacity(
                opacity: (math.sin(_ctrl.value * math.pi) * 0.4 + 0.6).clamp(0.4, 1.0),
                child: const Text('Toca o presiona ESPACIO para volar',
                  style: TextStyle(color: Colors.white60, fontSize: 13))),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

class _SecBtn extends StatelessWidget {
  final String icon, label; final VoidCallback onTap;
  const _SecBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white12, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
      ])));
}
