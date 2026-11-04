import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:si_eja/models/game_type.dart';
import 'package:si_eja/models/question_model.dart';
import 'package:si_eja/services/material_service.dart';
import 'package:si_eja/services/question_service.dart';

/// Menyusun 10 soal untuk satu stage dengan prioritas:
///   1. Soal aktif dari Firestore (melalui [QuestionService])
///   2. Bank soal lokal sebagai pelengkap (menggunakan [stageKata])
///
/// Output selalu `List<Map<String, dynamic>>` dengan format:
/// `{'type': GameType, 'kata': String, 'huruf': String}`
///
/// Format ini identik dengan yang dihasilkan `_generateQuestions()` asli di
/// [StageScreen], sehingga seluruh logika permainan downstream tidak berubah.
class StageQuestionComposer {
  // ─── Singleton ──────────────────────────────────────────────────────────────

  static final StageQuestionComposer _instance =
      StageQuestionComposer._internal();
  factory StageQuestionComposer() => _instance;
  StageQuestionComposer._internal();

  final QuestionService _questionService = QuestionService();
  final Random _random = Random();

  // ─── Data lokal (diambil dari stage_screen.dart — TIDAK DIUBAH) ─────────────

  /// Kata per stage — identik dengan [stageKata] di StageScreen.
  static const Map<int, List<String>> _stageKata = {
    1: ['ayam', 'bebek', 'cicak', 'domba', 'elang'],
    2: ['feri', 'gajah', 'harimau', 'ikan', 'jerapah'],
    3: ['kucing', 'lebah', 'monyet', 'nanas', 'onta'],
    4: ['panda', 'quran', 'rusa', 'singa', 'tikus'],
    5: ['ulat', 'vas', 'wortel', 'xilofon', 'yoyo', 'zebra'],
    6: [
      'ayam', 'bebek', 'cicak', 'domba', 'elang', 'feri',
      'gajah', 'harimau', 'ikan', 'jerapah', 'kucing',
      'lebah', 'monyet', 'nanas', 'onta', 'panda', 'quran',
      'rusa', 'singa', 'tikus', 'ulat', 'vas', 'wortel',
      'xilofon', 'yoyo', 'zebra',
    ],
  };

