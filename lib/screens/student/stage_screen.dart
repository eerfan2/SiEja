import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/models/game_type.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/material_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/services/stage_question_composer.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/widgets/material_image_widget.dart';

class StageScreen extends StatefulWidget {
  final int stageId;

  const StageScreen({
    super.key,
    required this.stageId,
  });

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> with WidgetsBindingObserver {
  // Kata per stage
  static const Map<int, List<String>> stageKata = {
    1: ['ayam', 'bebek', 'cicak', 'domba', 'elang'],
    2: ['feri', 'gajah', 'harimau', 'ikan', 'jerapah'],
    3: ['kucing', 'lebah', 'monyet', 'nanas', 'onta'],
    4: ['panda', 'quran', 'rusa', 'singa', 'tikus'],
    5: ['ulat', 'vas', 'wortel', 'xilofon', 'yoyo', 'zebra'],
    6: [
      'ayam',
      'bebek',
      'cicak',
      'domba',
      'elang',
      'feri',
      'gajah',
      'harimau',
      'ikan',
      'jerapah',
      'kucing',
      'lebah',
      'monyet',
      'nanas',
      'onta',
      'panda',
      'quran',
      'rusa',
      'singa',
      'tikus',
      'ulat',
      'vas',
      'wortel',
      'xilofon',
      'yoyo',
      'zebra'
    ],
  };

  // Huruf per stage
  static const Map<int, List<String>> stageHuruf = {
    1: ['a', 'b', 'c', 'd', 'e'],
    2: ['f', 'g', 'h', 'i', 'j'],
    3: ['k', 'l', 'm', 'n', 'o'],
    4: ['p', 'q', 'r', 's', 't'],
    5: ['u', 'v', 'w', 'x', 'y', 'z'],
    6: [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z'
    ],
  };

  // Komposisi soal per stage
  static const Map<int, List<Map<String, dynamic>>> stageKomposisi = {
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

  int _currentQuestion = 0;
  int _score = 0;
  int _totalQuestions = 10;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _answered = false;
  bool _isSubmitting = false; // Anti-double submit lock
  bool _canAnswer = false; // Lock pilihan saat instruksi audio sedang berputar
  bool _isLoadingQuestions = false; // Loading saat menyiapkan bank soal
  String? _selectedAnswer; // Jawaban yang dipilih user untuk efek visual
  List<Map<String, dynamic>> _questions = [];
  Timer? _introTimer;
  Timer? _secondIntroTimer;

  // State per tipe soal
  String _currentKata = '';
  String _currentHuruf = '';
  List<String> _choices = [];
  List<String> _userAnswer = [];
  List<int> _selectedIndices =
      []; // Untuk melacak tombol huruf yang dipilih secara spesifik
  List<String> _shuffledLetters = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Guard akses Fase 3: cegah akses langsung jika stage terkunci atau stage sebelumnya belum selesai
    if (!ProgressService().canPlayStage(widget.stageId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stage ini belum dapat dimainkan!'),
              duration: Duration(seconds: 2),
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/stage-map');
          }
        }
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playBGM(AppAudio.bgmStage);
    });
    _generateQuestions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _introTimer?.cancel();
    _secondIntroTimer?.cancel();
    AudioService().stopSFX();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveCurrentDraft();
    }
  }

  void _saveCurrentDraft() {
    if (_questions.isNotEmpty && _currentQuestion < _questions.length) {
      ProgressService().saveDraftStageProgress(
        stageId: widget.stageId,
        currentQuestion: _currentQuestion,
        score: _score,
        questions: _questions,
      );
    }
  }

  Future<void> _generateQuestions() async {
    // 1. Cek apakah ada draf progress yang tersimpan untuk stage ini
    final draft = ProgressService().getDraftStageProgress(widget.stageId);
    if (draft != null) {
      final List<dynamic> rawQuestions = draft['questions'] as List<dynamic>;
      final List<Map<String, dynamic>> restoredQuestions =
          rawQuestions.map((q) {
        final typeIndex = q['typeIndex'] as int;
        return {
          'type': GameType.values[typeIndex],
          'kata': q['kata'] as String,
          'huruf': q['huruf'] as String,
        };
      }).toList();

      final restoredIndex = draft['currentQuestion'] as int;
      final restoredScore = draft['score'] as int;

      if (restoredQuestions.isNotEmpty &&
          restoredIndex < restoredQuestions.length) {
        setState(() {
          _questions = restoredQuestions;
          _totalQuestions = restoredQuestions.length;
          _score = restoredScore;
        });
        _loadQuestion(restoredIndex);
        return;
      }
    }

    // 2. Jika tidak ada draf, muat bank soal baru
    // Tampilkan loading ringan selama pengambilan soal dari Firestore
    if (mounted) {
      setState(() {
        _isLoadingQuestions = true;
      });
    }

    List<Map<String, dynamic>> questions;
    try {
      // Pastikan katalog materi aktif sudah termuat terlebih dahulu
      await MaterialService().loadActiveMaterials();
      // Gunakan StageQuestionComposer: prioritas Firestore + fallback lokal
      questions = await StageQuestionComposer().compose(widget.stageId);
    } catch (_) {
      // Fallback penuh ke lokal jika composer gagal sama sekali
      questions = _buildLocalQuestions();
    }

    if (!mounted) return;

    setState(() {
      _isLoadingQuestions = false;
      _questions = questions;
      _totalQuestions = questions.length;
      _score = 0;
    });

    _loadQuestion(0);
  }

  /// Bank soal lokal murni — digunakan sebagai fallback terakhir jika
  /// [StageQuestionComposer] gagal sama sekali.
  List<Map<String, dynamic>> _buildLocalQuestions() {
    final komposisi = stageKomposisi[widget.stageId] ?? stageKomposisi[6]!;
    final kataList =
        List<String>.from(stageKata[widget.stageId] ?? stageKata[6]!);
    final random = Random();
    final List<Map<String, dynamic>> questions = [];

    for (final kompo in komposisi) {
      final type = kompo['type'] as GameType;
      final count = kompo['count'] as int;
      final typeWords = List<String>.from(kataList)..shuffle(random);

      for (int i = 0; i < count; i++) {
        final selectedKata = typeWords[i % typeWords.length];
        questions.add({
          'type': type,
          'kata': selectedKata,
          'huruf': selectedKata[0].toLowerCase(),
        });
      }
    }

    questions.shuffle();
    return questions;
  }

  void _loadQuestion(int index) {
    if (index >= _questions.length) {
      // Selesai stage → hapus draf → simpan skor → pindah ke halaman reward
      ProgressService().clearDraftStageProgress(widget.stageId);
      ProgressService().saveStageScore(widget.stageId, _score);
      context.go('/reward', extra: {
        'score': _score,
        'stageId': widget.stageId,
      });
      return;
    }

    // Simpan draf progress secara otomatis untuk soal saat ini
    if (_questions.isNotEmpty) {
      ProgressService().saveDraftStageProgress(
        stageId: widget.stageId,
        currentQuestion: index,
        score: _score,
        questions: _questions,
      );
    }

    final q = _questions[index];
    final type = q['type'] as GameType;
    final kata = q['kata'] as String;
    final huruf = q['huruf'] as String;

    setState(() {
      _currentQuestion = index;
      _currentKata = kata;
      _currentHuruf = huruf;
      _answered = false;
      _canAnswer = false;
      _isSubmitting = false;
      _showResult = false;
      _userAnswer = [];
      _selectedIndices = [];
      _choices = [];
      _selectedAnswer = null;
    });

    _setupChoices(type, kata, huruf);
    _playIntroAudio(type, huruf, kata);
  }

  void _setupChoices(GameType type, String kata, String huruf) {
    final currentStageLetters = stageHuruf[widget.stageId] ?? stageHuruf[6]!;
    final currentStageWords = (stageKata[widget.stageId] ?? stageKata[6]!)
        .map((k) => k.toLowerCase())
        .toList();
    final random = Random();
    final allLetters = 'abcdefghijklmnopqrstuvwxyz'.split('');

    switch (type) {
      case GameType.dengarSuaraHuruf:
        // 4 pilihan huruf, 1 benar
        final distractorCandidates =
            currentStageLetters.where((h) => h != huruf).toList();
        if (distractorCandidates.length < 3) {
          distractorCandidates.addAll(allLetters
              .where((h) => h != huruf && !distractorCandidates.contains(h)));
        }
        distractorCandidates.shuffle(random);
        _choices = [huruf, ...distractorCandidates.take(3)]..shuffle(random);
        break;

      case GameType.tebakGambarObjek:
        // 3 pilihan gambar, 1 benar
        final cleanKata = kata.toLowerCase().trim();
        final wrongKata = currentStageWords
            .where((k) => k.toLowerCase().trim() != cleanKata)
            .toList()
          ..shuffle(random);
        _choices = [cleanKata, ...wrongKata.take(2)]..shuffle(random);
        break;

      case GameType.hurufAwalApa:
        // 4 pilihan huruf, 1 benar
        final distractorCandidates =
            currentStageLetters.where((h) => h != huruf).toList();
        if (distractorCandidates.length < 3) {
          distractorCandidates.addAll(allLetters
              .where((h) => h != huruf && !distractorCandidates.contains(h)));
        }
        distractorCandidates.shuffle(random);
        _choices = [huruf, ...distractorCandidates.take(3)]..shuffle(random);
        break;

      case GameType.hurufYangHilang:
        // Tampilkan kata dengan 1 huruf hilang (menggunakan kata.length ~/ 2)
        // 4 pilihan huruf untuk mengisi
        final hiddenIndex = kata.length ~/ 2;
        final targetLetter = kata[hiddenIndex].toLowerCase();
        final distractorCandidates =
            currentStageLetters.where((h) => h != targetLetter).toList();
        if (distractorCandidates.length < 3) {
          distractorCandidates.addAll(allLetters.where(
              (h) => h != targetLetter && !distractorCandidates.contains(h)));
        }
        distractorCandidates.shuffle(random);
        _choices = [targetLetter, ...distractorCandidates.take(3)]
          ..shuffle(random);
        break;

      case GameType.susunKata:
        // Huruf acak untuk disusun
        _shuffledLetters = kata.split('')..shuffle(random);
        break;

      case GameType.cocokkanHuruf:
        // Pasangkan huruf besar dengan kecil
        // Tampilkan 4 huruf besar, 4 huruf kecil
        final distractorCandidates =
            currentStageLetters.where((h) => h != huruf).toList();
        if (distractorCandidates.length < 3) {
          distractorCandidates.addAll(allLetters
              .where((h) => h != huruf && !distractorCandidates.contains(h)));
        }
        distractorCandidates.shuffle(random);
        final displayHuruf = [huruf, ...distractorCandidates.take(3)]
          ..shuffle(random);
        _choices = displayHuruf;
        break;

      case GameType.urutkanHuruf:
        final q = _questions[_currentQuestion];
        final letterConfig = q['letterSequenceConfig'];

        List<String> selectedHuruf;

        if (letterConfig != null) {
          // ── Format baru: gunakan config dari Firestore ──────────────────
          final candidates = List<String>.from(letterConfig.candidateLetters);
          candidates.shuffle(random);
          selectedHuruf = candidates.take(letterConfig.letterCount).toList();
        } else {
          // ── Format lama / fallback lokal: ambil dari stageHuruf ─────────
          final allStageHuruf = List<String>.from(currentStageLetters);
          allStageHuruf.shuffle(random);
          // Konversi ke uppercase agar konsisten dengan format baru
          selectedHuruf =
              allStageHuruf.take(4).map((h) => h.toUpperCase()).toList();
        }

        // _choices adalah huruf yang sudah diurutkan sesuai alfabet (jawaban benar)
        final sortedHuruf = List<String>.from(selectedHuruf)..sort();
        _choices = sortedHuruf;

        // _shuffledLetters adalah versi acak untuk ditampilkan
        _shuffledLetters = List.from(selectedHuruf);
        // Pastikan shuffled tidak sama persis dengan sorted (maks 10 iterasi)
        int shuffleAttempts = 0;
        while (_shuffledLetters.join('') == _choices.join('') &&
            _shuffledLetters.length > 1 &&
            shuffleAttempts < 10) {
          _shuffledLetters.shuffle(random);
          shuffleAttempts++;
        }

        if (letterConfig != null) {
          debugPrint('[UrutkanHuruf]\n'
              'range: ${letterConfig.startLetter}-${letterConfig.endLetter}\n'
              'letterCount: ${letterConfig.letterCount}\n'
              'selected: ${selectedHuruf.join(",")}\n'
              'display: ${_shuffledLetters.join(",")}\n'
              'correct: ${_choices.join(",")}');
        }
        break;
    }
  }

  void _playIntroAudio(GameType type, String huruf, String kata) {
    _introTimer?.cancel();
    _secondIntroTimer?.cancel();

    _introTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      int totalDurationMs = 3000;

      switch (type) {
        case GameType.dengarSuaraHuruf:
          AudioService().playSFX(AppAudio.introDengar);
          totalDurationMs = 4500;
          _secondIntroTimer = Timer(const Duration(milliseconds: 3000), () {
            if (mounted) {
              final letterPath = MaterialService()
                  .resolveLetterAudioPath(kata, hurufFallback: huruf);
              AudioService().playSFX(letterPath);
            }
          });
          break;
        case GameType.tebakGambarObjek:
          AudioService().playSFX(AppAudio.introDengar);
          totalDurationMs = 4500;
          _secondIntroTimer =
              Timer(const Duration(milliseconds: 3000), () async {
            if (mounted) {
              final audioUrl =
                  await MaterialService().resolveWordAudioUrl(kata);
              AudioService().playSFX(audioUrl);
            }
          });
          break;
        case GameType.hurufAwalApa:
          AudioService().playSFX(AppAudio.introAwalKata);
          totalDurationMs = 3000;
          break;
        case GameType.hurufYangHilang:
          AudioService().playSFX(AppAudio.introGameHurufHilang);
          totalDurationMs = 3000;
          break;
        case GameType.susunKata:
          AudioService().playSFX(AppAudio.introSusun);
          totalDurationMs = 6000;
          _secondIntroTimer =
              Timer(const Duration(milliseconds: 4500), () async {
            if (mounted) {
              final audioUrl =
                  await MaterialService().resolveWordAudioUrl(kata);
              AudioService().playSFX(audioUrl);
            }
          });
          break;
        case GameType.cocokkanHuruf:
          AudioService().playSFX(AppAudio.introHurufBesarKecil);
          totalDurationMs = 3000;
          break;
        case GameType.urutkanHuruf:
          AudioService().playSFX(AppAudio.introUrutkan);
          totalDurationMs = 3000;
          break;
      }

      Timer(Duration(milliseconds: totalDurationMs), () {
        if (mounted) {
          setState(() {
            _canAnswer = true;
          });
        }
      });
    });
  }

  void _handleSubmitAnswer() {
    if (!_canAnswer || _answered || _isSubmitting) return;

    final q = _questions[_currentQuestion];
    final type = q['type'] as GameType;

    dynamic answerToEvaluate;
    if (type == GameType.susunKata) {
      if (_userAnswer.length != _currentKata.length) return;
      answerToEvaluate = _userAnswer.join('');
    } else if (type == GameType.urutkanHuruf) {
      if (_userAnswer.length != _shuffledLetters.length) return;
      answerToEvaluate = _userAnswer.join('');
    } else {
      if (_selectedAnswer == null) return;
      answerToEvaluate = _selectedAnswer;
    }

    setState(() {
      _isSubmitting = true;
    });

    _checkAnswer(answerToEvaluate);
  }

  Widget _buildSubmitButton({
    required bool isEnabled,
    required VoidCallback? onSubmit,
    required bool isTablet,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.4,
      child: AssetButton(
        normalAsset: AppImages.btnJawabNormal,
        pressedAsset: AppImages.btnJawabPressed,
        onTap: isEnabled && onSubmit != null ? onSubmit : () {},
        width: isTablet ? 150 : 110,
        height: isTablet ? 65 : 48,
      ),
    );
  }

  void _checkAnswer(dynamic answer) {
    if (_answered) return;
    _answered = true; // Langsung lock sinkron untuk mencegah Submit ganda

    final q = _questions[_currentQuestion];
    final type = q['type'] as GameType;
    bool isCorrect = false;

    switch (type) {
      case GameType.dengarSuaraHuruf:
        isCorrect =
            answer?.toString().toLowerCase() == _currentHuruf.toLowerCase();
        break;
      case GameType.tebakGambarObjek:
        isCorrect = answer?.toString().toLowerCase().trim() ==
            _currentKata.toLowerCase().trim();
        break;
      case GameType.hurufAwalApa:
        isCorrect =
            answer?.toString().toLowerCase() == _currentHuruf.toLowerCase();
        break;
      case GameType.hurufYangHilang:
        isCorrect = answer?.toString().toLowerCase() ==
            _getMissingLetter().toLowerCase();
        break;
      case GameType.susunKata:
        isCorrect = _userAnswer.join('').toLowerCase().trim() ==
            _currentKata.toLowerCase().trim();
        break;
      case GameType.cocokkanHuruf:
        isCorrect =
            answer?.toString().toLowerCase() == _currentHuruf.toLowerCase();
        break;
      case GameType.urutkanHuruf:
        isCorrect = _userAnswer.join('') == _choices.join('');
        break;
    }

    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
      _selectedAnswer = answer?.toString();
      if (isCorrect) _score += 10;
    });

    final random = Random();
    if (isCorrect) {
      final feedbacks = [
        AppAudio.feedbackBenar,
        AppAudio.feedbackBenar2,
        AppAudio.feedbackBenar3,
      ];
      AudioService().playSFX(feedbacks[random.nextInt(feedbacks.length)]);
    } else {
      final feedbacks = [
        AppAudio.feedbackSalah,
        AppAudio.feedbackSalah2,
        AppAudio.feedbackSalah3,
      ];
      AudioService().playSFX(feedbacks[random.nextInt(feedbacks.length)]);
    }

    // Auto lanjut setelah 3.0 detik agar suara feedback selesai
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _loadQuestion(_currentQuestion + 1);
      }
    });
  }

  String _getMissingLetter() {
    final kata = _currentKata;
    final hiddenIndex = kata.length ~/ 2;
    return kata[hiddenIndex];
  }

  Widget _buildQuestionWidget() {
    if (_isLoadingQuestions || _questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Menyiapkan soal...',
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final type = _questions[_currentQuestion]['type'] as GameType;

    Widget childWidget;
    switch (type) {
      case GameType.dengarSuaraHuruf:
        childWidget = _buildDengarSuaraHuruf();
        break;
      case GameType.tebakGambarObjek:
        childWidget = _buildTebakGambarObjek();
        break;
      case GameType.hurufAwalApa:
        childWidget = _buildHurufAwalApa();
        break;
      case GameType.hurufYangHilang:
        childWidget = _buildHurufYangHilang();
        break;
      case GameType.susunKata:
        childWidget = _buildSusunKata();
        break;
      case GameType.cocokkanHuruf:
        childWidget = _buildCocokkanHuruf();
        break;
      case GameType.urutkanHuruf:
        childWidget = _buildUrutkanHuruf();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        key: ValueKey<int>(_currentQuestion),
        physics: const ClampingScrollPhysics(),
        child: childWidget,
      ),
    );
  }

  // 1. DENGAR SUARA HURUF
  Widget _buildDengarSuaraHuruf() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Dengarkan suara huruf ini!',
            style: TextStyle(
              fontSize: isTablet ? 20 : 15,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            final path = MaterialService().resolveLetterAudioPath(_currentKata,
                hurufFallback: _currentHuruf);
            AudioService().playSFX(path);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.icSound,
                width: isTablet ? 76 : 52,
                height: isTablet ? 76 : 52,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap untuk dengar',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 13,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black54,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Huruf apakah itu?',
          style: TextStyle(
            fontSize: isTablet ? 22 : 16,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                blurRadius: 6,
                color: Colors.black54,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: _choices.map((choice) {
            final isSelected = _selectedAnswer == choice;
            return _ScaleOptionButton(
              onTap: (!_canAnswer || _answered || _isSubmitting)
                  ? null
                  : () => setState(() => _selectedAnswer = choice),
              isSelected: isSelected,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFE082)
                      : Colors.white
                          .withOpacity(_answered && !isSelected ? 0.6 : 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFF5A4FCF),
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    choice.toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: isSelected
                          ? const Color(0xFF4A148C)
                          : const Color(0xFF5A4FCF).withOpacity(
                              _answered && !isSelected ? 0.6 : 1.0),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildSubmitButton(
          isEnabled: _canAnswer &&
              !_answered &&
              !_isSubmitting &&
              _selectedAnswer != null,
          onSubmit: _handleSubmitAnswer,
          isTablet: isTablet,
        ),
      ],
    );
  }

  // 2. TEBAK GAMBAR OBJEK
  Widget _buildTebakGambarObjek() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Dengar lalu pilih gambarnya saja',
            style: TextStyle(
              fontSize: isTablet ? 20 : 14,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final audioUrl =
                await MaterialService().resolveWordAudioUrl(_currentKata);
            AudioService().playSFX(audioUrl);
          },
          child: Image.asset(
            AppImages.icSound,
            width: isTablet ? 76 : 52,
            height: isTablet ? 76 : 52,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Pilih gambar yang tepat!',
          style: TextStyle(
            fontSize: isTablet ? 20 : 15,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                blurRadius: 6,
                color: Colors.black54,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _choices.map((choice) {
            final isSelected = _selectedAnswer == choice;
            final boxSize = isTablet ? 130.0 : 88.0;
            return _ScaleOptionButton(
              onTap: (!_canAnswer || _answered || _isSubmitting)
                  ? null
                  : () => setState(() => _selectedAnswer = choice),
              isSelected: isSelected,
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFE082)
                      : Colors.white
                          .withOpacity(_answered && !isSelected ? 0.6 : 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFF5A4FCF),
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MaterialImageWidget(
                    word: choice,
                    huruf: choice.isNotEmpty ? choice[0] : null,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        _buildSubmitButton(
          isEnabled: _canAnswer &&
              !_answered &&
              !_isSubmitting &&
              _selectedAnswer != null,
          onSubmit: _handleSubmitAnswer,
          isTablet: isTablet,
        ),
      ],
    );
  }

  // 3. HURUF AWAL APA?
  Widget _buildHurufAwalApa() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Huruf awal dari nama gambar ini apa?',
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              AppImages.cardTemplateBlue,
              width: isTablet ? 260 : 180,
              fit: BoxFit.fitWidth,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  MaterialImageWidget(
                    word: _currentKata,
                    huruf: _currentHuruf,
                    width: isTablet ? 150 : 100,
                    height: isTablet ? 120 : 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentKata.isNotEmpty
                        ? _currentKata.toUpperCase()
                        : (AppImages.hurufKeKata[_currentHuruf] ?? ''),
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: const Color(0xFF5A4FCF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Pilih huruf awalnya!',
          style: TextStyle(
            fontSize: isTablet ? 24 : 16,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black54,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: _choices.map((choice) {
            final isSelected = _selectedAnswer == choice;
            return _ScaleOptionButton(
              onTap: (!_canAnswer || _answered || _isSubmitting)
                  ? null
                  : () => setState(() => _selectedAnswer = choice),
              isSelected: isSelected,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFE082)
                      : Colors.white
                          .withOpacity(_answered && !isSelected ? 0.6 : 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFF5A4FCF),
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    choice.toUpperCase(),
                    style: TextStyle(
                      fontSize: isTablet ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: isSelected
                          ? const Color(0xFF4A148C)
                          : const Color(0xFF5A4FCF).withOpacity(
                              _answered && !isSelected ? 0.6 : 1.0),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(
          isEnabled: _canAnswer &&
              !_answered &&
              !_isSubmitting &&
              _selectedAnswer != null,
          onSubmit: _handleSubmitAnswer,
          isTablet: isTablet,
        ),
      ],
    );
  }

  // 4. HURUF YANG HILANG
  Widget _buildHurufYangHilang() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final kata = _currentKata;
    final hiddenIndex = kata.length ~/ 2;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Huruf mana yang hilang?',
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              AppImages.cardTemplateBlue,
              width: isTablet ? 200 : 130,
              fit: BoxFit.fitWidth,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  MaterialImageWidget(
                    word: _currentKata,
                    huruf: _currentHuruf,
                    width: isTablet ? 120 : 80,
                    height: isTablet ? 100 : 70,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentKata.isNotEmpty
                        ? _currentKata.toUpperCase()
                        : (AppImages.hurufKeKata[_currentHuruf] ?? ''),
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: const Color(0xFF5A4FCF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(kata.length, (i) {
            final isHidden = i == hiddenIndex;
            final isFilledTentative = isHidden && _selectedAnswer != null;
            final displayText = isHidden
                ? (_selectedAnswer != null
                    ? _selectedAnswer!.toUpperCase()
                    : '?')
                : kata[i].toUpperCase();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isTablet ? 64 : 40,
              height: isTablet ? 74 : 48,
              decoration: BoxDecoration(
                color: isHidden
                    ? (isFilledTentative
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFFFFD966).withOpacity(0.9))
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHidden
                      ? const Color(0xFFFFAA00)
                      : const Color(0xFF5A4FCF),
                  width: isFilledTentative ? 3 : 2,
                ),
              ),
              child: Center(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: isTablet ? 40 : 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    color: isHidden
                        ? const Color(0xFF6A1B9A)
                        : const Color(0xFF5A4FCF),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          'Pilih huruf yang tepat!',
          style: TextStyle(
            fontSize: isTablet ? 24 : 16,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black54,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: _choices.map((choice) {
            final isSelected = _selectedAnswer == choice;
            return _ScaleOptionButton(
              onTap: (!_canAnswer || _answered || _isSubmitting)
                  ? null
                  : () => setState(() => _selectedAnswer = choice),
              isSelected: isSelected,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFE082)
                      : Colors.white
                          .withOpacity(_answered && !isSelected ? 0.6 : 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFF5A4FCF),
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    choice.toUpperCase(),
                    style: TextStyle(
                      fontSize: isTablet ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: isSelected
                          ? const Color(0xFF4A148C)
                          : const Color(0xFF5A4FCF).withOpacity(
                              _answered && !isSelected ? 0.6 : 1.0),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(
          isEnabled: _canAnswer &&
              !_answered &&
              !_isSubmitting &&
              _selectedAnswer != null,
          onSubmit: _handleSubmitAnswer,
          isTablet: isTablet,
        ),
      ],
    );
  }

  // 5. SUSUN KATA
  Widget _buildSusunKata() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Susun hurufnya menjadi kata!',
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final audioUrl =
                await MaterialService().resolveWordAudioUrl(_currentKata);
            AudioService().playSFX(audioUrl);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                AppImages.cardTemplateBlue,
                width: isTablet ? 200 : 130,
                fit: BoxFit.fitWidth,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    MaterialImageWidget(
                      word: _currentKata,
                      huruf: _currentHuruf,
                      width: isTablet ? 120 : 80,
                      height: isTablet ? 100 : 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentKata.isNotEmpty
                          ? _currentKata.toUpperCase()
                          : (AppImages.hurufKeKata[_currentHuruf] ?? ''),
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF5A4FCF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final audioUrl =
                await MaterialService().resolveWordAudioUrl(_currentKata);
            AudioService().playSFX(audioUrl);
          },
          child: Image.asset(
            AppImages.icSound,
            width: isTablet ? 56 : 46,
            height: isTablet ? 56 : 46,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_currentKata.length, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isTablet ? 64 : 40,
              height: isTablet ? 64 : 40,
              decoration: BoxDecoration(
                color: _userAnswer.length > i
                    ? const Color(0xFF7F77DD)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF5A4FCF),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _userAnswer.length > i ? _userAnswer[i].toUpperCase() : '',
                  style: TextStyle(
                    fontSize: isTablet ? 36 : 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _shuffledLetters.asMap().entries.map((entry) {
            final i = entry.key;
            final letter = entry.value;
            final isUsed = _selectedIndices.contains(i);
            return _ScaleOptionButton(
              onTap: isUsed || _answered || _isSubmitting || !_canAnswer
                  ? null
                  : () {
                      setState(() {
                        _selectedIndices.add(i);
                        _userAnswer.add(letter);
                      });
                    },
              child: Container(
                width: isTablet ? 60 : 40,
                height: isTablet ? 70 : 48,
                decoration: BoxDecoration(
                  color: isUsed
                      ? Colors.grey.withOpacity(0.4)
                      : const Color(0xFFFFD966).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUsed ? Colors.grey : const Color(0xFFFFAA00),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: isUsed ? Colors.grey : const Color(0xFF5A4FCF),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userAnswer.isNotEmpty &&
                !_answered &&
                !_isSubmitting &&
                _canAnswer) ...[
              AssetButton(
                normalAsset: AppImages.btnDeleteNormal,
                pressedAsset: AppImages.btnDeletePressed,
                onTap: () {
                  setState(() {
                    _userAnswer.removeLast();
                    _selectedIndices.removeLast();
                  });
                },
                width: isTablet ? 140 : 90,
                height: isTablet ? 64 : 44,
              ),
              const SizedBox(width: 16),
            ],
            _buildSubmitButton(
              isEnabled: _canAnswer &&
                  !_answered &&
                  !_isSubmitting &&
                  _userAnswer.length == _currentKata.length,
              onSubmit: _handleSubmitAnswer,
              isTablet: isTablet,
            ),
          ],
        ),
      ],
    );
  }

  // 6. COCOKKAN HURUF BESAR DAN KECIL
  Widget _buildCocokkanHuruf() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Cocokkan huruf besar dengan huruf kecilnya!',
            style: TextStyle(
              fontSize: isTablet ? 20 : 14,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: isTablet ? 160 : 100,
          height: isTablet ? 160 : 100,
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _currentHuruf.toUpperCase(),
              style: TextStyle(
                fontSize: isTablet ? 80 : 56,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Huruf besar',
          style: TextStyle(
            fontSize: isTablet ? 22 : 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black45,
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Pilih huruf kecilnya!',
          style: TextStyle(
            fontSize: isTablet ? 26 : 16,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black54,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: _choices.map((choice) {
            final isSelected = _selectedAnswer == choice;
            return _ScaleOptionButton(
              onTap: (!_canAnswer || _answered || _isSubmitting)
                  ? null
                  : () => setState(() => _selectedAnswer = choice),
              isSelected: isSelected,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFE082)
                      : Colors.white
                          .withOpacity(_answered && !isSelected ? 0.6 : 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFF5A4FCF),
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: isTablet ? 56 : 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: isSelected
                          ? const Color(0xFF4A148C)
                          : const Color(0xFF5A4FCF).withOpacity(
                              _answered && !isSelected ? 0.6 : 1.0),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(
          isEnabled: _canAnswer &&
              !_answered &&
              !_isSubmitting &&
              _selectedAnswer != null,
          onSubmit: _handleSubmitAnswer,
          isTablet: isTablet,
        ),
      ],
    );
  }

  // 7. URUTKAN HURUF
  Widget _buildUrutkanHuruf() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A4FCF).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Urutkan huruf sesuai alfabet!',
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Huruf yang tersedia:',
          style: TextStyle(
            fontSize: isTablet ? 20 : 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black45,
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _shuffledLetters.asMap().entries.map((entry) {
            final i = entry.key;
            final letter = entry.value;
            final isUsed = _selectedIndices.contains(i);
            return _ScaleOptionButton(
              onTap: isUsed || _answered || _isSubmitting || !_canAnswer
                  ? null
                  : () {
                      setState(() {
                        _selectedIndices.add(i);
                        _userAnswer.add(letter);
                      });
                    },
              child: Container(
                width: isTablet ? 75 : 50,
                height: isTablet ? 75 : 50,
                decoration: BoxDecoration(
                  color: isUsed
                      ? Colors.grey.withOpacity(0.4)
                      : const Color(0xFFFFD966).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUsed ? Colors.grey : const Color(0xFFFFAA00),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: isUsed ? Colors.grey : const Color(0xFF5A4FCF),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Urutan kamu:',
          style: TextStyle(
            fontSize: isTablet ? 20 : 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black45,
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_shuffledLetters.length, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isTablet ? 80 : 46,
              height: isTablet ? 85 : 50,
              decoration: BoxDecoration(
                color: _userAnswer.length > i
                    ? const Color(0xFF7F77DD)
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF5A4FCF)
                      .withOpacity(_userAnswer.length > i ? 1.0 : 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _userAnswer.length > i ? _userAnswer[i].toUpperCase() : '',
                  style: TextStyle(
                    fontSize: isTablet ? 38 : 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userAnswer.isNotEmpty &&
                !_answered &&
                !_isSubmitting &&
                _canAnswer) ...[
              AssetButton(
                normalAsset: AppImages.btnDeleteNormal,
                pressedAsset: AppImages.btnDeletePressed,
                onTap: () {
                  setState(() {
                    _userAnswer.removeLast();
                    _selectedIndices.removeLast();
                  });
                },
                width: isTablet ? 140 : 90,
                height: isTablet ? 64 : 44,
              ),
              const SizedBox(width: 16),
            ],
            _buildSubmitButton(
              isEnabled: _canAnswer &&
                  !_answered &&
                  !_isSubmitting &&
                  _userAnswer.length == _shuffledLetters.length,
              onSubmit: _handleSubmitAnswer,
              isTablet: isTablet,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        _saveCurrentDraft();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/stage-map');
        }
      },
      child: BgScaffold(
        backgroundAsset: AppImages.bgInStage,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            return Stack(
              children: [
                // 1. TOMBOL BACK pojok kiri atas
                Positioned(
                  top: screenWidth >= 600 ? 45 : 10,
                  left: 16,
                  child: AssetButton(
                    normalAsset: AppImages.btnBackNormal,
                    pressedAsset: AppImages.btnBackPressed,
                    onTap: () {
                      _saveCurrentDraft();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/stage-map');
                      }
                    },
                    width: screenWidth >= 600 ? 120 : 80,
                    height: screenWidth >= 600 ? 66 : 44,
                  ),
                ),

                // 2. PROGRESS BAR soal (left: 110 & right: 110 untuk mencegah overlap dengan tombol back & skor)
                Positioned(
                  top: screenWidth >= 600 ? 55 : 10,
                  left: screenWidth >= 600 ? 180 : 110,
                  right: screenWidth >= 600 ? 180 : 110,
                  child: Column(
                    children: [
                      Text(
                        'Soal ${_currentQuestion + 1} dari $_totalQuestions',
                        style: TextStyle(
                          fontSize: screenWidth >= 600 ? 22 : 14,
                          fontFamily: 'Fredoka',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black45,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _totalQuestions > 0
                            ? (_currentQuestion + 1) / _totalQuestions
                            : 0.0,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF5A4FCF)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

                // 3. SKOR & NOMOR STAGE pojok kanan atas
                Positioned(
                  top: screenWidth >= 600 ? 60 : 25,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A4FCF).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppImages.icStar,
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_score',
                              style: TextStyle(
                                fontSize: screenWidth >= 600 ? 26 : 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(
                          top: screenWidth >= 600 ? 48 : 51,
                          right: screenWidth >= 600 ? 70 : 24,
                        ),
                        child: Text(
                          '${_currentQuestion + 1}',
                          style: TextStyle(
                            fontSize: screenWidth >= 600 ? 36 : 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                  blurRadius: 0,
                                  color: Colors.black87,
                                  offset: Offset(-2, -2)),
                              Shadow(
                                  blurRadius: 0,
                                  color: Colors.black87,
                                  offset: Offset(2, -2)),
                              Shadow(
                                  blurRadius: 0,
                                  color: Colors.black87,
                                  offset: Offset(-2, 2)),
                              Shadow(
                                  blurRadius: 0,
                                  color: Colors.black87,
                                  offset: Offset(2, 2)),
                              Shadow(
                                  blurRadius: 6,
                                  color: Colors.black54,
                                  offset: Offset.zero),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. AREA SOAL (posisi seimbang agar pas di tengah jalan dan tidak menempel bar atas/bawah)
                Positioned(
                  top: screenWidth >= 600 ? 130 : 95,
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: _buildQuestionWidget(),
                ),

                // 5. POPUP HASIL
                if (_showResult)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.6, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            _isCorrect
                                ? AppImages.popupCorrect
                                : AppImages.popupTryAgain,
                            width: screenWidth * 0.65,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScaleOptionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;

  const _ScaleOptionButton({
    required this.child,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<_ScaleOptionButton> createState() => _ScaleOptionButtonState();
}

class _ScaleOptionButtonState extends State<_ScaleOptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.88;
    } else if (widget.isSelected) {
      scale = 1.10;
    }

    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            },
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
