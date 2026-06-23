// ============================================================
// ui/leaderboard_screen.dart
// Pantalla de ranking con animaciones, filtros y posición del jugador
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  bool _error   = false;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _load();
  }

  @override
  void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final data = await LeaderboardService().fetchTop20();
      if (mounted) {
        setState(() { _entries = data; _loading = false; });
        _staggerCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050A1E), Color(0xFF0D1B3E), Color(0xFF1A2A5E)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24)),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('🏆 RANKING GLOBAL',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 1)),
                ),
                // Botón recargar
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24)),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
                ),
              ],
            ),
          ),

          // ── Tu puntaje personal ──────────────────────────
          _MyScoreCard(game: game),

          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 4),

          // ── Lista ────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5E87A)))
                : _error
                    ? _ErrorView(onRetry: _load)
                    : _entries.isEmpty
                        ? const _EmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _entries.length,
                            itemBuilder: (ctx, i) {
                              // Animación escalonada por fila
                              final delay = i / _entries.length;
                              final anim  = CurvedAnimation(
                                parent: _staggerCtrl,
                                curve: Interval(delay * 0.6, delay * 0.6 + 0.4, curve: Curves.easeOut),
                              );
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.3, 0), end: Offset.zero)
                                      .animate(anim),
                                  child: _LeaderboardRow(
                                    rank:  i + 1,
                                    entry: _entries[i],
                                    isMe:  _entries[i].playerName == game.playerName &&
                                           _entries[i].score      == game.bestScore,
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // ── Botón enviar puntaje ─────────────────────────
          _SubmitButton(game: game, onSubmitted: _load),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}

// ── Panel "tu puntaje" ────────────────────────────────────────
class _MyScoreCard extends StatelessWidget {
  final GameProvider game;
  const _MyScoreCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A8A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5E87A).withOpacity(0.4))),
      child: Row(children: [
        const Text('👤', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(game.playerName.isEmpty ? 'Sin nombre — configura en START' : game.playerName,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Récord personal: ${game.bestScore} pts',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        Text('${game.bestScore}',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFF5E87A))),
      ]),
    );
  }
}

// ── Fila del ranking ─────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  final int rank; final LeaderboardEntry entry; final bool isMe;
  const _LeaderboardRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColors = {1: const Color(0xFFFFD700), 2: const Color(0xFFC0C0C0), 3: const Color(0xFFCD7F32)};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF1A3A8A).withOpacity(0.7)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? const Color(0xFFF5E87A).withOpacity(0.7)
              : isTop3 ? rankColors[rank]!.withOpacity(0.4) : Colors.transparent,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Posición / medalla
        SizedBox(width: 36,
          child: isTop3
              ? Text(medals[rank]!, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)
              : Text('#$rank',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                    color: isMe ? const Color(0xFFF5E87A) : Colors.white38),
                  textAlign: TextAlign.center)),
        const SizedBox(width: 8),
        // Skin emoji
        Text(_skinEmoji(entry.skinId), style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        // Nombre y detalles
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(entry.playerName,
              style: TextStyle(color: isMe ? const Color(0xFFF5E87A) : Colors.white,
                fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            if (isMe) const Padding(padding: EdgeInsets.only(left: 4), child: Text('(tú)', style: TextStyle(color: Color(0xFFF5E87A), fontSize: 11))),
          ]),
          Text('Nv. ${entry.level}${entry.isNight ? " 🌙" : " ☀️"}',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        // Score
        Text('${entry.score}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
            color: isTop3 ? rankColors[rank]! : (isMe ? const Color(0xFFF5E87A) : Colors.white))),
      ]),
    );
  }

  String _skinEmoji(String id) {
    const map = {'yellow':'🐤','red':'🔴','blue':'🔵','ninja':'🥷','astro':'👨‍🚀','dark':'🌑'};
    return map[id] ?? '🐤';
  }
}

// ── Botón enviar puntaje ──────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final GameProvider game; final VoidCallback onSubmitted;
  const _SubmitButton({required this.game, required this.onSubmitted});
  @override State<_SubmitButton> createState() => _SubmitButtonState();
}
class _SubmitButtonState extends State<_SubmitButton> {
  bool _submitting = false;
  bool _done = false;

  Future<void> _submit() async {
    if (widget.game.bestScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juega primero para tener un puntaje que enviar.'),
          backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _submitting = true);
    final entry = LeaderboardEntry(
      playerName: widget.game.playerName.isEmpty ? 'Jugador' : widget.game.playerName,
      score:      widget.game.bestScore,
      level:      widget.game.level,
      isNight:    widget.game.isNight,
      date:       DateTime.now().toIso8601String(),
      skinId:     widget.game.selectedSkin.name,
    );
    final ok = await LeaderboardService().submitScore(entry);
    if (mounted) {
      setState(() { _submitting = false; _done = ok; });
      if (ok) widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '✅ Puntaje enviado!' : '⚠️ Sin conexión — se guardó localmente'),
          backgroundColor: ok ? Colors.green : Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _submitting ? null : _submit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _done
                  ? [const Color(0xFF2E8B57), const Color(0xFF1A6B3A)]
                  : [const Color(0xFF1A3A8A), const Color(0xFF0D1B5E)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFF5E87A).withOpacity(0.5))),
          child: _submitting
              ? const Center(child: SizedBox(width:20, height:20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth:2)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_done ? Icons.check_circle_rounded : Icons.upload_rounded,
                    color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(_done ? 'PUNTAJE ENVIADO' : 'ENVIAR MI RÉCORD (${widget.game.bestScore})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('🌐', style:TextStyle(fontSize:48)),const SizedBox(height:12),
    const Text('Sin conexión al ranking',style:TextStyle(color:Colors.white70,fontSize:16)),
    const SizedBox(height:8),const Text('Se muestra el caché local',style:TextStyle(color:Colors.white38,fontSize:13)),
    const SizedBox(height:20),GestureDetector(onTap:onRetry,child:Container(padding:const EdgeInsets.symmetric(horizontal:24,vertical:10),decoration:BoxDecoration(color:Colors.white10,borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white24)),child:const Text('Reintentar',style:TextStyle(color:Colors.white))))
  ]));
}
class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override Widget build(BuildContext context)=>const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('🏆',style:TextStyle(fontSize:48)),SizedBox(height:12),
    Text('Sé el primero en el ranking!',style:TextStyle(color:Colors.white70,fontSize:16))]));
}