  /// Komposisi soal per stage — identik dengan [stageKomposisi] di StageScreen.
  static const Map<int, List<Map<String, dynamic>>> _stageKomposisi = {
    1: [
      {'type': GameType.dengarSuaraHuruf, 'count': 5},
      {'type': GameType.tebakGambarObjek, 'count': 5},
    ],
    2: [
      {'type': GameType.dengarSuaraHuruf, 'count': 4},
      {'type': GameType.tebakGambarObjek, 'count': 3},
      {'type': GameType.hurufYangHilang, 'count': 3},
    ],
    3: [
      {'type': GameType.dengarSuaraHuruf, 'count': 3},
      {'type': GameType.tebakGambarObjek, 'count': 3},
      {'type': GameType.hurufYangHilang, 'count': 2},
      {'type': GameType.hurufAwalApa, 'count': 2},
    ],
    4: [
      {'type': GameType.dengarSuaraHuruf, 'count': 2},
      {'type': GameType.tebakGambarObjek, 'count': 2},
      {'type': GameType.hurufYangHilang, 'count': 2},
      {'type': GameType.hurufAwalApa, 'count': 2},
      {'type': GameType.cocokkanHuruf, 'count': 2},
    ],
    5: [
      {'type': GameType.tebakGambarObjek, 'count': 2},
      {'type': GameType.hurufYangHilang, 'count': 2},
      {'type': GameType.susunKata, 'count': 3},
      {'type': GameType.urutkanHuruf, 'count': 3},
    ],
    6: [
      {'type': GameType.dengarSuaraHuruf, 'count': 1},
      {'type': GameType.tebakGambarObjek, 'count': 1},
      {'type': GameType.hurufYangHilang, 'count': 1},
      {'type': GameType.hurufAwalApa, 'count': 1},
      {'type': GameType.cocokkanHuruf, 'count': 2},
      {'type': GameType.urutkanHuruf, 'count': 2},
      {'type': GameType.susunKata, 'count': 2},
    ],
  };

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Menyusun 10 soal untuk [stageId].
  ///
  /// Alur:
  /// 1. Ambil soal aktif dari Firestore (via [QuestionService])
  /// 2. Kocok dan ambil maksimal 10 soal valid dari Firestore (tanpa batasan komposisi)
  /// 3. Jika kurang dari 10, tambah dari bank lokal (mengikuti komposisi default)
  /// 4. Kocok hasil akhir
  ///
  /// Mengembalikan soal lokal saja jika Firestore tidak tersedia atau kosong.
  Future<List<Map<String, dynamic>>> compose(int stageId) async {
    // ── 0. Pastikan katalog materi aktif sudah siap ────────────────────────────
    try {
      await MaterialService().loadActiveMaterials();
    } catch (_) {}

    // ── 1. Ambil soal dari Firestore ──────────────────────────────────────────
    List<QuestionModel> firestoreQuestions = [];
    try {
      firestoreQuestions = await _questionService.getQuestionsByStage(stageId);
    } catch (_) {
      // Firestore gagal → gunakan lokal sepenuhnya
      debugPrint('[Composer] Firestore gagal — full fallback lokal');
    }
    
    final List<Map<String, dynamic>> result = [];
    final Set<String> usedKeys = {};

    // ── 2. Soal dari Firestore ───────────────────────────────────────────────
    // Ambil semua yang valid tanpa peduli tipe game, maksimal 10
    final firestoreCandidates = List<QuestionModel>.from(firestoreQuestions)..shuffle(_random);
    
    for (final q in firestoreCandidates) {
      if (result.length >= 10) break;
      final key = q.uniqueKey;
      if (!usedKeys.contains(key)) {
        final map = q.toLocalMap();
        map['source'] = 'Firestore';
        result.add(map);
        usedKeys.add(key);
      }
    }

    final int countFromFirestore = result.length;

    // ── 3. Fallback lokal jika kurang dari 10 ────────────────────────────────
    if (result.length < 10) {
      final needed = 10 - result.length;
      debugPrint(
        '[Composer] Soal aktif Firestore: $countFromFirestore. Mengambil $needed soal pelengkap dari Default Lokal.',
      );
      _padWithLocal(stageId, result, usedKeys);
    }

    // Berikan tag sumber pada soal pelengkap
    for (final item in result) {
      item.putIfAbsent('source', () => 'Default Lokal');
    }

    result.shuffle(_random);

    final finalQuestions = result.take(10).toList();

    // ── Cetak Informasi Sumber Soal ke Terminal ─────────────────────────────
    final int fromFirestore = finalQuestions.where((q) => q['source'] == 'Firestore').length;
    final int fromLocal = finalQuestions.where((q) => q['source'] == 'Default Lokal').length;

    debugPrint('╔══════════════════════════════════════════════════════════════════');
    debugPrint('║ 🎮 [SiEja] KOMPOSISI 10 SOAL SESI BERMAIN — STAGE $stageId');
    debugPrint('║ 📊 Ringkasan: $fromFirestore Soal Firestore | $fromLocal Soal Default Lokal');
    debugPrint('╟──────────────────────────────────────────────────────────────────');
    for (int i = 0; i < finalQuestions.length; i++) {
      final q = finalQuestions[i];
      final isFirestore = q['source'] == 'Firestore';
      final srcTag = isFirestore ? '🔥 [FIRESTORE]' : '📦 [DEFAULT]  ';
      final typeStr = q['type'] is GameType ? (q['type'] as GameType).name : q['type'].toString();
      final detail = q['type'] == GameType.urutkanHuruf
          ? 'Urutkan Huruf (${q['letterSequenceConfig']?.startLetter ?? 'A'}-${q['letterSequenceConfig']?.endLetter ?? 'Z'})'
          : 'Kata: "${q['kata']}", Huruf: "${q['huruf']?.toString().toUpperCase()}"';
      debugPrint('║ ${(i + 1).toString().padLeft(2)}. $srcTag $typeStr -> $detail');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════════');

    return finalQuestions;
  }

  // ─── Helper: bangun kandidat lokal untuk satu tipe ─────────────────────────

  /// Membuat list soal lokal untuk [stageId] dan [type], mengecualikan key
  /// yang sudah ada di [usedKeys].
  List<Map<String, dynamic>> _buildLocalCandidates(
    int stageId,
    GameType type,
    Set<String> usedKeys,
  ) {
    final kata = _stageKata[stageId] ?? _stageKata[6]!;
    final List<Map<String, dynamic>> candidates = [];

    for (final k in kata) {
      final h = k[0].toLowerCase();
      final key = '${type.name}_${k}_$h';
      if (!usedKeys.contains(key)) {
        candidates.add({'type': type, 'kata': k, 'huruf': h});
      }
    }

    // Jika semua kata sudah dipakai untuk tipe ini, boleh duplikasi kata
    // (berbeda uniqueKey karena tipe berbeda, ini fallback terakhir)
    if (candidates.isEmpty) {
      for (final k in kata) {
        final h = k[0].toLowerCase();
        candidates.add({'type': type, 'kata': k, 'huruf': h});
      }
    }

    return candidates;
  }

  /// Tambah soal lokal ke [result] sampai 10 soal tercapai.
  void _padWithLocal(
    int stageId,
    List<Map<String, dynamic>> result,
    Set<String> usedKeys,
  ) {
    final kata = _stageKata[stageId] ?? _stageKata[6]!;
    final komposisi = _stageKomposisi[stageId] ?? _stageKomposisi[6]!;

    // Iterasi komposisi sebagai panduan tipe
    for (final kompo in komposisi) {
      if (result.length >= 10) break;
      final type = kompo['type'] as GameType;
      final candidates = List<Map<String, dynamic>>.from(
        _buildLocalCandidates(stageId, type, usedKeys),
      )..shuffle(_random);

      for (final q in candidates) {
        if (result.length >= 10) break;
        final key = '${type.name}_${q['kata']}_${q['huruf']}';
        result.add(q);
        usedKeys.add(key);
      }
    }

    // Fallback terakhir: apapun yang ada di kata stage
    if (result.length < 10) {
      for (final k in kata) {
        if (result.length >= 10) break;
        final type = (komposisi.first['type'] as GameType);
        result.add({'type': type, 'kata': k, 'huruf': k[0].toLowerCase()});
      }
    }
  }

  // ─── Expose data lokal untuk keperluan test ──────────────────────────────────

  /// Mengembalikan referensi data kata lokal (hanya untuk testing).
  @visibleForTesting
  static Map<int, List<String>> get stageKataForTest => _stageKata;

  /// Mengembalikan referensi komposisi (hanya untuk testing).
  @visibleForTesting
  static Map<int, List<Map<String, dynamic>>> get stageKomposisiForTest =>
      _stageKomposisi;
}
