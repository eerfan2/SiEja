import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simulasi Testing Algoritma SiEja', () {

    // 1. SIMULASI ALGORITMA PENGACAKAN SOAL (FISHER-YATES SHUFFLE)
    test('Simulasi Algoritma Fisher-Yates Shuffle pada Pengacakan Soal', () {
      final List<String> originalList = ['ayam', 'bebek', 'cicak', 'domba', 'elang'];
      final List<String> shuffledList = List.from(originalList);

      // Simulasi pengacakan Fisher-Yates
      final random = Random(42); // Seed konstan untuk reproduksibilitas simulasi
      for (int i = shuffledList.length - 1; i > 0; i--) {
        int j = random.nextInt(i + 1);
        var temp = shuffledList[i];
        shuffledList[i] = shuffledList[j];
        shuffledList[j] = temp;
      }

      print('Original List : $originalList');
      print('Shuffled List : $shuffledList');

      // Memastikan jumlah elemen tetap sama
      expect(shuffledList.length, equals(originalList.length));
      // Memastikan elemen yang terkandung sama
      expect(shuffledList, containsAll(originalList));
    });

    // 2. SIMULASI ALGORITMA PENOMORAN PIN OTOMATIS (GREEDY MINIMAL ALLOCATION)
    test('Simulasi Algoritma Generate PIN 3-Digit Unik', () {
      // Skenario: PIN yang sudah terpakai di sistem
      final Set<int> existingPins = {1, 2, 4, 5}; // PIN 001, 002, 004, 005 terpakai

      // Algoritma pencarian PIN kandidat terkecil yang belum terpakai
      int candidate = 1;
      while (existingPins.contains(candidate)) {
        candidate++;
      }

      final generatedPin = candidate.toString().padLeft(3, '0');

      print('Existing Pins : $existingPins');
      print('Generated PIN : $generatedPin');

      // Harus mengisi celah angka 3 -> "003"
      expect(generatedPin, equals('003'));
    });

    // 3. SIMULASI ALGORITMA DETEKSI SISWA TERTINGGAL (STUDENT STUCK DETECTION)
    //    Logika baru: siswa dianggap perlu remedial jika ada stage berstatus
    //    'completed' namun skornya < 50. Sistem melaporkan stage ID mana saja
    //    yang perlu perhatian guru.
    test('Simulasi Algoritma Indikator Siswa Perlu Bantuan (Student Stuck)', () {
      List<int> detectStuckStages(List<Map<String, dynamic>> stages) {
        return [
          for (var s in stages)
            if (s['status'] == 'completed' && (s['skor'] as int) < 50)
              s['id'] as int
        ];
      }

      // Skenario 1: Stage 2 completed tapi skor 40 (<50) → STUCK di stage 2
      final stagesA = [
        {'id': 1, 'status': 'completed', 'skor': 70},
        {'id': 2, 'status': 'completed', 'skor': 40}, // < 50 → perlu remedial
        {'id': 3, 'status': 'locked',    'skor': 0},
      ];
      final stuckA = detectStuckStages(stagesA);
      expect(stuckA.isNotEmpty, isTrue);
      expect(stuckA, contains(2));
      expect(stuckA, isNot(contains(1)));
      print('Skenario 1 – Stage stuck: $stuckA');

      // Skenario 2: Semua completed stage skornya >= 50 → NOT STUCK
      final stagesB = [
        {'id': 1, 'status': 'completed', 'skor': 90},
        {'id': 2, 'status': 'completed', 'skor': 50}, // tepat di batas → aman
        {'id': 3, 'status': 'unlocked',  'skor': 0},
      ];
      final stuckB = detectStuckStages(stagesB);
      expect(stuckB.isEmpty, isTrue);
      print('Skenario 2 – Stage stuck: $stuckB');

      // Skenario 3: Belum ada stage completed sama sekali → NOT STUCK
      final stagesC = [
        {'id': 1, 'status': 'unlocked', 'skor': 0},
        {'id': 2, 'status': 'locked',   'skor': 0},
      ];
      final stuckC = detectStuckStages(stagesC);
      expect(stuckC.isEmpty, isTrue);
      print('Skenario 3 – Stage stuck: $stuckC');

      // Skenario 4: Beberapa stage stuck sekaligus
      final stagesD = [
        {'id': 1, 'status': 'completed', 'skor': 30}, // < 50 → stuck
        {'id': 2, 'status': 'completed', 'skor': 80}, // >= 50 → aman
        {'id': 3, 'status': 'completed', 'skor': 0},  // < 50 → stuck
        {'id': 4, 'status': 'locked',    'skor': 0},
      ];
      final stuckD = detectStuckStages(stagesD);
      expect(stuckD.length, equals(2));
      expect(stuckD, containsAll([1, 3]));
      print('Skenario 4 – Stage stuck: $stuckD');
    });

    // 4. SIMULASI ALGORITMA PENILAIAN BINTANG (STAR RATING THRESHOLDING)
    //    Threshold disesuaikan dengan reward_screen.dart dan stage_map_screen.dart:
    //    >= 90 → ⭐⭐⭐ | >= 70 → ⭐⭐ | >= 50 → ⭐ | < 50 → 0 bintang
    test('Simulasi Kategori Bintang Berdasarkan Skor Kuis', () {
      int getStars(int score) {
        if (score >= 90) return 3;
        if (score >= 70) return 2;
        if (score >= 50) return 1;
        return 0;
      }

      // Batas atas 3 bintang
      expect(getStars(100), equals(3));
      expect(getStars(90),  equals(3));
      // Batas 2 bintang
      expect(getStars(89),  equals(2));
      expect(getStars(70),  equals(2));
      // Batas 1 bintang
      expect(getStars(69),  equals(1));
      expect(getStars(50),  equals(1));
      // Di bawah threshold → 0 bintang
      expect(getStars(49),  equals(0));
      expect(getStars(0),   equals(0));
    });
  });
}
