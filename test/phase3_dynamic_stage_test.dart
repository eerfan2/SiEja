import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/models/stage_model.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/services/stage_service.dart';
import 'package:si_eja/screens/student/stage_map_screen.dart';
import 'package:si_eja/widgets/generic_stage_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 3: Aturan Akses Stage SiEja (Access Control Rules)', () {
    late ProgressService progressService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      progressService = ProgressService();
      await progressService.init();
      progressService.setCurrentSiswa('siswa_test_1', 'laki-laki');
    });

    test('1. Stage 1 mempertahankan perilaku lama (terbuka secara default)', () {
      // Default: Stage 1 terbuka
      expect(progressService.getStageStatus(1), 'unlocked');
      expect(progressService.canPlayStage(1), true);
      expect(progressService.checkStageAccess(1), StageAccessResult.allowed);
    });

    test('2. Stage 1 dapat dikunci secara manual oleh guru', () async {
      await progressService.lockStageByTeacher(1);
      expect(progressService.getStageStatus(1), 'locked');
      expect(progressService.canPlayStage(1), false);
      expect(progressService.checkStageAccess(1), StageAccessResult.lockedByTeacher);
    });

    test('3. Stage baru (Stage > 1) terkunci secara default', () {
      // Stage 2, Stage 7, Stage 8 default locked
      expect(progressService.getStageStatus(2), 'locked');
      expect(progressService.canPlayStage(2), false);

      expect(progressService.getStageStatus(7), 'locked');
      expect(progressService.canPlayStage(7), false);
    });

    test('4. Stage yang dibuka guru tetapi Stage sebelumnya belum selesai TETAP TERKUNCI', () async {
      // Guru membuka Stage 2
      await progressService.unlockStageByTeacher(2);
      expect(progressService.getStageStatus(2), 'unlocked');

      // Namun Stage 1 masih 'unlocked' (belum 'completed')
      expect(progressService.getStageStatus(1), 'unlocked');

      // Evaluasi akses Stage 2: harus gagal karena stage 1 belum selesai
      expect(progressService.canPlayStage(2), false);
      expect(progressService.checkStageAccess(2), StageAccessResult.prevStageIncomplete);
    });

    test('5. Stage yang dibuka guru dan Stage sebelumnya selesai DAPAT DIMAINKAN', () async {
      // Siswa menyelesaikan Stage 1
      await progressService.saveStageScore(1, 95);
      expect(progressService.getStageStatus(1), 'completed');

      // Guru membuka Stage 2
      await progressService.unlockStageByTeacher(2);

      // Siswa sekarang dapat memainkan Stage 2
      expect(progressService.canPlayStage(2), true);
      expect(progressService.checkStageAccess(2), StageAccessResult.allowed);
    });

    test('6. Evaluasi berlaku identik pada Stage 7 dan seterusnya (Dinamis)', () async {
      // Stage 6 selesai
      await progressService.saveStageScore(6, 100);
      expect(progressService.getStageStatus(6), 'completed');

      // Guru belum membuka Stage 7
      expect(progressService.canPlayStage(7), false);
      expect(progressService.checkStageAccess(7), StageAccessResult.lockedByTeacher);

      // Guru membuka Stage 7
      await progressService.unlockStageByTeacher(7);
      expect(progressService.canPlayStage(7), true);
      expect(progressService.checkStageAccess(7), StageAccessResult.allowed);

      // Stage 8: dibuka guru tapi Stage 7 belum selesai -> tetap terkunci
      await progressService.unlockStageByTeacher(8);
      expect(progressService.canPlayStage(8), false);
      expect(progressService.checkStageAccess(8), StageAccessResult.prevStageIncomplete);
    });
  });

  group('Fase 3: Sinkronisasi Progres Siswa & Preservasi Data Lama', () {
    late ProgressService progressService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      progressService = ProgressService();
      await progressService.init();
      progressService.setCurrentSiswa('siswa_123', 'perempuan');
    });

    test('7. loadStudentProgressFromFirebase memuat stage dinamis tanpa batasan 6 stage', () async {
      final mockFirebaseData = {
        'progress': {
          'stage1': {'skor': 90, 'status': 'completed'},
          'stage2': {'skor': 85, 'status': 'completed'},
          'stage7': {'skor': 70, 'status': 'completed'},
          'stage8': {'skor': 0, 'status': 'unlocked'},
        }
      };

      await progressService.loadStudentProgressFromFirebase(mockFirebaseData);

      expect(progressService.getStageScore(1), 90);
      expect(progressService.getStageStatus(1), 'completed');

      expect(progressService.getStageScore(2), 85);
      expect(progressService.getStageStatus(2), 'completed');

      // Stage 7 & 8 terpelihara dengan tepat
      expect(progressService.getStageScore(7), 70);
      expect(progressService.getStageStatus(7), 'completed');

      expect(progressService.getStageScore(8), 0);
      expect(progressService.getStageStatus(8), 'unlocked');

      // Stage 8 dapat dimainkan karena Stage 7 sudah completed
      expect(progressService.canPlayStage(8), true);
    });

    test('8. Penambahan stage baru tidak mereset progres siswa lama', () async {
      // Progres siswa lama pada stage 1 s.d. 3
      await progressService.saveStageScore(1, 100);
      await progressService.saveStageScore(2, 90);
      await progressService.saveStageScore(3, 80);

      // Simulasi sinkronisasi data dari Firebase di mana ada Stage 7 baru yang ditambahkan guru
      final updatedData = {
        'progress': {
          'stage1': {'skor': 100, 'status': 'completed'},
          'stage2': {'skor': 90, 'status': 'completed'},
          'stage3': {'skor': 80, 'status': 'completed'},
          'stage7': {'skor': 0, 'status': 'locked'}, // Stage baru
        }
      };

      await progressService.loadStudentProgressFromFirebase(updatedData);

      // Verifikasi seluruh progres lama UTUH
      expect(progressService.getStageScore(1), 100);
      expect(progressService.getStageStatus(1), 'completed');
      expect(progressService.getStageScore(2), 90);
      expect(progressService.getStageStatus(2), 'completed');
      expect(progressService.getStageScore(3), 80);
      expect(progressService.getStageStatus(3), 'completed');

      // Stage baru berstatus locked
      expect(progressService.getStageStatus(7), 'locked');
    });
  });

  group('Fase 3: Model Stage & Pengurutan Numerik (Sorting Integrity)', () {
    test('9. StageModel diurutkan berdasarkan number secara menaik (bukan urutan dokumen string)', () {
      final docA = StageModel.fromMap('stage10', {'number': 10, 'nama': 'Stage 10'});
      final docB = StageModel.fromMap('stage2', {'number': 2, 'nama': 'Stage 2'});
      final docC = StageModel.fromMap('stage7', {'number': 7, 'nama': 'Stage 7'});
      final docD = StageModel.fromMap('stage1', {'number': 1, 'nama': 'Stage 1'});

      final list = [docA, docB, docC, docD];
      list.sort((a, b) => a.number.compareTo(b.number));

      expect(list.map((s) => s.number).toList(), [1, 2, 7, 10]);
      // Memastikan bukan urutan leksikografis (di mana "stage10" sebelum "stage2")
      expect(list[0].id, 'stage1');
      expect(list[1].id, 'stage2');
      expect(list[2].id, 'stage7');
      expect(list[3].id, 'stage10');
    });

    test('10. StageService menyediakan fallback bawaan 6 stage jika offline', () {
      expect(StageService.defaultStages.length, 6);
      expect(StageService.defaultStages.first.number, 1);
      expect(StageService.defaultStages.first.isOpenByTeacher, true);
      expect(StageService.defaultStages.last.number, 6);
    });

    test('11. AppImages.stageIcon menangani Stage > 6 tanpa crash (defensive fallback)', () {
      expect(AppImages.hasStageIcon(1), true);
      expect(AppImages.hasStageIcon(6), true);
      expect(AppImages.hasStageIcon(7), false);
      expect(AppImages.hasStageIcon(10), false);

      // Safe fallback asset path (tidak throw exception)
      final icon7Locked = AppImages.stageIcon('locked', 7);
      expect(icon7Locked.contains('stage_locked_6.png'), true);

      final icon8Unlocked = AppImages.stageIcon('unlocked', 8);
      expect(icon8Unlocked.contains('stage_unlocked_6.png'), true);

      final icon9Completed = AppImages.stageIcon('completed', 9);
      expect(icon9Completed.contains('stage_completed_6.png'), true);
    });
  });

  group('Fase 3: Widget GenericStageBadge (Tampilan Generik Stage 7+)', () {
    testWidgets('12. GenericStageBadge merender status locked dengan benar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenericStageBadge(
              stageNumber: 7,
              status: 'locked',
            ),
          ),
        ),
      );

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Terkunci'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('13. GenericStageBadge merender status unlocked dengan benar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenericStageBadge(
              stageNumber: 8,
              status: 'unlocked',
            ),
          ),
        ),
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('Buka'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('14. GenericStageBadge merender status completed dengan benar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenericStageBadge(
              stageNumber: 9,
              status: 'completed',
            ),
          ),
        ),
      );

      expect(find.text('9'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('15. StageMapScreen merender peta stage dengan benar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StageMapScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StageMapScreen), findsOneWidget);
    });
  });
}
