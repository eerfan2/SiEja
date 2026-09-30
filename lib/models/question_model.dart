import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:si_eja/models/game_type.dart';

// ─── LetterSequenceConfig ─────────────────────────────────────────────────────

/// Konfigurasi khusus untuk mini-game `urutkanHuruf` berbasis range huruf.
///
/// Menyimpan aturan pembangkitan soal — **bukan** hasil huruf yang sudah dipilih.
/// Pembangkitan huruf acak dilakukan di sisi Android saat soal dimuat.
///
/// Contoh dokumen Firestore:
/// ```json
/// {
///   "config": {
///     "startLetter": "F",
///     "endLetter": "Q",
///     "letterCount": 4
///   }
/// }
/// ```
class LetterSequenceConfig {
  /// Huruf awal range (uppercase, A–Z), inklusif.
  final String startLetter;

  /// Huruf akhir range (uppercase, A–Z), inklusif.
  final String endLetter;

  /// Jumlah huruf yang dipilih dalam satu soal. Nilai valid: 3, 4, 5, 6, 7.
  final int letterCount;

  const LetterSequenceConfig({
    required this.startLetter,
    required this.endLetter,
    required this.letterCount,
  });

  // ─── Nilai yang diizinkan untuk letterCount ──────────────────────────────
  static const Set<int> validCounts = {3, 4, 5, 6, 7};

  /// Parse dan validasi `config` dari Firestore.
  ///
  /// Mengembalikan [null] dan log alasan jika config tidak valid.
  /// Aman dipanggil dengan data apapun — tidak akan throw.
  static LetterSequenceConfig? fromMap(Map<String, dynamic>? configMap) {
    if (configMap == null) return null;

    try {
      final rawStart = (configMap['startLetter'] as String?)?.trim().toUpperCase() ?? '';
      final rawEnd   = (configMap['endLetter']   as String?)?.trim().toUpperCase() ?? '';
      final count    = (configMap['letterCount'] as num?)?.toInt() ?? 0;

      // 1. startLetter wajib satu karakter A-Z
      if (rawStart.length != 1 || rawStart.codeUnitAt(0) < 65 || rawStart.codeUnitAt(0) > 90) {
        debugPrint('[LetterSequenceConfig] startLetter tidak valid: "$rawStart"');
        return null;
      }

      // 2. endLetter wajib satu karakter A-Z
      if (rawEnd.length != 1 || rawEnd.codeUnitAt(0) < 65 || rawEnd.codeUnitAt(0) > 90) {
        debugPrint('[LetterSequenceConfig] endLetter tidak valid: "$rawEnd"');
        return null;
      }

      // 3. startLetter <= endLetter secara alfabet
      if (rawStart.codeUnitAt(0) > rawEnd.codeUnitAt(0)) {
        debugPrint('[LetterSequenceConfig] startLetter "$rawStart" > endLetter "$rawEnd" — ditolak');
        return null;
      }

      // 4. letterCount harus dalam {3,4,5,6,7}
      if (!validCounts.contains(count)) {
        debugPrint('[LetterSequenceConfig] letterCount $count tidak valid (harus 3–7)');
        return null;
      }

      // 5. Jumlah huruf dalam range harus >= letterCount
      final rangeSize = rawEnd.codeUnitAt(0) - rawStart.codeUnitAt(0) + 1;
      if (rangeSize < count) {
        debugPrint(
          '[LetterSequenceConfig] Range $rawStart-$rawEnd hanya punya $rangeSize huruf, '
          'tetapi letterCount = $count — ditolak',
        );
        return null;
      }

      return LetterSequenceConfig(
        startLetter: rawStart,
        endLetter: rawEnd,
        letterCount: count,
      );
    } catch (e) {
      debugPrint('[LetterSequenceConfig] Error parsing config: $e');
      return null;
    }
  }

  /// Bangun list semua huruf dalam range [startLetter]–[endLetter] (uppercase).
  List<String> get candidateLetters {
    final start = startLetter.codeUnitAt(0);
    final end   = endLetter.codeUnitAt(0);
    return List.generate(end - start + 1, (i) => String.fromCharCode(start + i));
  }

  @override
  String toString() => 'LetterSequenceConfig($startLetter-$endLetter, count=$letterCount)';
}

// ─── QuestionModel ────────────────────────────────────────────────────────────

/// Model yang merepresentasikan satu dokumen dalam collection `soal` Firestore.
///
/// Firestore hanya menyimpan metadata soal (stageId, gameType, kata, huruf).
/// Gambar dan audio tetap diambil dari local assets menggunakan [AppImages] dan
/// [AppAudio] di [app_constants.dart].
///
/// Untuk `urutkanHuruf` format baru, field [letterSequenceConfig] digunakan
/// sebagai pengganti `kata`/`huruf`. Format lama (`kata` + `huruf`) tetap
/// didukung sebagai legacy fallback.
class QuestionModel {
  /// Firestore Auto-ID dokumen.
  final String id;

  /// ID stage, contoh: 'stage1' … 'stage6'.
  final String stageId;

  /// Jenis mini-game.
  final GameType gameType;

  /// Kata utama dalam lowercase, contoh: 'ayam', 'bebek'.
  /// Untuk `urutkanHuruf` format baru, field ini kosong ('').
  final String kata;

  /// Huruf awal dari kata dalam lowercase, contoh: 'a', 'b'.
  /// Untuk `urutkanHuruf` format baru, field ini kosong ('').
  final String huruf;

  /// Hanya soal dengan isActive = true yang digunakan aplikasi.
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// UID guru pembuat soal (nullable untuk data awal yang dibuat manual).
  final String? createdBy;

