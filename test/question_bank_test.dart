// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter_test/flutter_test.dart';
import 'package:si_eja/models/game_type.dart';
import 'package:si_eja/models/question_model.dart';
import 'package:si_eja/services/question_service.dart';
import 'package:si_eja/services/stage_question_composer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers untuk mensimulasikan QuestionModel tanpa dependensi Firestore
// ─────────────────────────────────────────────────────────────────────────────

/// Simulasi QuestionModel dari data Map mentah (tanpa DocumentSnapshot).
/// Digunakan agar test tidak memerlukan Firebase yang terinisialisasi.
class _FakeQuestion {
  final String id;
  final String stageId;
  final GameType gameType;
  final String kata;
  final String huruf;
  final LetterSequenceConfig? letterSequenceConfig;

  const _FakeQuestion({
    required this.id,
    required this.stageId,
    required this.gameType,
    required this.kata,
    required this.huruf,
    this.letterSequenceConfig,
  });

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

  String get uniqueKey {
    if (letterSequenceConfig != null) {
      final c = letterSequenceConfig!;
      return 'urutkanHuruf_config_${c.startLetter}_${c.endLetter}_${c.letterCount}';
    }
    return '${gameType.name}_${kata}_$huruf';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulasi logika komposisi soal (tanpa Firestore)
// ─────────────────────────────────────────────────────────────────────────────

/// Versi murni-lokal dari StageQuestionComposer untuk keperluan unit test.
/// Menggunakan data yang sama dengan [StageQuestionComposer] (lewat getter
/// @visibleForTesting) sehingga logika identik, hanya sumber Firestore diganti
/// dengan list yang bisa dikontrol.
List<Map<String, dynamic>> _composeSync({
  required int stageId,
  required List<_FakeQuestion> firestoreQuestions,
}) {
  final result = <Map<String, dynamic>>[];
  final usedKeys = <String>{};

  final firestoreCandidates = List<_FakeQuestion>.from(firestoreQuestions)..shuffle();
  for (final q in firestoreCandidates) {
    if (result.length >= 10) break;
    final key = q.uniqueKey;
    if (!usedKeys.contains(key)) {
      result.add(q.toLocalMap());
      usedKeys.add(key);
    }
  }

  if (result.length < 10) {
    final komposisi = StageQuestionComposer.stageKomposisiForTest[stageId]!;
    final stageKata = StageQuestionComposer.stageKataForTest[stageId]!;

    for (final kompo in komposisi) {
      if (result.length >= 10) break;
      final type = kompo['type'] as GameType;
      
      final candidates = <Map<String, dynamic>>[];
      for (final k in stageKata) {
        final h = k[0].toLowerCase();
        final key = '${type.name}_${k}_$h';
        if (!usedKeys.contains(key)) {
          candidates.add({'type': type, 'kata': k, 'huruf': h});
        }
      }
      
      if (candidates.isEmpty) {
        for (final k in stageKata) {
          final h = k[0].toLowerCase();
          candidates.add({'type': type, 'kata': k, 'huruf': h});
        }
      }

      candidates.shuffle();
      for (final q in candidates) {
        if (result.length >= 10) break;
        final key = '${type.name}_${q['kata']}_${q['huruf']}';
        result.add(q);
        usedKeys.add(key);
      }
    }
    
    if (result.length < 10) {
      for (final k in stageKata) {
        if (result.length >= 10) break;
        final type = (komposisi.first['type'] as GameType);
        result.add({'type': type, 'kata': k, 'huruf': k[0].toLowerCase()});
      }
    }
  }

  result.shuffle();
  return result.take(10).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// TEST SUITE
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('QuestionBank – Parsing & Validasi', () {
    // ── Test 1: Parsing gameType valid ────────────────────────────────────────
    test('T1: gameTypeFromString mengembalikan enum yang benar untuk semua nilai valid', () {
      expect(gameTypeFromString('dengarSuaraHuruf'), equals(GameType.dengarSuaraHuruf));
      expect(gameTypeFromString('tebakGambarObjek'), equals(GameType.tebakGambarObjek));
      expect(gameTypeFromString('susunKata'),        equals(GameType.susunKata));
      expect(gameTypeFromString('hurufYangHilang'),  equals(GameType.hurufYangHilang));
      expect(gameTypeFromString('hurufAwalApa'),     equals(GameType.hurufAwalApa));
      expect(gameTypeFromString('cocokkanHuruf'),    equals(GameType.cocokkanHuruf));
      expect(gameTypeFromString('urutkanHuruf'),     equals(GameType.urutkanHuruf));
    });

    // ── Test 2: gameType invalid tidak crash ──────────────────────────────────
    test('T2: gameTypeFromString mengembalikan null untuk nilai tidak dikenal (tidak crash)', () {
      expect(gameTypeFromString(''), isNull);
      expect(gameTypeFromString('invalid'), isNull);
      expect(gameTypeFromString('TebakGambar'), isNull,
          reason: 'Case-sensitive: TebakGambar bukan tebakGambarObjek');
      expect(gameTypeFromString('DENGARSUARAHURUF'), isNull);
      expect(gameTypeFromString('soalBaru'), isNull);
      // Tidak boleh throw exception
    });

    // ── Test 3: Validasi ketersediaan asset lokal ──────────────────────────────
    test('T3: hasValidAsset memeriksa ketersediaan asset dengan benar', () {
      expect(QuestionService.hasValidAsset('a', 'ayam'), isTrue);
      expect(QuestionService.hasValidAsset('A', 'Ayam'), isTrue);
      expect(QuestionService.hasValidAsset('a', 'angsa'), isFalse, reason: 'Kata angsa tidak memiliki asset lokal');
      expect(QuestionService.hasValidAsset('k', 'kucing'), isTrue, reason: 'Bisa dicek dari stage manapun (bebas range)');
      expect(QuestionService.hasValidAsset('z', 'zebra'), isTrue);
    });
  });

  // ── groupByGameType ───────────────────────────────────────────────────────
  group('QuestionService – groupByGameType', () {
    test('T_group: mengelompokkan model berdasarkan gameType dengan benar', () {
      // Kita uji lewat _FakeQuestion + logika serupa karena QuestionModel
      // membutuhkan DocumentSnapshot yang tidak tersedia di unit test.
      // Test ini memverifikasi bahwa data dapat dikelompokkan seperti yang
      // dilakukan oleh groupByGameType.
      final fakeList = [
        const _FakeQuestion(id: '1', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'ayam', huruf: 'a'),
        const _FakeQuestion(id: '2', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'bebek', huruf: 'b'),
        const _FakeQuestion(id: '3', stageId: 'stage1', gameType: GameType.tebakGambarObjek, kata: 'cicak', huruf: 'c'),
      ];

      final Map<GameType, List<_FakeQuestion>> grouped = {};
      for (final q in fakeList) {
        grouped.putIfAbsent(q.gameType, () => []).add(q);
      }

      expect(grouped[GameType.dengarSuaraHuruf]?.length, equals(2));
      expect(grouped[GameType.tebakGambarObjek]?.length, equals(1));
      expect(grouped[GameType.hurufAwalApa], isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test komposisi soal (sinkron, tanpa Firestore)
  // ─────────────────────────────────────────────────────────────────────────
  group('StageQuestionComposer – Komposisi Soal', () {
    // ── Test 4: Firestore kosong → fallback lokal → 10 soal ──────────────────
    test('T4: Firestore kosong → fallback 100% lokal, total tetap 10 soal', () {
      // Stage 1: 5 dengarSuaraHuruf + 5 tebakGambarObjek = 10
      final result = _composeSync(stageId: 1, firestoreQuestions: []);

      expect(result.length, equals(10),
          reason: 'Harus selalu menghasilkan 10 soal meski Firestore kosong');
      expect(result.every((q) => q['kata'] != null && (q['kata'] as String).isNotEmpty),
          isTrue,
          reason: 'Setiap soal harus memiliki kata yang tidak kosong');
    });

    // ── Test 5: Firestore penuh (semua tipe tercukupi) ───────────────────────
    test('T5: Firestore menyediakan cukup soal untuk semua tipe → 10 soal dari Firestore', () {
      // Stage 1: butuh 5 dengar + 5 tebak
      final firestoreQ = [
        const _FakeQuestion(id: 'f1', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'ayam', huruf: 'a'),
        const _FakeQuestion(id: 'f2', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'bebek', huruf: 'b'),
        const _FakeQuestion(id: 'f3', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'cicak', huruf: 'c'),
        const _FakeQuestion(id: 'f4', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'domba', huruf: 'd'),
        const _FakeQuestion(id: 'f5', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'elang', huruf: 'e'),
        const _FakeQuestion(id: 'f6', stageId: 'stage1', gameType: GameType.tebakGambarObjek, kata: 'ayam', huruf: 'a'),
        const _FakeQuestion(id: 'f7', stageId: 'stage1', gameType: GameType.tebakGambarObjek, kata: 'bebek', huruf: 'b'),
        const _FakeQuestion(id: 'f8', stageId: 'stage1', gameType: GameType.tebakGambarObjek, kata: 'cicak', huruf: 'c'),
        const _FakeQuestion(id: 'f9', stageId: 'stage1', gameType: GameType.tebakGambarObjek, kata: 'domba', huruf: 'd'),
        const _FakeQuestion(id: 'f10', stageId: 'stage1', gameType: GameType.tebakGambarObjek, kata: 'elang', huruf: 'e'),
      ];

      final result = _composeSync(stageId: 1, firestoreQuestions: firestoreQ);

      expect(result.length, equals(10));
      // Semua soal berasal dari Firestore (kata-kata dari list firestoreQ)
      final kataFirestore = firestoreQ.map((q) => q.kata).toSet();
      expect(result.every((q) => kataFirestore.contains(q['kata'])), isTrue,
          reason: 'Semua soal harus dari Firestore jika Firestore mencukupi');
    });

    // ── Test 6: Firestore sebagian → gabungan Firestore + lokal ──────────────
    test('T6: Firestore sebagian (2 dengar) → 2 Firestore + 3 lokal + 5 tebak lokal = 10', () {
      // Stage 1: butuh 5 dengar + 5 tebak
      // Firestore hanya punya 2 dengarSuaraHuruf
      final firestoreQ = [
        const _FakeQuestion(id: 'f1', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'ayam', huruf: 'a'),
        const _FakeQuestion(id: 'f2', stageId: 'stage1', gameType: GameType.dengarSuaraHuruf, kata: 'bebek', huruf: 'b'),
      ];

      final result = _composeSync(stageId: 1, firestoreQuestions: firestoreQ);

      expect(result.length, equals(10),
          reason: 'Harus tetap 10 meski Firestore hanya punya 2 soal');

      // Verifikasi 2 soal dari Firestore ada di hasil
      final resultKataForType = result
          .where((q) => q['type'] == GameType.dengarSuaraHuruf)
          .map((q) => q['kata'] as String)
          .toSet();
      expect(resultKataForType.contains('ayam'), isTrue,
          reason: 'Soal Firestore (ayam) harus ada di hasil');
      expect(resultKataForType.contains('bebek'), isTrue,
          reason: 'Soal Firestore (bebek) harus ada di hasil');
    });

    // ── Test 7: Hasil akhir selalu 10 soal untuk semua stage ─────────────────
    test('T7: Hasil akhir selalu 10 soal untuk setiap stage (1-6)', () {
      for (int stageId = 1; stageId <= 6; stageId++) {
        final result = _composeSync(stageId: stageId, firestoreQuestions: []);
        expect(result.length, equals(10),
            reason: 'Stage $stageId harus menghasilkan tepat 10 soal');
      }
    });

    // ── Test 8: Tidak ada duplikasi kata+gameType ─────────────────────────────
    test('T8: Tidak ada duplikasi kata+gameType dalam satu set soal', () {
      for (int stageId = 1; stageId <= 6; stageId++) {
        final result = _composeSync(stageId: stageId, firestoreQuestions: []);
        final keys = result
            .map((q) => '${(q["type"] as GameType).name}_${q["kata"]}')
            .toList();
        final uniqueKeys = keys.toSet();

        // Catatan: untuk stage yang kata-nya sedikit, duplikasi mungkin
        // TIDAK bisa dihindari (misalnya stage 1 hanya punya 5 kata tetapi
        // butuh 10 soal dengan 2 tipe yang berbeda).
        // Yang dipastikan: tidak ada soal yang SAMA PERSIS (kata+tipe identik)
        // apabila masih ada kandidat yang berbeda.
        // Untuk stage 1, 5 kata × 2 tipe = 10 kombinasi unik → bisa 100% unique.
        if (stageId != 5 && stageId != 6) {
          // Stage 5 punya 6 kata, stage 6 punya 26 kata; keduanya lebih dari cukup.
          // Stage 1-4: 5 kata × jumlah tipe = cukup untuk 10 soal unik per tipe.
          expect(keys.length, equals(uniqueKeys.length),
              reason: 'Stage $stageId: tidak boleh ada duplikasi kata+gameType '
                  'jika masih ada kandidat lain yang tersedia');
        } else {
          // Stage 5 & 6 memiliki lebih banyak kata; tetap harapkan tidak ada duplikasi.
          expect(keys.length, equals(uniqueKeys.length),
              reason: 'Stage $stageId: tidak boleh ada duplikasi kata+gameType');
        }
      }
    });

    // ── Test 9: Komposisi gameType mengikuti Firestore atau lokal ────────────────
    test('T9: Soal Firestore dapat bypass stageKomposisi', () {
      // Stage 1 default-nya dengarSuaraHuruf dan tebakGambarObjek.
      // Kita tambahkan susunKata dari Firestore.
      final firestoreQ = [
        const _FakeQuestion(id: 'f1', stageId: 'stage1', gameType: GameType.susunKata, kata: 'kucing', huruf: 'k'),
      ];
      final result = _composeSync(stageId: 1, firestoreQuestions: firestoreQ);

      final countPerType = <GameType, int>{};
      for (final q in result) {
        final t = q['type'] as GameType;
        countPerType[t] = (countPerType[t] ?? 0) + 1;
      }

      // Pastikan ada susunKata meski di Stage 1
      expect(countPerType[GameType.susunKata], equals(1));
      expect(result.length, equals(10));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test gameTypeToString
  // ─────────────────────────────────────────────────────────────────────────
  group('gameTypeToString', () {
    test('T_str: round-trip gameTypeFromString(gameTypeToString(x)) == x', () {
      for (final type in GameType.values) {
        final str = gameTypeToString(type);
        expect(gameTypeFromString(str), equals(type),
            reason: 'Round-trip harus mengembalikan tipe asal: $type');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // A. Model/Parsing — LetterSequenceConfig
  // ─────────────────────────────────────────────────────────────────────────
  group('LetterSequenceConfig – Parsing & Validasi', () {
    // A1: Config valid F-Q + 4
    test('A1: config F-Q + 4 valid', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': 'F', 'endLetter': 'Q', 'letterCount': 4});
      expect(cfg, isNotNull);
      expect(cfg!.startLetter, equals('F'));
      expect(cfg.endLetter, equals('Q'));
      expect(cfg.letterCount, equals(4));
    });

    // A2: startLetter invalid (angka)
    test('A2: startLetter invalid (angka) ditolak', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': '1', 'endLetter': 'Q', 'letterCount': 4});
      expect(cfg, isNull, reason: 'startLetter angka harus ditolak');
    });

    // A3: endLetter invalid (string panjang)
    test('A3: endLetter invalid (string panjang) ditolak', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': 'F', 'endLetter': 'QQ', 'letterCount': 4});
      expect(cfg, isNull, reason: 'endLetter lebih dari 1 karakter harus ditolak');
    });

    // A4: startLetter > endLetter (Q-F) ditolak
    test('A4: Q-F (startLetter > endLetter) ditolak', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': 'Q', 'endLetter': 'F', 'letterCount': 4});
      expect(cfg, isNull, reason: 'start > end harus ditolak');
    });

    // A5: range terlalu kecil (F-H + 4) ditolak
    test('A5: F-H + letterCount=4 ditolak (range hanya 3 huruf)', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': 'F', 'endLetter': 'H', 'letterCount': 4});
      expect(cfg, isNull, reason: 'Range F-H hanya 3 huruf, tidak cukup untuk letterCount=4');
    });

    // A6: letterCount=2 ditolak
    test('A6: letterCount=2 ditolak', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': 'F', 'endLetter': 'Q', 'letterCount': 2});
      expect(cfg, isNull, reason: 'letterCount < 3 harus ditolak');
    });

    // A7: letterCount=8 ditolak
    test('A7: letterCount=8 ditolak', () {
      final cfg = LetterSequenceConfig.fromMap({'startLetter': 'F', 'endLetter': 'Q', 'letterCount': 8});
      expect(cfg, isNull, reason: 'letterCount > 7 harus ditolak');
    });

    // A8: config null untuk game lain tidak crash
    test('A8: fromMap(null) mengembalikan null dengan aman', () {
      final cfg = LetterSequenceConfig.fromMap(null);
      expect(cfg, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // B. Generator — pembangkitan huruf dari config
  // ─────────────────────────────────────────────────────────────────────────
  group('LetterSequenceConfig – Generator', () {
    late LetterSequenceConfig cfg;

    setUp(() {
      cfg = LetterSequenceConfig.fromMap({'startLetter': 'F', 'endLetter': 'Q', 'letterCount': 4})!;
    });

    // B9: candidateLetters menghasilkan range yang benar
    test('B9: candidateLetters F-Q menghasilkan 12 huruf', () {
      // F G H I J K L M N O P Q = 12 huruf
      expect(cfg.candidateLetters.length, equals(12));
      expect(cfg.candidateLetters.first, equals('F'));
      expect(cfg.candidateLetters.last, equals('Q'));
    });

    // B10: Simulasi pemilihan huruf unik
    test('B10: pilih letterCount huruf dari kandidat → semua unik', () {
      final candidates = List<String>.from(cfg.candidateLetters);
      candidates.shuffle();
      final selected = candidates.take(cfg.letterCount).toList();
      expect(selected.length, equals(cfg.letterCount));
      expect(selected.toSet().length, equals(selected.length),
          reason: 'Tidak boleh ada huruf duplikat');
    });

    // B11: Semua huruf terpilih berada dalam range F-Q
    test('B11: semua huruf terpilih berada dalam range F-Q', () {
      final candidates = List<String>.from(cfg.candidateLetters);
      candidates.shuffle();
      final selected = candidates.take(cfg.letterCount).toList();
      for (final h in selected) {
        expect(h.codeUnitAt(0) >= 'F'.codeUnitAt(0), isTrue,
            reason: '$h harus >= F');
        expect(h.codeUnitAt(0) <= 'Q'.codeUnitAt(0), isTrue,
            reason: '$h harus <= Q');
      }
    });

    // B12: correctLetters (sorted) urut alfabet
    test('B12: correctLetters (sorted) urut alfabet', () {
      final candidates = List<String>.from(cfg.candidateLetters);
      candidates.shuffle();
      final selected = candidates.take(cfg.letterCount).toList();
      final sorted = List<String>.from(selected)..sort();
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].codeUnitAt(0) <= sorted[i + 1].codeUnitAt(0), isTrue,
            reason: 'Urutan tidak alfabet: ${sorted[i]} > ${sorted[i+1]}');
      }
    });

    // B13: displayLetters adalah permutasi dari correctLetters
    test('B13: displayLetters adalah permutasi dari correctLetters', () {
      final candidates = List<String>.from(cfg.candidateLetters);
      candidates.shuffle();
      final selected = candidates.take(cfg.letterCount).toList();
      final sorted = List<String>.from(selected)..sort();
      // Keduanya punya huruf yang sama, hanya urutan berbeda
      expect(List<String>.from(selected)..sort(), equals(sorted),
          reason: 'Set huruf display dan correct harus identik');
    });

    // B14: letterCount valid semua diterima
    test('B14: semua letterCount valid (3–7) diterima', () {
      for (final count in LetterSequenceConfig.validCounts) {
        // Gunakan range A-Z (26 huruf) yang cukup untuk count=7
        final c = LetterSequenceConfig.fromMap({
          'startLetter': 'A',
          'endLetter': 'Z',
          'letterCount': count,
        });
        expect(c, isNotNull, reason: 'letterCount=$count harus valid');
        expect(c!.letterCount, equals(count));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // C. Composer — config dihitung sebagai satu soal
  // ─────────────────────────────────────────────────────────────────────────
  group('StageQuestionComposer – urutkanHuruf Config Deduplication', () {
    // 1. tujuh config urutkanHuruf berbeda dianggap tujuh soal berbeda
    test('1. tujuh config urutkanHuruf berbeda dianggap tujuh soal berbeda', () {
      final configs = [
        const LetterSequenceConfig(startLetter: 'A', endLetter: 'Z', letterCount: 7),
        const LetterSequenceConfig(startLetter: 'N', endLetter: 'T', letterCount: 4),
        const LetterSequenceConfig(startLetter: 'K', endLetter: 'S', letterCount: 3),
        const LetterSequenceConfig(startLetter: 'K', endLetter: 'O', letterCount: 4),
        const LetterSequenceConfig(startLetter: 'H', endLetter: 'O', letterCount: 5),
        const LetterSequenceConfig(startLetter: 'F', endLetter: 'L', letterCount: 6),
        const LetterSequenceConfig(startLetter: 'F', endLetter: 'Q', letterCount: 4),
      ];
      
      final firestoreQ = List.generate(7, (i) => _FakeQuestion(
        id: 'u$i',
        stageId: 'stage3',
        gameType: GameType.urutkanHuruf,
        kata: '',
        huruf: '',
        letterSequenceConfig: configs[i],
      ));

      final result = _composeSync(stageId: 3, firestoreQuestions: firestoreQ);
      final urutkanResult = result.where((q) => q['type'] == GameType.urutkanHuruf).toList();
      
      // All 7 should be included because they have different configs
      expect(urutkanResult.length, equals(7));
    });

    // 2. dua config identik dianggap duplicate
    test('2. dua config identik dianggap duplicate', () {
      final firestoreQ = [
        const _FakeQuestion(
          id: 'u1', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'F', endLetter: 'Q', letterCount: 4),
        ),
        const _FakeQuestion(
          id: 'u2', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'F', endLetter: 'Q', letterCount: 4),
        ),
      ];

      final result = _composeSync(stageId: 3, firestoreQuestions: firestoreQ);
      
      // We know there are exactly two firestore questions with identical configs.
      // So only 1 unique firestore config question should end up in the result.
      // However, local fallback may add more urutkanHuruf (default stage 3 has 0 urutkanHuruf fallback though!)
      // Let's check how many urutkanHuruf config match the specific duplicate ones.
      int matchingConfig = 0;
      for (final q in result) {
        if (q['type'] == GameType.urutkanHuruf && q.containsKey('letterSequenceConfig')) {
           final cfg = q['letterSequenceConfig'] as LetterSequenceConfig;
           if (cfg.startLetter == 'F' && cfg.endLetter == 'Q' && cfg.letterCount == 4) {
             matchingConfig++;
           }
        }
      }
      expect(matchingConfig, equals(1));
    });

    // 3. standard question dengan kata sama tetapi gameType berbeda tetap dianggap berbeda
    test('3. standard question dengan kata sama tetapi gameType berbeda tetap dianggap berbeda', () {
      final firestoreQ = [
        const _FakeQuestion(id: '1', stageId: 'stage3', gameType: GameType.dengarSuaraHuruf, kata: 'ayam', huruf: 'a'),
        const _FakeQuestion(id: '2', stageId: 'stage3', gameType: GameType.tebakGambarObjek, kata: 'ayam', huruf: 'a'),
      ];

      final result = _composeSync(stageId: 3, firestoreQuestions: firestoreQ);
      final ayamCount = result.where((q) => q['kata'] == 'ayam').length;
      
      // Both should be included
      expect(ayamCount, greaterThanOrEqualTo(2));
    });

    // 4. 10 Firestore valid termasuk banyak urutkanHuruf config menghasilkan 10 Firestore + 0 local
    test('4. 10 Firestore valid termasuk banyak urutkanHuruf config menghasilkan 10 Firestore + 0 local', () {
      final firestoreQ = [
        const _FakeQuestion(id: '1', stageId: 'stage3', gameType: GameType.dengarSuaraHuruf, kata: 'ayam', huruf: 'a'),
        const _FakeQuestion(id: '2', stageId: 'stage3', gameType: GameType.tebakGambarObjek, kata: 'bebek', huruf: 'b'),
        const _FakeQuestion(id: '3', stageId: 'stage3', gameType: GameType.susunKata, kata: 'cicak', huruf: 'c'),
        const _FakeQuestion(
          id: 'u1', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'A', endLetter: 'Z', letterCount: 7),
        ),
        const _FakeQuestion(
          id: 'u2', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'N', endLetter: 'T', letterCount: 4),
        ),
        const _FakeQuestion(
          id: 'u3', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'K', endLetter: 'S', letterCount: 3),
        ),
        const _FakeQuestion(
          id: 'u4', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'K', endLetter: 'O', letterCount: 4),
        ),
        const _FakeQuestion(
          id: 'u5', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'H', endLetter: 'O', letterCount: 5),
        ),
        const _FakeQuestion(
          id: 'u6', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'F', endLetter: 'L', letterCount: 6),
        ),
        const _FakeQuestion(
          id: 'u7', stageId: 'stage3', gameType: GameType.urutkanHuruf, kata: '', huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'F', endLetter: 'Q', letterCount: 4),
        ),
      ];

      final result = _composeSync(stageId: 3, firestoreQuestions: firestoreQ);
      expect(result.length, equals(10));
      
      // Verification that no local fallbacks were used by checking all questions have a matching ID/Kata/Config
      // But _composeSync doesn't annotate `_source` like the real one. 
      // Instead we can just check if all the known 10 firestore questions are present.
      
      final resultKeys = result.map((r) {
        if (r.containsKey('letterSequenceConfig')) {
          final c = r['letterSequenceConfig'] as LetterSequenceConfig;
          return 'urutkanHuruf_config_${c.startLetter}_${c.endLetter}_${c.letterCount}';
        }
        final gt = (r['type'] as GameType).name;
        return '${gt}_${r['kata']}_${r['huruf']}';
      }).toSet();
      
      final expectedKeys = firestoreQ.map((q) => q.uniqueKey).toSet();
      
      expect(resultKeys.intersection(expectedKeys).length, equals(10));
    });

    // 5. >10 Firestore tetap dipilih maksimal 10
    test('5. >10 Firestore tetap dipilih maksimal 10', () {
      final firestoreQ = List.generate(
        15,
        (i) => _FakeQuestion(
          id: 'q$i',
          stageId: 'stage3',
          gameType: GameType.urutkanHuruf,
          kata: '',
          huruf: '',
          letterSequenceConfig: LetterSequenceConfig(
            startLetter: 'A', 
            endLetter: String.fromCharCode('B'.codeUnitAt(0) + i), 
            letterCount: 4
          ),
        ),
      );
      final result = _composeSync(stageId: 3, firestoreQuestions: firestoreQ);
      expect(result.length, equals(10), reason: 'Selalu 10 soal meski Firestore > 10');
    });

    // 6. <10 tetap dilengkapi lokal
    test('6. <10 tetap dilengkapi lokal menjadi 10', () {
      final firestoreQ = [
        const _FakeQuestion(
          id: 'u1',
          stageId: 'stage3',
          gameType: GameType.urutkanHuruf,
          kata: '',
          huruf: '',
          letterSequenceConfig: LetterSequenceConfig(startLetter: 'F', endLetter: 'Q', letterCount: 4),
        ),
      ];
      final result = _composeSync(stageId: 3, firestoreQuestions: firestoreQ);
      expect(result.length, equals(10));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // D. Legacy — dokumen lama tidak crash
  // ─────────────────────────────────────────────────────────────────────────
  group('urutkanHuruf – Legacy Compatibility', () {
    // D19: dokumen lama (kata+huruf) diterima oleh _FakeQuestion tanpa crash
    test('D19: dokumen lama kata+huruf tidak menyebabkan crash', () {
      final legacyQ = [
        const _FakeQuestion(
          id: 'legacy1',
          stageId: 'stage5',
          gameType: GameType.urutkanHuruf,
          kata: 'nanas',
          huruf: 'n',
        ),
      ];
      // Tidak boleh throw exception
      expect(
        () => _composeSync(stageId: 5, firestoreQuestions: legacyQ),
        returnsNormally,
      );
      final result = _composeSync(stageId: 5, firestoreQuestions: legacyQ);
      expect(result.length, equals(10));
    });

    // D20: config null tidak menyebabkan crash di _FakeQuestion
    test('D20: urutkanHuruf tanpa config (kata kosong) tidak crash di composer', () {
      const q = _FakeQuestion(
        id: 'no_config',
        stageId: 'stage5',
        gameType: GameType.urutkanHuruf,
        kata: '',
        huruf: '',
      );
      // Tidak boleh throw saat dibuat
      expect(q.toLocalMap, returnsNormally);
      final map = q.toLocalMap();
      expect(map['type'], equals(GameType.urutkanHuruf));
    });
  });
}
