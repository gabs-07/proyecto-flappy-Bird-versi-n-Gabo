import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/skin.dart';
import '../providers/game_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final night = game.isNight;

    return Container(
      color: Colors.black.withOpacity(0.88),
      child: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🎨 TIENDA DE SKINS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 1)),
                Row(children: [
                  const Text('💰 ', style: TextStyle(fontSize: 18)),
                  Text('${game.totalCoins}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700))),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white12, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24)),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20)),
                  ),
                ]),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          // Grid de skins
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9),
              itemCount: kSkins.length,
              itemBuilder: (ctx, i) => _SkinCard(skin: kSkins[i], game: game, night: night),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final Skin skin; final GameProvider game; final bool night;
  const _SkinCard({required this.skin, required this.game, required this.night});

  @override
  Widget build(BuildContext context) {
    final isOwned    = game.unlockedSkins.contains(skin.id);
    final isSelected = game.selectedSkin == skin.id;
    final canAfford  = game.canAfford(skin);

    Color borderColor;
    if (isSelected)     borderColor = const Color(0xFFFFD700);
    else if (isOwned)   borderColor = const Color(0xFF5DC832);
    else if (canAfford) borderColor = Colors.white24;
    else                borderColor = Colors.white12;

    return GestureDetector(
      onTap: () {
        if (isOwned) { game.selectSkin(skin.id); return; }
        if (canAfford) game.buySkin(skin);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A2A0A)
              : night ? const Color(0xFF0D1530) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview del pájaro con color del skin
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(skin.bodyColor),
                border: Border.all(color: Color(skin.wingColor), width: 3),
              ),
              child: Center(
                child: Text(skin.icon,
                  style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 8),
            Text(skin.name,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFFD700) : Colors.white)),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
                child: const Text('EQUIPADO',
                  style: TextStyle(fontSize: 10, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)))
            else if (isOwned)
              const Text('Toca para equipar',
                style: TextStyle(fontSize: 11, color: Color(0xFF5DC832)))
            else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('💰 ', style: TextStyle(fontSize: 13)),
                Text('${skin.cost}',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: canAfford ? const Color(0xFFFFD700) : Colors.white38)),
              ]),
          ],
        ),
      ),
    );
  }
}
