import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/achievement.dart';
import '../providers/game_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final unlocked = game.unlockedAchievements;

    return Container(
      color: Colors.black.withOpacity(0.88),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🏆 LOGROS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 1)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mira qué logros ya tienes y cómo desbloquear los demás.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _Badge(text: '${unlocked.length}', label: 'desbloqueados'),
                  const SizedBox(width: 12),
                  _Badge(text: '${kAchievements.length}', label: 'totales'),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                itemCount: kAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = kAchievements[index];
                  final isUnlocked = unlocked.contains(achievement.id);
                  return _AchievementTile(achievement: achievement, unlocked: isUnlocked);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final String label;
  const _Badge({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF163A12) : const Color(0xFF1F1F35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: unlocked ? const Color(0xFF4CC26E) : const Color(0xFF39405A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? const Color(0xFF4CC26E) : const Color(0xFF5C5F88),
          ),
          child: Center(
            child: Text(achievement.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(achievement.title,
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CC26E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('DESBLOQUEADO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
            ]),
            const SizedBox(height: 6),
            Text(achievement.desc,
              style: TextStyle(color: unlocked ? Colors.white70 : Colors.white54, fontSize: 13, height: 1.3)),
          ]),
        ),
      ]),
    );
  }
}
