import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';

class AudioController {
  late final AudioPlayer _backgroundPlayer;
  final AudioPlayer _effectsPlayer = AudioPlayer();
  bool enabled = true;
  final Queue<String> _effectQueue = Queue<String>();
  bool _isProcessingQueue = false;
  static const Duration _effectCooldown = Duration(milliseconds: 120);

  AudioController() {
    _backgroundPlayer = AudioPlayer(playerId: 'bgm_player');
  }

  Future<void> init() async {
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    _backgroundPlayer.setVolume(enabled ? 0.45 : 0.0);
    _effectsPlayer.setVolume(enabled ? 0.9 : 0.0);
  }

  Future<void> playBackground() async {
    if (!enabled) return;
    try {
      await _backgroundPlayer.setSource(AssetSource('audio/musica_de_fondo.mp3'));
      await _backgroundPlayer.resume();
    } catch (_) {
      // Se ignoran fallos de audio para que el juego siga funcionando.
    }
  }

  Future<void> stopBackground() async {
    try {
      await _backgroundPlayer.pause();
    } catch (_) {
      // Ignorar errores silenciosos.
    }
  }

  Future<void> playJump() async {
    if (!enabled) return;
    await _playEffect('audio/game-jump.mp3');
  }

  Future<void> playScore() async {
    if (!enabled) return;
    // No se dispone de sonido de score en assets actualmente.
    // Dejar como no-op para evitar errores; agregar asset si se desea.
  }

  Future<void> playHit() async {
    if (!enabled) return;
    await _playEffect('audio/game-over.mp3');
  }

  Future<void> _playEffect(String assetPath) async {
    // Encolar el efecto y procesar la cola secuencialmente con un
    // pequeño cooldown para evitar solapamientos.
    final asset = assetPath.replaceFirst('audio/', '');
    _effectQueue.addLast(asset);
    if (!_isProcessingQueue) await _processEffectQueue();
  }

  Future<void> _processEffectQueue() async {
    _isProcessingQueue = true;
    while (_effectQueue.isNotEmpty) {
      final asset = _effectQueue.removeFirst();
      try {
        await _effectsPlayer.play(AssetSource(asset));
      } catch (_) {
        // Ignorar errores para que la cola siga procesando.
      }
      // Esperar un pequeño cooldown antes del siguiente efecto
      await Future.delayed(_effectCooldown);
    }
    _isProcessingQueue = false;
  }

  Future<void> dispose() async {
    await _backgroundPlayer.dispose();
    await _effectsPlayer.dispose();
  }
}
