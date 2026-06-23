// ============================================================
// services/replay_recorder.dart
// Sistema de replay: graba posición del pájaro y tubos cada tick
// y permite reproducirlos como animación después
// ============================================================
import '../game/bird.dart';
import '../game/pipe.dart';

// Un snapshot del estado del juego en un tick
class ReplayFrame {
  final double birdY;
  final double birdVelocity;
  final double birdRotation;
  final int    birdFrame;
  final List<_PipeSnapshot> pipes;
  final int    score;
  final double nightBlend;

  const ReplayFrame({
    required this.birdY,
    required this.birdVelocity,
    required this.birdRotation,
    required this.birdFrame,
    required this.pipes,
    required this.score,
    required this.nightBlend,
  });
}

class _PipeSnapshot {
  final double x, gapY, gapHeight;
  const _PipeSnapshot(this.x, this.gapY, this.gapHeight);
}

class ReplayRecorder {
  static final ReplayRecorder _i = ReplayRecorder._();
  factory ReplayRecorder() => _i;
  ReplayRecorder._();

  // Máximo de frames a guardar (~10 segundos a 60fps)
  static const int _maxFrames = 600;

  final List<ReplayFrame> _frames = [];
  bool _recording = false;
  int _finalScore = 0;
  double _finalNightBlend = 0;

  bool get hasReplay => _frames.isNotEmpty;
  int get finalScore => _finalScore;
  List<ReplayFrame> get frames => List.unmodifiable(_frames);

  // ── Grabar ────────────────────────────────────────────────
  void startRecording() {
    _frames.clear();
    _recording = true;
  }

  void stopRecording(int score) {
    _recording = false;
    _finalScore = score;
  }

  void recordFrame(Bird bird, List<Pipe> pipes, int score, double nightBlend) {
    if (!_recording) return;
    // Solo guardamos los últimos _maxFrames
    if (_frames.length >= _maxFrames) _frames.removeAt(0);

    _frames.add(ReplayFrame(
      birdY:        bird.y,
      birdVelocity: bird.velocity,
      birdRotation: bird.rotation,
      birdFrame:    bird.animationFrame,
      score:        score,
      nightBlend:   nightBlend,
      pipes: pipes.map((p) => _PipeSnapshot(p.x, p.gapY, p.gapHeight)).toList(),
    ));
  }

  void clearReplay() {
    _frames.clear();
    _recording = false;
  }
}

// ── Controlador de reproducción ───────────────────────────────
class ReplayPlayer {
  final List<ReplayFrame> frames;
  int _currentIndex = 0;
  bool _playing = false;
  bool _loop;

  ReplayPlayer({required this.frames, bool loop = true}) : _loop = loop;

  bool get isPlaying  => _playing;
  bool get isFinished => _currentIndex >= frames.length;
  double get progress => frames.isEmpty ? 0 : _currentIndex / frames.length;

  ReplayFrame? get currentFrame =>
      _currentIndex < frames.length ? frames[_currentIndex] : null;

  void play()  => _playing = true;
  void pause() => _playing = false;

  void reset() {
    _currentIndex = 0;
    _playing = true;
  }

  // Avanza un tick — llamar cada 16ms desde el render loop
  ReplayFrame? tick() {
    if (!_playing || frames.isEmpty) return null;
    if (_currentIndex >= frames.length) {
      if (_loop) {
        _currentIndex = 0;
      } else {
        _playing = false;
        return null;
      }
    }
    return frames[_currentIndex++];
  }
}
