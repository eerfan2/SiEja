import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/models/material_model.dart';
import 'package:si_eja/services/material_service.dart';
import 'package:si_eja/services/question_service.dart';
import 'package:si_eja/widgets/material_image_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 4: MaterialModel Unit Tests', () {
    test('1. MaterialModel.fromMap mem-parsing data lengkap dengan benar', () {
      final map = {
        'word': 'BOLA',
        'normalizedWord': 'bola',
        'initialLetter': 'B',
        'letterAudioId': 'B',
        'imagePath': 'material_catalog/mat_1/image.png',
        'wordAudioPath': 'material_catalog/mat_1/word.mp3',
        'isActive': true,
        'createdAt': DateTime(2026, 10, 14),
        'updatedAt': DateTime(2026, 10, 14),
        'createdBy': 'teacher_001',
      };

      final model = MaterialModel.fromMap(map, 'mat_1');
      expect(model, isNotNull);
      expect(model!.id, 'mat_1');
      expect(model.word, 'BOLA');
      expect(model.normalizedWord, 'bola');
      expect(model.initialLetter, 'B');
      expect(model.letterAudioId, 'B');
      expect(model.letterAudioKey, 'b');
      expect(model.imagePath, 'material_catalog/mat_1/image.png');
      expect(model.wordAudioPath, 'material_catalog/mat_1/word.mp3');
      expect(model.isActive, isTrue);
      expect(model.createdBy, 'teacher_001');
    });

    test('2. MaterialModel.fromMap melakukan fallback normalisasi otomatis', () {
      final map = {
        'word': '  robot mainan  ',
        'imagePath': 'path/img.png',
        'wordAudioPath': 'path/aud.mp3',
      };

      final model = MaterialModel.fromMap(map, 'mat_2');
      expect(model, isNotNull);
      expect(model!.word, 'robot mainan');
      expect(model.normalizedWord, 'robot mainan');
      expect(model.initialLetter, 'R');
      expect(model.letterAudioId, 'R');
      expect(model.letterAudioKey, 'r');
      expect(model.isActive, isTrue); // default true
    });

    test('3. MaterialModel.fromMap menolak data dengan kata kosong', () {
      final emptyWordMap = {
        'word': '   ',
        'imagePath': 'path/img.png',
      };

      final model = MaterialModel.fromMap(emptyWordMap, 'mat_invalid');
      expect(model, isNull);
    });

    test('4. letterAudioId independen dari initialLetter jika guru memilih suara berbeda', () {
      // Guru memilih kata "JERAPAH" tetapi memilih audio huruf "G"
      final map = {
        'word': 'JERAPAH',
        'normalizedWord': 'jerapah',
        'initialLetter': 'J',
        'letterAudioId': 'G',
        'imagePath': 'path/img.png',
        'wordAudioPath': 'path/aud.mp3',
        'isActive': true,
      };

      final model = MaterialModel.fromMap(map, 'mat_3');
      expect(model, isNotNull);
      expect(model!.initialLetter, 'J');
      expect(model.letterAudioId, 'G');
      expect(model.letterAudioKey, 'g');
    });
  });

  group('Fase 4: MaterialService & Media Resolver Tests', () {
    final materialService = MaterialService();

    setUp(() {
      materialService.clearCache();
    });

    test('5. Pemetaan letterAudioId ke audio lokal bawaan AppAudio.huruf', () {
      const dynamicItem = MaterialModel(
        id: 'mat_bola',
        word: 'BOLA',
        normalizedWord: 'bola',
        initialLetter: 'B',
        letterAudioId: 'B',
        imagePath: 'path/bola.png',
        wordAudioPath: 'path/bola.mp3',
        isActive: true,
      );
      materialService.setMockMaterials([dynamicItem]);

      final letterPath = materialService.resolveLetterAudioPath('BOLA');
      expect(letterPath, AppAudio.huruf('b'));
      expect(letterPath, 'assets/audio/huruf/b.mp3');
    });

    test('6. Pilihan audio huruf berbeda dari initialLetter tetap memetakan ke audio yang dipilih', () {
      const customAudioItem = MaterialModel(
        id: 'mat_custom',
        word: 'KAPAL',
        normalizedWord: 'kapal',
        initialLetter: 'K',
        letterAudioId: 'P', // Guru memilih suara huruf P
        imagePath: 'path/kapal.png',
        wordAudioPath: 'path/kapal.mp3',
        isActive: true,
      );
      materialService.setMockMaterials([customAudioItem]);

      final letterPath = materialService.resolveLetterAudioPath('KAPAL');
      expect(letterPath, AppAudio.huruf('p'));
      expect(letterPath, 'assets/audio/huruf/p.mp3');
    });

    test('7. Resolusi audio kata menggunakan cache URL Storage jika tersedia', () async {
      const item = MaterialModel(
        id: 'mat_bola',
        word: 'BOLA',
        normalizedWord: 'bola',
        initialLetter: 'B',
        letterAudioId: 'B',
        imagePath: 'path/bola.png',
        wordAudioPath: 'path/bola.mp3',
        isActive: true,
      );
      materialService.setMockMaterials([item]);
      materialService.setMockUrl('aud_bola', 'https://firebasestorage.googleapis.com/bola.mp3');

      final resolvedAudio = await materialService.resolveWordAudioUrl('bola');
      expect(resolvedAudio, 'https://firebasestorage.googleapis.com/bola.mp3');
    });

    test('8. Fallback audio kata lokal ketika materi tidak ada di cloud atau gagal', () async {
      // Kata 'kucing' adalah materi lokal bawaan
      final resolvedAudio = await materialService.resolveWordAudioUrl('kucing');
      expect(resolvedAudio, AppAudio.kata('kucing'));
      expect(resolvedAudio, 'assets/audio/kata/kucing.mp3');
    });

    test('9. Resolusi gambar menggunakan cache URL Storage jika tersedia', () async {
      const item = MaterialModel(
        id: 'mat_sepatu',
        word: 'SEPATU',
        normalizedWord: 'sepatu',
        initialLetter: 'S',
        letterAudioId: 'S',
        imagePath: 'path/sepatu.png',
        wordAudioPath: 'path/sepatu.mp3',
        isActive: true,
      );
      materialService.setMockMaterials([item]);
      materialService.setMockUrl('img_sepatu', 'https://firebasestorage.googleapis.com/sepatu.png');

      final resolvedImage = await materialService.resolveImageUrl('sepatu');
      expect(resolvedImage, 'https://firebasestorage.googleapis.com/sepatu.png');
    });

    test('10. Fallback gambar lokal bawaan ketika materi tidak ada di cloud', () async {
      // Huruf 'a' dan kata 'ayam' adalah aset lokal bawaan
      final resolvedImage = await materialService.resolveImageUrl('ayam', hurufFallback: 'a');
      expect(resolvedImage, AppImages.hurufKeGambar['a']);
      expect(resolvedImage, 'assets/images/kata/a_ayam.png');
    });

    test('11. Resolusi mengembalikan null aman jika kata sama sekali tidak memiliki aset', () async {
      final resolved = await materialService.resolveImageUrl('kosong_tanpa_gambar');
      expect(resolved, isNull);
    });
  });

  group('Fase 4: QuestionService Validasi Materi Lokal & Dinamis', () {
    final materialService = MaterialService();

    setUp(() {
      materialService.clearCache();
    });

    test('12. QuestionService.hasValidAsset menerima pasangan huruf-kata lokal bawaan', () {
      expect(QuestionService.hasValidAsset('a', 'ayam'), isTrue);
      expect(QuestionService.hasValidAsset('k', 'kucing'), isTrue);
      expect(QuestionService.hasValidAsset('z', 'zebra'), isTrue);
    });

    test('13. QuestionService.hasValidAsset menerima kata dari dynamic catalog', () {
      const dynamicItem = MaterialModel(
        id: 'mat_bola',
        word: 'BOLA',
        normalizedWord: 'bola',
        initialLetter: 'B',
        letterAudioId: 'B',
        imagePath: 'path/bola.png',
        wordAudioPath: 'path/bola.mp3',
        isActive: true,
      );
      materialService.setMockMaterials([dynamicItem]);

      // Pasangan 'b' + 'bola' valid karena 'bola' ada di dynamic catalog
      expect(QuestionService.hasValidAsset('b', 'bola'), isTrue);
      expect(QuestionService.hasValidAsset('B', 'BOLA'), isTrue);
    });

    test('14. QuestionService.hasValidAsset menolak kata yang tidak ada di lokal maupun dynamic catalog', () {
      expect(QuestionService.hasValidAsset('x', 'kata_fiktif_123'), isFalse);
      expect(QuestionService.hasValidAsset('k', 'kuda'), isFalse); // 'kuda' bukan bawaan SiEja
    });
  });

  group('Fase 4: MaterialImageWidget Widget Tests', () {
    testWidgets('15. MaterialImageWidget merender fallback icon tanpa crash saat gambar kosong', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialImageWidget(
              word: 'kata_tidak_ada',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MaterialImageWidget), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('16. MaterialImageWidget merender aset lokal bawaan dengan benar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialImageWidget(
              word: 'ayam',
              huruf: 'a',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MaterialImageWidget), findsOneWidget);
    });
  });
}
