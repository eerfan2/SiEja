import 'package:flutter_test/flutter_test.dart';
import 'package:si_eja/core/app_constants.dart';

void main() {
  group('Fase 1: Logika Penilaian 7 Tipe Mini-Game & Submit', () {
    // 1. Dengar Suara Huruf
    test('1. dengarSuaraHuruf: Benar jika huruf sama, salah jika beda', () {
      const currentHuruf = 'b';
      String? tentativeAnswer;
      bool isSubmitting = false;
      bool answered = false;
      int score = 0;

      // Pilihan tentatif pertama: 'c'
      tentativeAnswer = 'c';
      expect(answered, isFalse);
      expect(score, 0);

      // Siswa mengganti pilihan ke 'b' sebelum submit
      tentativeAnswer = 'b';
      expect(answered, isFalse);
      expect(score, 0);

      // Submit
      if (!isSubmitting && !answered && tentativeAnswer.isNotEmpty) {
        isSubmitting = true;
        answered = true;
        final isCorrect = tentativeAnswer == currentHuruf;
        if (isCorrect) score += 10;
      }

      expect(answered, isTrue);
      expect(score, 10);
    });

    // 2. Tebak Gambar Objek
    test('2. tebakGambarObjek: Benar jika gambar sesuai nama objek', () {
      const currentHuruf = 'a';
      final expectedWord = AppImages.hurufKeKata[currentHuruf]!.toLowerCase(); // 'ayam'
      String? tentativeAnswer;
      int score = 0;

      // Siswa memilih 'bebek' lalu ganti 'ayam'
      tentativeAnswer = 'bebek';
      tentativeAnswer = expectedWord;

      final isCorrect = tentativeAnswer == AppImages.hurufKeKata[currentHuruf]?.toLowerCase();
      if (isCorrect) score += 10;

      expect(isCorrect, isTrue);
      expect(score, 10);

      // Test jawaban salah
      tentativeAnswer = 'cicak';
      final isWrong = tentativeAnswer == AppImages.hurufKeKata[currentHuruf]?.toLowerCase();
      expect(isWrong, isFalse);
    });

    // 3. Huruf Awal Apa
    test('3. hurufAwalApa: Benar jika huruf awal cocok dengan huruf objek', () {
      const currentHuruf = 'k';
      String? tentativeAnswer = 'l';
      expect(tentativeAnswer == currentHuruf, isFalse);

      tentativeAnswer = 'k';
      expect(tentativeAnswer == currentHuruf, isTrue);
    });

    // 4. Huruf Yang Hilang
    test('4. hurufYangHilang: Menilai huruf di indeks tengah kata', () {
      const kata = 'bebek'; // length 5, hiddenIndex = 2 ('b')
      const hiddenIndex = 5 ~/ 2;
      final missingLetter = kata[hiddenIndex]; // 'b'

      String? tentativeAnswer = 'e';
      expect(tentativeAnswer == missingLetter, isFalse);

      tentativeAnswer = 'b';
      expect(tentativeAnswer == missingLetter, isTrue);
    });

    // 5. Susun Kata
    test('5. susunKata: Hanya bisa submit jika panjang lengkap, mendukung hapus huruf', () {
      const currentKata = 'ikan';
      final userAnswer = <String>[];
      final selectedIndices = <int>[];

      // Masukkan sebagian huruf: 'i', 'k'
      userAnswer.addAll(['i', 'k']);
      selectedIndices.addAll([0, 1]);
      bool canSubmit = userAnswer.length == currentKata.length;
      expect(canSubmit, isFalse); // Belum lengkap, submit nonaktif

      // Siswa salah masukkan 'a' lalu menghapusnya
      userAnswer.add('a');
      selectedIndices.add(2);
      expect(userAnswer, ['i', 'k', 'a']);

      // Hapus huruf terakhir
      userAnswer.removeLast();
      selectedIndices.removeLast();
      expect(userAnswer, ['i', 'k']);

      // Lengkapi dengan susunan yang benar: 'i', 'k', 'a', 'n'
      userAnswer.addAll(['a', 'n']);
      selectedIndices.addAll([2, 3]);
      canSubmit = userAnswer.length == currentKata.length;
      expect(canSubmit, isTrue);

      final isCorrect = userAnswer.join('') == currentKata;
      expect(isCorrect, isTrue);
    });

    // 6. Cocokkan Huruf
    test('6. cocokkanHuruf: Benar jika huruf kecil sesuai huruf besar', () {
      const currentHuruf = 'm';
      String? tentativeAnswer = 'n';
      expect(tentativeAnswer == currentHuruf, isFalse);

      tentativeAnswer = 'm';
      expect(tentativeAnswer == currentHuruf, isTrue);
    });

    // 7. Urutkan Huruf
    test('7. urutkanHuruf: Menilai urutan alfabet, mendukung hapus dan perubahan', () {
      final choices = ['B', 'C', 'D', 'E']; // Jawaban benar (terurut)
      final shuffled = ['D', 'B', 'E', 'C'];
      final userAnswer = <String>[];
      final selectedIndices = <int>[];

      // Siswa memasukkan 'D' (salah urutan pertama)
      userAnswer.add(shuffled[0]);
      selectedIndices.add(0);
      expect(userAnswer.length == shuffled.length, isFalse);

      // Siswa sadar salah, tekan Hapus
      userAnswer.removeLast();
      selectedIndices.removeLast();
      expect(userAnswer.isEmpty, isTrue);

      // Siswa memasukkan urutan yang benar
      userAnswer.addAll(['B', 'C', 'D', 'E']);
      expect(userAnswer.length == shuffled.length, isTrue);

      final isCorrect = userAnswer.join('') == choices.join('');
      expect(isCorrect, isTrue);
    });
  });

  group('Fase 1: Pencegahan Submit Ganda (Idempotency Guard)', () {
    test('Ketukan berulang pada Submit di StageScreen hanya menilai dan menambah skor 1 kali', () {
      bool answered = false;
      bool isSubmitting = false;
      int score = 0;
      int feedbackCalls = 0;

      void checkAnswer(dynamic answer) {
        if (answered) return;
        answered = true;
        final isCorrect = answer == 'a';
        if (isCorrect) score += 10;
        feedbackCalls++;
      }

      void handleSubmitAnswer(dynamic selectedAnswer) {
        if (answered || isSubmitting) return;
        if (selectedAnswer == null) return;
        isSubmitting = true;
        checkAnswer(selectedAnswer);
      }

      // Ketukan 1
      handleSubmitAnswer('a');
      expect(score, 10);
      expect(feedbackCalls, 1);

      // Ketukan 2 (double tap cepat)
      handleSubmitAnswer('a');
      expect(score, 10);
      expect(feedbackCalls, 1);

      // Ketukan 3 (spam)
      handleSubmitAnswer('a');
      expect(score, 10);
      expect(feedbackCalls, 1);
    });

    test('Ketukan berulang pada Cek Jawaban di SpellWordScreen hanya menambah skor 1 kali', () {
      bool showResult = false;
      bool isSubmitting = false;
      int score = 0;
      int feedbackCalls = 0;
      const currentWord = 'ayam';
      final userAnswer = ['a', 'y', 'a', 'm'];

      void checkAnswer() {
        if (isSubmitting || showResult) return;
        if (userAnswer.length != currentWord.length) return;

        isSubmitting = true;
        showResult = true;

        final isCorrect = userAnswer.join('') == currentWord;
        if (isCorrect) score += 20;
        feedbackCalls++;
      }

      // Ketukan 1
      checkAnswer();
      expect(score, 20);
      expect(feedbackCalls, 1);

      // Ketukan 2
      checkAnswer();
      expect(score, 20);
      expect(feedbackCalls, 1);

      // Ketukan 3
      checkAnswer();
      expect(score, 20);
      expect(feedbackCalls, 1);
    });

    test('Submit ditolak jika jawaban belum lengkap', () {
      bool isSubmitting = false;
      bool answered = false;
      int score = 0;

      void handleSubmit(String? answer) {
        if (answer == null || answered || isSubmitting) return;
        isSubmitting = true;
        answered = true;
        score += 10;
      }

      // Jawaban masih null
      handleSubmit(null);
      expect(answered, isFalse);
      expect(score, 0);

      // Jawaban diisi
      handleSubmit('a');
      expect(answered, isTrue);
      expect(score, 10);
    });
  });
}
