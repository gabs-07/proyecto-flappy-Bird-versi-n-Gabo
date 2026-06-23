// ============================================================
// services/leaderboard_service.dart
// Ranking online usando HTTP puro hacia una API REST pública
// (no necesita Firebase SDK — usa jsonbin.io como backend gratis)
//
// ALTERNATIVA CON FIREBASE: ver comentarios al final del archivo
// ============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  final String playerName;
  final int    score;
  final int    level;
  final bool   isNight;
  final String date;       // ISO 8601
  final String skinId;

  const LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.level,
    required this.isNight,
    required this.date,
    required this.skinId,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    playerName: j['name']  ?? 'Jugador',
    score:      j['score'] ?? 0,
    level:      j['level'] ?? 0,
    isNight:    j['night'] ?? false,
    date:       j['date']  ?? '',
    skinId:     j['skin']  ?? 'yellow',
  );

  Map<String, dynamic> toJson() => {
    'name':  playerName,
    'score': score,
    'level': level,
    'night': isNight,
    'date':  date,
    'skin':  skinId,
  };
}

class LeaderboardService {
  // ── Singleton ─────────────────────────────────────────────
  static final LeaderboardService _i = LeaderboardService._();
  factory LeaderboardService() => _i;
  LeaderboardService._();

  // ── Configuración ─────────────────────────────────────────
  // JSONBin.io es gratis y no requiere SDK. Crea tu bin en jsonbin.io
  // y reemplaza BIN_ID y API_KEY con los tuyos.
  //
  // Pasos:
  //   1. Entra a https://jsonbin.io y crea cuenta gratuita
  //   2. Crea un nuevo BIN con contenido: {"scores":[]}
  //   3. Copia tu BIN ID y API KEY aquí abajo
  //
  static const String _binId  = 'TU_BIN_ID_AQUI';
  static const String _apiKey = 'TU_API_KEY_AQUI';
  static const String _baseUrl = 'https://api.jsonbin.io/v3/b/$_binId';

  // Cache local para mostrar aunque no haya internet
  List<LeaderboardEntry> _cache = [];
  List<LeaderboardEntry> get cached => List.unmodifiable(_cache);

  bool _configured = false;
  bool get isConfigured => _binId != 'TU_BIN_ID_AQUI';

  // ── Obtener top 20 ────────────────────────────────────────
  Future<List<LeaderboardEntry>> fetchTop20() async {
    if (!isConfigured) return _loadLocalMock();

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/latest'),
        headers: {'X-Master-Key': _apiKey, 'X-Bin-Meta': 'false'},
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data   = jsonDecode(res.body);
        final scores = (data['scores'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        scores.sort((a, b) => b.score.compareTo(a.score));
        _cache = scores.take(20).toList();
        _saveLocalCache();
        return _cache;
      }
    } catch (_) {}

    // Fallback: cache local
    return await _loadLocalCache();
  }

  // ── Enviar puntaje ────────────────────────────────────────
  Future<bool> submitScore(LeaderboardEntry entry) async {
    if (!isConfigured) {
      _addToLocalMock(entry);
      return true;
    }

    try {
      // 1. Leer scores actuales
      final getRes = await http.get(
        Uri.parse('$_baseUrl/latest'),
        headers: {'X-Master-Key': _apiKey, 'X-Bin-Meta': 'false'},
      ).timeout(const Duration(seconds: 6));

      List<dynamic> scores = [];
      if (getRes.statusCode == 200) {
        final data = jsonDecode(getRes.body);
        scores = data['scores'] as List? ?? [];
      }

      // 2. Agregar nuevo puntaje, ordenar y mantener top 50
      scores.add(entry.toJson());
      scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      if (scores.length > 50) scores = scores.take(50).toList();

      // 3. Guardar
      final putRes = await http.put(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _apiKey,
        },
        body: jsonEncode({'scores': scores}),
      ).timeout(const Duration(seconds: 6));

      if (putRes.statusCode == 200) {
        _cache = scores
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .take(20)
            .toList();
        _saveLocalCache();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Posición del jugador ──────────────────────────────────
  int playerRank(String name, int score) {
    final sorted = [..._cache]..sort((a, b) => b.score.compareTo(a.score));
    final idx = sorted.indexWhere((e) => e.playerName == name && e.score == score);
    return idx >= 0 ? idx + 1 : -1;
  }

  // ── Persistencia local (cache offline) ───────────────────
  Future<void> _saveLocalCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lb_cache',
          jsonEncode(_cache.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<List<LeaderboardEntry>> _loadLocalCache() async {
    try {
      final p    = await SharedPreferences.getInstance();
      final raw  = p.getString('lb_cache');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _cache = list.map((e) => LeaderboardEntry.fromJson(e)).toList();
        return _cache;
      }
    } catch (_) {}
    return _loadLocalMock();
  }

  // Mock para cuando no hay configuración ni cache
  List<LeaderboardEntry> _loadLocalMock() {
    if (_cache.isEmpty) {
      _cache = [
        LeaderboardEntry(playerName:'FlappyMaster', score:88, level:17, isNight:true,  date:'', skinId:'dark'),
        LeaderboardEntry(playerName:'BirdKing',     score:72, level:14, isNight:true,  date:'', skinId:'ninja'),
        LeaderboardEntry(playerName:'NightFlyer',   score:65, level:13, isNight:true,  date:'', skinId:'blue'),
        LeaderboardEntry(playerName:'ProBird',      score:55, level:11, isNight:false, date:'', skinId:'red'),
        LeaderboardEntry(playerName:'Jugador',      score:42, level:8,  isNight:false, date:'', skinId:'yellow'),
      ];
    }
    return _cache;
  }

  void _addToLocalMock(LeaderboardEntry entry) {
    _cache.add(entry);
    _cache.sort((a,b) => b.score.compareTo(a.score));
    if (_cache.length > 20) _cache = _cache.take(20).toList();
  }
}

// ╔══════════════════════════════════════════════════════════╗
// ║  ALTERNATIVA CON FIREBASE FIRESTORE                      ║
// ╠══════════════════════════════════════════════════════════╣
// ║  1. Agrega a pubspec.yaml:                               ║
// ║     firebase_core: ^3.0.0                                ║
// ║     cloud_firestore: ^5.0.0                              ║
// ║                                                          ║
// ║  2. Crea proyecto en console.firebase.google.com         ║
// ║     Agrega app Android/iOS, descarga google-services.json║
// ║                                                          ║
// ║  3. Reemplaza fetchTop20() con:                          ║
// ║     final snap = await FirebaseFirestore.instance        ║
// ║       .collection('leaderboard')                         ║
// ║       .orderBy('score', descending: true)                ║
// ║       .limit(20).get();                                  ║
// ║     return snap.docs.map((d) =>                          ║
// ║       LeaderboardEntry.fromJson(d.data())).toList();     ║
// ╚══════════════════════════════════════════════════════════╝
