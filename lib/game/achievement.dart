// Sistema de logros — definición y estado
// Cada Achievement es inmutable como definición; AchievementState lleva el progreso.

enum AchievementId {
  firstPipe,      // Pasar el primer tubo
  score10,        // Llegar a 10 puntos
  score25,        // Llegar a 25 puntos
  score50,        // Llegar a 50 puntos
  nightSurvivor,  // Sobrevivir 10 segundos en modo noche
  coinCollector,  // Recoger 10 monedas en una partida
  shieldUser,     // Usar un escudo
  slowMoUser,     // Usar slow-motion
  dodgeUfo,       // Esquivar un OVNI
  skinUnlock,     // Desbloquear primer skin
}

class Achievement {
  final AchievementId id;
  final String title;
  final String desc;
  final String icon;   // emoji

  const Achievement({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
  });
}

// Catálogo completo
const List<Achievement> kAchievements = [
  Achievement(id: AchievementId.firstPipe,     icon: '🐦', title: '¡Primer vuelo!',      desc: 'Pasa tu primer tubo'),
  Achievement(id: AchievementId.score10,        icon: '⭐', title: 'Volador novato',       desc: 'Alcanza 10 puntos'),
  Achievement(id: AchievementId.score25,        icon: '🌟', title: 'Volador experto',      desc: 'Alcanza 25 puntos'),
  Achievement(id: AchievementId.score50,        icon: '🏆', title: 'Maestro del vuelo',    desc: 'Alcanza 50 puntos'),
  Achievement(id: AchievementId.nightSurvivor,  icon: '🌙', title: 'Hijo de la noche',     desc: 'Sobrevive 10s en modo noche'),
  Achievement(id: AchievementId.coinCollector,  icon: '💰', title: 'Coleccionista',        desc: 'Recoge 10 monedas en una partida'),
  Achievement(id: AchievementId.shieldUser,     icon: '🛡', title: 'Intocable',            desc: 'Activa un escudo'),
  Achievement(id: AchievementId.slowMoUser,     icon: '⏱', title: 'Tiempo detenido',      desc: 'Activa slow-motion'),
  Achievement(id: AchievementId.dodgeUfo,       icon: '🛸', title: 'Esquivador cósmico',   desc: 'Pasa junto a un OVNI'),
  Achievement(id: AchievementId.skinUnlock,     icon: '🎨', title: 'Estilo propio',        desc: 'Desbloquea un skin'),
];