  /// Konfigurasi khusus untuk `urutkanHuruf` format baru (opsional).
  /// Null untuk semua game lain dan `urutkanHuruf` format lama.
  final LetterSequenceConfig? letterSequenceConfig;

  const QuestionModel({
    required this.id,
    required this.stageId,
    required this.gameType,
    required this.kata,
    required this.huruf,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.letterSequenceConfig,
  });

  /// Factory constructor yang membuat [QuestionModel] dari dokumen Firestore.
  ///
  /// Mengembalikan [null] jika:
  /// - [gameType] tidak valid (tidak ada dalam enum [GameType])
  /// - Bukan `urutkanHuruf` config: [kata] atau [huruf] kosong
  /// - `urutkanHuruf` config ada tapi tidak valid (ditolak sesuai validasi)
  ///
  /// Caller harus mem-filter null setelah memanggil ini.
  static QuestionModel? fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Parsing gameType — aman terhadap nilai yang tidak dikenal
      final gameTypeStr = (data['gameType'] as String?)?.trim() ?? '';
      final gameType = gameTypeFromString(gameTypeStr);
      if (gameType == null) return null;

      final stageId = (data['stageId'] as String?)?.trim() ?? '';
      if (stageId.isEmpty) return null;

      final isActive = (data['isActive'] as bool?) ?? false;

      DateTime? createdAt;
      DateTime? updatedAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      }
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }

      // ── Jalur khusus: urutkanHuruf ────────────────────────────────────────
      if (gameType == GameType.urutkanHuruf) {
        final configMap = data['config'] as Map<String, dynamic>?;

        if (configMap != null) {
          // Format baru: parse dan validasi config
          final config = LetterSequenceConfig.fromMap(configMap);
          if (config == null) {
            // config ada tetapi tidak valid — skip dokumen
            debugPrint(
              '[QuestionModel] Dokumen ${doc.id} (urutkanHuruf) di-skip: '
              'config tidak valid',
            );
            return null;
          }

          return QuestionModel(
            id: doc.id,
            stageId: stageId,
            gameType: gameType,
            kata: '',   // tidak digunakan pada format baru
            huruf: '',  // tidak digunakan pada format baru
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: data['createdBy'] as String?,
            letterSequenceConfig: config,
          );
        } else {
          // Format lama (kata + huruf) — legacy fallback
          final kata  = (data['kata']  as String?)?.trim().toLowerCase() ?? '';
          final huruf = (data['huruf'] as String?)?.trim().toLowerCase() ?? '';

          if (kata.isEmpty || huruf.isEmpty) {
            debugPrint(
              '[QuestionModel] Dokumen ${doc.id} (urutkanHuruf lama) di-skip: '
              'kata/huruf kosong dan tidak ada config',
            );
            return null;
          }

          debugPrint(
            '[QuestionModel] Dokumen ${doc.id} (urutkanHuruf) diterima '
            'sebagai format lama (kata=$kata, huruf=$huruf)',
          );
          return QuestionModel(
            id: doc.id,
            stageId: stageId,
            gameType: gameType,
            kata: kata,
            huruf: huruf,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: data['createdBy'] as String?,
            letterSequenceConfig: null,
          );
        }
      }

      // ── Jalur normal: 6 game lain ─────────────────────────────────────────
      // Validasi kata & huruf tidak kosong
      final kata  = (data['kata']  as String?)?.trim().toLowerCase() ?? '';
      final huruf = (data['huruf'] as String?)?.trim().toLowerCase() ?? '';
      if (kata.isEmpty || huruf.isEmpty) return null;

      return QuestionModel(
        id: doc.id,
        stageId: stageId,
        gameType: gameType,
        kata: kata,
        huruf: huruf,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: data['createdBy'] as String?,
        letterSequenceConfig: null,
      );
    } catch (_) {
      // Tidak crash; dokumen tidak valid di-skip oleh caller.
      return null;
    }
  }

  /// Konversi ke format [Map] yang digunakan oleh [StageScreen] secara internal.
  ///
  /// Format dasar: `{'type': GameType, 'kata': String, 'huruf': String}`
  ///
  /// Untuk `urutkanHuruf` format baru, key `'letterSequenceConfig'` ditambahkan
  /// agar `_setupChoices()` dapat menggunakan config tanpa mengakses model secara langsung.
  Map<String, dynamic> toLocalMap() {
    final map = <String, dynamic>{
      'type': gameType,
      'kata': kata,
      'huruf': huruf,
    };
    if (letterSequenceConfig != null) {
      map['letterSequenceConfig'] = letterSequenceConfig;
    }
    return map;
  }

  /// Unique key untuk deteksi duplikasi dalam satu set soal.
  ///
  /// Untuk `urutkanHuruf` config, key berbasis range dan count agar
  /// dua config berbeda tidak saling menimpa.
  String get uniqueKey {
    if (letterSequenceConfig != null) {
      final c = letterSequenceConfig!;
      return 'urutkanHuruf_config_${c.startLetter}_${c.endLetter}_${c.letterCount}';
    }
    return '${gameType.name}_${kata}_$huruf';
  }

  @override
  String toString() {
    if (letterSequenceConfig != null) {
      return 'QuestionModel(id=$id, stageId=$stageId, gameType=urutkanHuruf, '
          'config=$letterSequenceConfig)';
    }
    return 'QuestionModel(id=$id, stageId=$stageId, '
        'gameType=${gameType.name}, kata=$kata, huruf=$huruf)';
  }
}
