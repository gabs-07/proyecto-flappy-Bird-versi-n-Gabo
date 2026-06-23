enum SkinId { yellow, red, blue, ninja, astro, dark }

class Skin {
  final SkinId id;
  final String name;
  final String icon;
  final int cost;          // monedas necesarias para desbloquear
  final int bodyColor;     // color ARGB del cuerpo
  final int wingColor;
  final int beakColor;
  final bool isNightVariant; // si este skin aplica al pájaro nocturno

  const Skin({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
    required this.bodyColor,
    required this.wingColor,
    required this.beakColor,
    this.isNightVariant = false,
  });
}

const List<Skin> kSkins = [
  Skin(id: SkinId.yellow, name: 'Clásico',     icon: '🐤', cost: 0,
       bodyColor: 0xFFFFD700, wingColor: 0xFFE8A800, beakColor: 0xFFFF8C00),
  Skin(id: SkinId.red,    name: 'Rojo fuego',  icon: '🔴', cost: 15,
       bodyColor: 0xFFFF4444, wingColor: 0xFFCC2222, beakColor: 0xFFFF8C00),
  Skin(id: SkinId.blue,   name: 'Oceánico',    icon: '🔵', cost: 20,
       bodyColor: 0xFF44AAFF, wingColor: 0xFF2288DD, beakColor: 0xFFFF8C00),
  Skin(id: SkinId.ninja,  name: 'Ninja',       icon: '🥷', cost: 30,
       bodyColor: 0xFF333333, wingColor: 0xFF111111, beakColor: 0xFF888888),
  Skin(id: SkinId.astro,  name: 'Astronauta',  icon: '👨‍🚀', cost: 40,
       bodyColor: 0xFFEEEEFF, wingColor: 0xFFCCCCEE, beakColor: 0xFFFF8C00),
  Skin(id: SkinId.dark,   name: 'Oscuro',      icon: '🌑', cost: 50,
       bodyColor: 0xFF1A1A2E, wingColor: 0xFF0D0D1A, beakColor: 0xFF6644AA,
       isNightVariant: true),
];
