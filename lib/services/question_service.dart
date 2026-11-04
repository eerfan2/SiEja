import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/models/game_type.dart';
import 'package:si_eja/models/question_model.dart';
import 'package:si_eja/services/material_service.dart';

/// Service untuk mengambil soal dari Cloud Firestore collection `soal`.
///
/// Gunakan instance singleton via factory constructor:
/// ```dart
/// final questions = await QuestionService().getQuestionsByStage(1);
/// ```
///
/// Jika Firestore tidak dapat diakses (offline, error, collection kosong),
/// fungsi mengembalikan list kosong — caller wajib menyediakan fallback lokal.
class QuestionService {
  // ─── Singleton ──────────────────────────────────────────────────────────────

  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // ─── Validasi stageId ────────────────────────────────────────────────────────
  static bool isValidStageId(int stageId) => stageId >= 1;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Mengambil semua soal aktif untuk [stageId] dari Firestore.
  ///
  /// Query: `collection('soal').where('stageId', isEqualTo: 'stage$stageId')
  ///                           .where('isActive', isEqualTo: true)`
  ///
  /// Hasil sudah difilter:
  /// - `gameType` valid
  /// - `kata` dan `huruf` tidak kosong
  /// - `huruf` dalam range huruf stage yang bersangkutan
  ///
  /// Mengembalikan `[]` jika terjadi error atau Firestore tidak tersedia.
  Future<List<QuestionModel>> getQuestionsByStage(int stageId) async {
    final stageKey = 'stage$stageId';

    // Defensive: pastikan stageId valid
    if (!isValidStageId(stageId)) {
      debugPrint('[QuestionService] stageId tidak valid: $stageId');
      return [];
    }

    try {
      // Pastikan katalog materi aktif sudah selesai dimuat agar validasi hasValidAsset
      // dapat mengenali kata materi dari katalog dinamis (misal: Bowo, Owl, Tedy)
      await MaterialService().loadActiveMaterials();

      final snapshot = await _firestore
          .collection('soal')
          .where('stageId', isEqualTo: stageKey)
          .where('isActive', isEqualTo: true)
          .get();

      final List<QuestionModel> results = [];

      for (final doc in snapshot.docs) {
        final model = QuestionModel.fromFirestore(doc);
        if (model == null) {
          // gameType tidak valid atau data kosong — skip
          debugPrint(
            '[QuestionService] Dokumen ${doc.id} di-skip (data tidak valid)',
          );
          continue;
        }

        // Untuk urutkanHuruf format baru: lewati validasi asset lokal
        // karena soal tidak memerlukan kata/huruf untuk asset gambar/audio.
        if (model.gameType == GameType.urutkanHuruf && model.letterSequenceConfig != null) {
          final cfg = model.letterSequenceConfig!;
          debugPrint(
            '[QuestionService] [urutkanHuruf] ${cfg.startLetter}-${cfg.endLetter} '
            '/ ${cfg.letterCount} huruf (Firestore)',
          );
          results.add(model);
          continue;
        }

        // Validasi ketersediaan asset lokal untuk game lain
        if (!QuestionService.hasValidAsset(model.huruf, model.kata)) {
          debugPrint(
            '[QuestionService] Dokumen ${doc.id} di-skip: '
            'asset tidak ditemukan untuk huruf="${model.huruf}" dan kata="${model.kata}"',
          );
          continue;
        }

        results.add(model);
      }

      debugPrint(
        '[QuestionService] Stage $stageId: ${results.length} soal aktif dari Firestore',
      );
      return results;
    } on FirebaseException catch (e) {
      debugPrint('[QuestionService] FirebaseException: ${e.code} – ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[QuestionService] Error tidak terduga: $e');
      return [];
    }
  }

  // ─── Helper validasi ─────────────────────────────────────────────────────────

  /// Memeriksa apakah [huruf] dan [kata] memiliki asset yang valid (lokal atau cloud).
  ///
  /// Memeriksa pemetaan lokal bawaan [AppImages.hurufKeKata] terlebih dahulu,
  /// kemudian memeriksa ketersediaan kata pada katalog dinamis [MaterialService].
  static bool hasValidAsset(String huruf, String kata) {
    final cleanKata = kata.toLowerCase().trim();
    final cleanHuruf = huruf.toLowerCase().trim();

    // 1. Cek pemetaan aset lokal bawaan
    final validKata = AppImages.hurufKeKata[cleanHuruf];
    if (validKata != null && validKata.toLowerCase() == cleanKata) {
      return true;
    }

    // 2. Cek ketersediaan di katalog dinamis aktif
    if (MaterialService().hasMaterial(cleanKata)) {
      return true;
    }

    return false;
  }

  /// Mengelompokkan list [QuestionModel] berdasarkan [GameType].
  ///
  /// Digunakan oleh [StageQuestionComposer] untuk memilih soal per tipe.
  static Map<GameType, List<QuestionModel>> groupByGameType(
    List<QuestionModel> questions,
  ) {
    final Map<GameType, List<QuestionModel>> grouped = {};
    for (final q in questions) {
      grouped.putIfAbsent(q.gameType, () => []).add(q);
    }
    return grouped;
  }
}
