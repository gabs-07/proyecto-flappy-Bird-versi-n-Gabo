import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_controller.dart';
import '../game/bird.dart';
import '../game/pipe.dart';
import '../game/obstacle.dart';
import '../game/coin.dart';
import '../game/powerup_item.dart';
import '../game/skin.dart';
import '../game/achievement.dart';
import '../game/game_logic.dart';

enum GameState { start, playing, gameOver }

class GameProvider extends ChangeNotifier {
  // ── Entidades ────────────────────────────────────────────────────────────────
  late Bird             bird;
  late List<Pipe>       pipes;
  late List<Obstacle>   obstacles;
  late List<Coin>       coins;
  late List<PowerUpItem> powerUpItems;

  // ── Estado base ──────────────────────────────────────────────────────────────
  GameState state     = GameState.start;
  bool isPaused       = false;
  bool soundOn        = true;
  int  score          = 0;
  int  bestScore      = 0;
  double difficulty   = 0.0;
  double groundScroll = 0.0;
  int  _tick          = 0;

  // ── Nivel / noche ────────────────────────────────────────────────────────────
  int  get level   => GameLogic.levelFromScore(score);
  bool get isNight => GameLogic.isNightMode(score);
  double _nightBlend = 0.0;
  double get nightBlend => _nightBlend;

  // ── Monedas ──────────────────────────────────────────────────────────────────
  int totalCoins      = 0;   // acumuladas entre partidas (persistentes)
  int sessionCoins    = 0;   // recogidas en la partida actual
  double _coinTimer   = 0.0;
  static const double _coinInterval = 3.0; // spawn cada 3s

  // ── Power-ups activos ─────────────────────────────────────────────────────────
  bool shieldActive       = false;
  bool slowMoActive       = false;
  bool doublePointsActive = false;
  double shieldTimer      = 0.0;
  double slowMoTimer      = 0.0;
  double doubleTimer      = 0.0;
  static const double _shieldDur = 5.0;
  static const double _slowMoDur = 5.0;
  static const double _doubleDur = 8.0;
  double _powerUpTimer    = 0.0;
  static const double _powerUpInterval = 12.0; // spawn cada 12s

  // ── Skins ────────────────────────────────────────────────────────────────────
  SkinId selectedSkin         = SkinId.yellow;
  Set<SkinId> unlockedSkins   = {SkinId.yellow};
  Skin get currentSkin => kSkins.firstWhere((s) => s.id == selectedSkin);

  // ── Logros ───────────────────────────────────────────────────────────────────
  Set<AchievementId> unlockedAchievements = {};
  // Cola de toasts pendientes de mostrar en pantalla
  List<Achievement> pendingToasts = [];
  double _nightSurvivalTime = 0.0;  // segundos en modo noche esta partida
  bool _ufoNearby           = false; // para el logro de esquivar OVNI

  // ── Efectos visuales ─────────────────────────────────────────────────────────
  bool   _collisionEnabled = false;
  int    _ticksSinceStart  = 0;
  double _shakeAmount      = 0.0;
  double get shakeAmount   => _shakeAmount;
  bool   _newRecord        = false;
  bool   get newRecord     => _newRecord;

  // ── Intro ────────────────────────────────────────────────────────────────
  bool introPlayed = false;
  void markIntroPlayed() { introPlayed = true; notifyListeners(); }

  // ── Obstáculos ───────────────────────────────────────────────────────────────
  double _obstacleTimer = 0.0;
  double get _obstacleInterval {
    final lvl = level;
    if (lvl < 1) return 9999.0;
    if (lvl < 2) return 5.0;
    if (lvl < 4) return 3.5;
    return 2.5;
  }

  static const double _dt = 0.016;
  late Timer _ticker;
  final AudioController audio = AudioController();
  final Random _rng = Random();

  GameProvider() {
    _loadSettings();
    _reset();
    audio.init();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _gameLoop());
  }

  // ── Persistencia ─────────────────────────────────────────────────────────────
  void _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    bestScore  = p.getInt('bestScore')  ?? 0;
    totalCoins = p.getInt('totalCoins') ?? 0;
    soundOn    = p.getBool('soundOn')   ?? true;
    audio.enabled = soundOn;
    // Skins desbloqueados
    final raw = p.getStringList('unlockedSkins') ?? ['yellow'];
    unlockedSkins = raw.map((s) => SkinId.values.firstWhere(
        (e) => e.name == s, orElse: () => SkinId.yellow)).toSet();
    final sel = p.getString('selectedSkin') ?? 'yellow';
    selectedSkin = SkinId.values.firstWhere(
        (e) => e.name == sel, orElse: () => SkinId.yellow);
    // Logros
    final ach = p.getStringList('achievements') ?? [];
    unlockedAchievements = ach.map((s) => AchievementId.values.firstWhere(
        (e) => e.name == s, orElse: () => AchievementId.firstPipe)).toSet();
    notifyListeners();
  }

  void _saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bestScore',  bestScore);
    await p.setInt('totalCoins', totalCoins);
    await p.setBool('soundOn',   soundOn);
    await p.setStringList('unlockedSkins', unlockedSkins.map((s) => s.name).toList());
    await p.setString('selectedSkin', selectedSkin.name);
    await p.setStringList('achievements', unlockedAchievements.map((a) => a.name).toList());
  }

  // ── Reset ────────────────────────────────────────────────────────────────────
  void _reset() {
    bird         = Bird(y: 0.0, velocity: 0.0);
    score        = 0;
    difficulty   = 0.0;
    isPaused     = false;
    groundScroll = 0.0;
    state        = GameState.start;
    _tick        = 0;
    _collisionEnabled = false;
    _ticksSinceStart  = 0;
    _shakeAmount      = 0.0;
    _nightBlend       = 0.0;
    _obstacleTimer    = 0.0;
    _newRecord        = false;
    obstacles         = [];
    coins             = [];
    powerUpItems      = [];
    sessionCoins      = 0;
    // Power-ups
    shieldActive       = false;
    slowMoActive       = false;
    doublePointsActive = false;
    shieldTimer = slowMoTimer = doubleTimer = 0.0;
    _powerUpTimer      = 0.0;
    _coinTimer         = 0.0;
    _nightSurvivalTime = 0.0;
    _ufoNearby         = false;
    pendingToasts      = [];

    pipes = List<Pipe>.generate(4, (i) => Pipe(
      x: 1.2 + i * GameLogic.pipeSpacing,
      gapY: GameLogic.randomGapY(),
      gapHeight: GameLogic.randomGapHeight(0),
    ));
    notifyListeners();
  }

  // ── Acciones ─────────────────────────────────────────────────────────────────
  void startGame() {
    if (state != GameState.start) return;
    state = GameState.playing;
    isPaused = false;
    _ticksSinceStart = 0;
    _collisionEnabled = false;
    if (soundOn) audio.playBackground();
    notifyListeners();
  }

  void jump() {
    if (state == GameState.gameOver) { resetGame(); return; }
    if (state == GameState.start) startGame();
    if (state != GameState.playing || isPaused) return;
    bird.jump(GameLogic.jumpVelocity);
    audio.playJump();
    HapticFeedback.lightImpact(); // ← vibración suave al saltar
    notifyListeners();
  }

  void togglePause() {
    if (state != GameState.playing && !isPaused) return;
    isPaused = !isPaused;
    isPaused ? audio.stopBackground() : (soundOn ? audio.playBackground() : null);
    notifyListeners();
  }

  void toggleSound() {
    soundOn = !soundOn;
    audio.enabled = soundOn;
    if (!soundOn) audio.stopBackground();
    else if (state == GameState.playing && !isPaused) audio.playBackground();
    _saveSettings();
    notifyListeners();
  }

  void resetGame() {
    if (score > bestScore) bestScore = score;
    totalCoins += sessionCoins;
    _saveSettings();
    audio.stopBackground();
    _reset();
  }

  // ── Skins ────────────────────────────────────────────────────────────────────
  bool canAfford(Skin skin) => totalCoins >= skin.cost;

  void buySkin(Skin skin) {
    if (!canAfford(skin)) return;
    if (unlockedSkins.contains(skin.id)) { selectSkin(skin.id); return; }
    totalCoins -= skin.cost;
    unlockedSkins.add(skin.id);
    selectSkin(skin.id);
    _tryUnlockAchievement(AchievementId.skinUnlock);
    _saveSettings();
    notifyListeners();
  }

  void selectSkin(SkinId id) {
    selectedSkin = id;
    _saveSettings();
    notifyListeners();
  }

  // ── Toast de logro consumido ──────────────────────────────────────────────────
  void dismissToast() {
    if (pendingToasts.isNotEmpty) pendingToasts.removeAt(0);
    notifyListeners();
  }

  // ── Game Loop ─────────────────────────────────────────────────────────────────
  void _gameLoop() {
    if (state != GameState.playing || isPaused) return;

    _tick++;
    _ticksSinceStart++;
    if (!_collisionEnabled && _ticksSinceStart > 20) _collisionEnabled = true;

    difficulty = (difficulty + 0.000035).clamp(0.0, 1.0);
    final baseSpeed = GameLogic.currentSpeed(difficulty) + GameLogic.nightSpeedBonus(score);
    final double speed = slowMoActive ? baseSpeed * 0.45 : baseSpeed;
    final double gravity = GameLogic.currentGravity(difficulty);

    // Física
    bird.applyGravity(gravity);
    bird.updatePosition();
    bird.animate();

    if (_shakeAmount > 0) _shakeAmount = (_shakeAmount - 0.04).clamp(0.0, 1.0);

    // Timers de power-ups activos
    if (shieldActive) {
      shieldTimer -= _dt;
      if (shieldTimer <= 0) { shieldActive = false; shieldTimer = 0; }
    }
    if (slowMoActive) {
      slowMoTimer -= _dt;
      if (slowMoTimer <= 0) { slowMoActive = false; slowMoTimer = 0; }
    }
    if (doublePointsActive) {
      doubleTimer -= _dt;
      if (doubleTimer <= 0) { doublePointsActive = false; doubleTimer = 0; }
    }

    // Tubos
    for (final pipe in pipes) {
      pipe.x -= speed;
      if (!pipe.scored && pipe.x < GameLogic.birdX) {
        final pts = doublePointsActive ? 2 : 1;
        score += pts;
        pipe.scored = true;
        audio.playScore();
        HapticFeedback.selectionClick(); // vibración al puntuar
        _checkScoreAchievements();
      }
    }
    if (pipes.first.x < -1.4) {
      final r = pipes.removeAt(0)
        ..x = pipes.last.x + GameLogic.pipeSpacing
        ..gapY = GameLogic.randomGapY()
        ..gapHeight = GameLogic.randomGapHeight(difficulty)
        ..scored = false;
      pipes.add(r);
    }

    // Monedas
    _coinTimer += _dt;
    if (_coinTimer >= _coinInterval) {
      _coinTimer = 0;
      _spawnCoin();
    }
    for (final coin in coins) coin.update(speed, _tick);
    _checkCoinCollections();
    coins.removeWhere((c) => c.collected || c.x < -1.4);

    // Power-up items en pantalla
    _powerUpTimer += _dt;
    if (_powerUpTimer >= _powerUpInterval) {
      _powerUpTimer = 0;
      _spawnPowerUpItem();
    }
    for (final p in powerUpItems) p.update(speed, _tick);
    _checkPowerUpCollections();
    powerUpItems.removeWhere((p) => p.collected || p.x < -1.4);

    // Obstáculos nocturnos
    if (isNight) {
      _nightSurvivalTime += _dt;
      if (_nightSurvivalTime >= 10) _tryUnlockAchievement(AchievementId.nightSurvivor);

      _obstacleTimer += _dt;
      if (_obstacleTimer >= _obstacleInterval) {
        _obstacleTimer = 0;
        obstacles.add(Obstacle.random(level));
      }
      for (final obs in obstacles) obs.update(_dt, _tick);

      // Logro OVNI
      _ufoNearby = obstacles.any((o) => o.type == ObstacleType.ufo &&
          (o.x - GameLogic.birdX).abs() < 0.25 && o.active);
      if (_ufoNearby) _tryUnlockAchievement(AchievementId.dodgeUfo);

      obstacles.removeWhere((o) => !o.active);
    }

    // Transición noche
    final targetBlend = isNight ? 1.0 : 0.0;
    _nightBlend += (targetBlend - _nightBlend) * 0.02;

    // Colisiones
    if (_collisionEnabled) {
      final hitPipe = GameLogic.checkCollision(bird, pipes);
      final hitObs  = isNight && GameLogic.checkObstacleCollision(bird, obstacles);
      final hitBounds = GameLogic.checkGroundCollision(bird);
      if (hitPipe || hitObs || hitBounds) {
        if (shieldActive && !hitBounds) {
          // El escudo absorbe el golpe solo en tubos y obstáculos
          shieldActive = false;
          shieldTimer  = 0;
          _shakeAmount = 0.4;
          HapticFeedback.mediumImpact();
        } else {
          _die();
          return;
        }
      }
    }

    groundScroll = (groundScroll + speed * 1.4) % 1.0;
    notifyListeners();
  }

  // ── Spawn de monedas ──────────────────────────────────────────────────────────
  void _spawnCoin() {
    // Aparece entre los tubos en una posición Y aleatoria jugable
    final y = -0.5 + _rng.nextDouble() * 0.8;
    // Pequeña cadena de 1–3 monedas juntas
    final count = 1 + _rng.nextInt(3);
    for (int i = 0; i < count; i++) {
      coins.add(Coin(x: 1.3 + i * 0.12, y: y + i * 0.04));
    }
  }

  // ── Spawn de power-up item ────────────────────────────────────────────────────
  void _spawnPowerUpItem() {
    final types = PowerUpType.values;
    final type = types[_rng.nextInt(types.length)];
    final y = -0.5 + _rng.nextDouble() * 0.8;
    powerUpItems.add(PowerUpItem(type: type, x: 1.4, y: y));
  }

  // ── Recolección de monedas ────────────────────────────────────────────────────
  void _checkCoinCollections() {
    const double hitboxFactor = 0.75;
    final double halfBird = GameLogic.birdSizeRatio * hitboxFactor / 2;
    final double bx = GameLogic.birdX, by = bird.y;

    for (final coin in coins) {
      if (coin.collected) continue;
      final dx = bx - coin.x, dy = by - coin.y;
      if (sqrt(dx*dx + dy*dy) < halfBird + Coin.radius) {
        coin.collected = true;
        sessionCoins++;
        HapticFeedback.selectionClick();
        _tryUnlockAchievement(AchievementId.coinCollector);
      }
    }
  }

  // ── Recolección de power-ups ──────────────────────────────────────────────────
  void _checkPowerUpCollections() {
    const double hitboxFactor = 0.75;
    final double halfBird = GameLogic.birdSizeRatio * hitboxFactor / 2;
    final double bx = GameLogic.birdX, by = bird.y;

    for (final item in powerUpItems) {
      if (item.collected) continue;
      final dx = bx - item.x, dy = by - item.y;
      if (sqrt(dx*dx + dy*dy) < halfBird + PowerUpItem.radius) {
        item.collected = true;
        _activatePowerUp(item.type);
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _activatePowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        shieldActive = true;
        shieldTimer  = _shieldDur;
        _tryUnlockAchievement(AchievementId.shieldUser);
      case PowerUpType.slowMo:
        slowMoActive = true;
        slowMoTimer  = _slowMoDur;
        _tryUnlockAchievement(AchievementId.slowMoUser);
      case PowerUpType.doublePoints:
        doublePointsActive = true;
        doubleTimer        = _doubleDur;
    }
    notifyListeners();
  }

  // ── Logros ────────────────────────────────────────────────────────────────────
  void _tryUnlockAchievement(AchievementId id) {
    if (unlockedAchievements.contains(id)) return;

    // Condiciones específicas
    if (id == AchievementId.coinCollector && sessionCoins < 10) return;

    unlockedAchievements.add(id);
    final achievement = kAchievements.firstWhere((a) => a.id == id);
    pendingToasts.add(achievement);
    _saveSettings();
    notifyListeners();
  }

  void _checkScoreAchievements() {
    if (score >= 1)  _tryUnlockAchievement(AchievementId.firstPipe);
    if (score >= 10) _tryUnlockAchievement(AchievementId.score10);
    if (score >= 25) _tryUnlockAchievement(AchievementId.score25);
    if (score >= 50) _tryUnlockAchievement(AchievementId.score50);
  }

  void _die() {
    state = GameState.gameOver;
    isPaused = false;
    if (score > bestScore) { bestScore = score; _newRecord = true; }
    totalCoins += sessionCoins;
    _saveSettings();
    audio.playHit();
    audio.stopBackground();
    _shakeAmount = 1.0;
    HapticFeedback.heavyImpact(); // vibración fuerte al morir
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.cancel();
    audio.dispose();
    super.dispose();
  }
}
