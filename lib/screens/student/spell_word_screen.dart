import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class SpellWordScreen extends StatefulWidget {
  const SpellWordScreen({super.key});

  @override
  State<SpellWordScreen> createState() => _SpellWordScreenState();
}

class _SpellWordScreenState extends State<SpellWordScreen> {
  String _currentWord = '';
  String _currentLetter = '';
  List<Map<String, dynamic>> _letterOptions = [];
  List<String> _userAnswer = [];
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _questionIndex = 0;
  List<String> _wordList = [];

  @override
  void initState() {
    super.initState();
    AudioService().stopBGM();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        AudioService().playSFX(AppAudio.introDengar);
      }
    });

    _wordList = AppImages.hurufKeKata.values.toList()..shuffle();
    _wordList = _wordList.take(5).toList();
    _loadQuestion();
  }

  @override
  void dispose() {
    AudioService().stopSFX();
    super.dispose();
  }

  void _loadQuestion() {
    if (_questionIndex >= _wordList.length) {
      // Semua soal selesai → ke reward
      context.go('/reward', extra: {'score': _score});
      return;
    }
    final word = _wordList[_questionIndex].toLowerCase();
    final letter = AppImages.hurufKeKata.entries
        .firstWhere((e) => e.value.toLowerCase() == word)
        .key;
    final letters = word.split('');
    letters.shuffle();
    final letterOptions = letters
        .asMap()
        .entries
        .map((e) => {
              'id': e.key,
              'letter': e.value,
              'isUsed': false,
            })
        .toList();

    setState(() {
      _currentWord = word;
      _currentLetter = letter;
      _letterOptions = letterOptions;
      _userAnswer = [];
      _showResult = false;
    });
    // Play audio kata
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        AudioService().playSFX(AppAudio.kata(_currentWord));
      }
    });
  }

  void _checkAnswer() {
    final answer = _userAnswer.join('');
    final isCorrect = answer == _currentWord;
    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      if (isCorrect) _score += 20;
    });
    
    if (isCorrect) {
      AudioService().playSFX(AppAudio.feedbackBenar2);
    } else {
      AudioService().playSFX(AppAudio.feedbackSalah2);
    }
    
    // Auto lanjut setelah 1.5 detik
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _questionIndex++;
          _showResult = false;
        });
        _loadQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/select-objek');
        }
      },
      child: BgScaffold(
      backgroundAsset: AppImages.bgSpellWord,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 1. TOMBOL BACK pojok kiri atas
              Positioned(
                top: 16,
                left: 16,
                child: AssetButton(
                  normalAsset: AppImages.btnBackNormal,
                  pressedAsset: AppImages.btnBackPressed,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/select-objek');
                    }
                  },
                  width: MediaQuery.of(context).size.width >= 600 ? 120 : 80,
                  height: MediaQuery.of(context).size.width >= 600 ? 66 : 44,
                ),
              ),

              // 2. PROGRESS BAR soal
              Positioned(
                top: screenHeight * 0.06,
                left: 24,
                right: 24,
                child: Column(
                  children: [
                    Text(
                      'Soal ${_questionIndex + 1} dari ${_wordList.length}',
                      style: const TextStyle(
                        fontSize: 14,
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
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _wordList.isEmpty
                          ? 0
                          : (_questionIndex + 1) / _wordList.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF5A4FCF)),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              // 3. KARTU SOAL
              Positioned(
                top: screenHeight * 0.08,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      AppImages.cardTemplateBlue,
                      width: screenWidth * 0.84,
                      fit: BoxFit.fitWidth,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gambar benda
                          Image.asset(
                            AppImages.hurufKeGambar[_currentLetter] ?? '',
                            width: screenWidth * 0.50,
                            height: screenWidth * 0.50,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tombol dengar kata
                          GestureDetector(
                            onTap: () => AudioService()
                                .playSFX(AppAudio.kata(_currentWord)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AppImages.icSound,
                                    width:48, height: 48),
                                const SizedBox(width: 7),
                                const Text(
                                  'Dengarkan kata!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Fredoka',
                                    color: Color(0xFF5A4FCF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Teks "Susun hurufnya!"
              Positioned(
                top: screenHeight * 0.53,
                left: 0,
                right: 0,
                child: const Text(
                  'Susun hurufnya!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      // Outline stroke (warna ungu gelap)
                      Shadow(color: Color(0xFF5A4FCF), offset: Offset(-1, -1), blurRadius: 2),
                      Shadow(color: Color(0xFF5A4FCF), offset: Offset(1, -1), blurRadius: 2),
                      Shadow(color: Color(0xFF5A4FCF), offset: Offset(-1, 1), blurRadius: 2),
                      Shadow(color: Color(0xFF5A4FCF), offset: Offset(1, 1), blurRadius: 2),
                      // Drop shadow utama
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black87,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Slot jawaban kosong
              Positioned(
                top: screenHeight * 0.58,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _currentWord.length, (i) {
                      final isTablet = screenWidth >= 600;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4),
                        width: isTablet ? 68 : 50,
                        height: isTablet ? 76 : 58,
                        decoration: BoxDecoration(
                          color: _userAnswer.length > i
                            ? const Color(0xFF7F77DD)
                            : Colors.white.withOpacity(0.8),
                          borderRadius: 
                            BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF5A4FCF),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _userAnswer.length > i
                              ? _userAnswer[i].toUpperCase()
                              : '',
                            style: TextStyle(
                              fontSize: isTablet ? 38 : 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ),

              // Huruf pilihan acak
              Positioned(
                top: screenHeight * 0.70,
                left: 16,
                right: 16,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _letterOptions.map((option) {
                    final isTablet = screenWidth >= 600;
                    return GestureDetector(
                      onTap: option['isUsed']
                          ? null
                          : () {
                              if (_userAnswer.length < _currentWord.length) {
                                setState(() {
                                  option['isUsed'] = true;
                                  _userAnswer.add(option['letter']);
                                });
                              }
                            },
                      child: AnimatedScale(
                        scale: option['isUsed'] ? 0.8 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: isTablet ? 68 : 52,
                          height: isTablet ? 68 : 52,
                          decoration: BoxDecoration(
                            color: option['isUsed']
                                ? Colors.grey.withOpacity(0.5)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: option['isUsed']
                                  ? Colors.grey
                                  : const Color(0xFF5A4FCF),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              option['letter'].toUpperCase(),
                              style: TextStyle(
                                fontSize: isTablet ? 32 : 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: option['isUsed']
                                    ? Colors.grey
                                    : const Color(0xFF5A4FCF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Tombol Hapus + Cek Jawaban
              Positioned(
                bottom: screenHeight * 0.04,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AssetButton(
                      normalAsset: AppImages.btnDeleteNormal,
                      pressedAsset: AppImages.btnDeletePressed,
                      onTap: () {
                        if (_userAnswer.isNotEmpty) {
                          setState(() {
                            for (int i = 
                              _letterOptions.length - 1;
                              i >= 0; i--) {
                              if (_letterOptions[i]
                                  ['isUsed']) {
                                _letterOptions[i]
                                  ['isUsed'] = false;
                                break;
                              }
                            }
                            _userAnswer.removeLast();
                          });
                        }
                      },
                      width: screenWidth >= 600 ? 160 : 120,
                      height: screenWidth >= 600 ? 64 : 48,
                    ),
                    const SizedBox(width: 16),
                    AssetButton(
                      normalAsset: AppImages.btnCheckNormal,
                      pressedAsset: AppImages.btnCheckPressed,
                      onTap: _userAnswer.length == 
                        _currentWord.length
                          ? _checkAnswer
                          : () {},
                      width: screenWidth >= 600 ? 170 : 130,
                      height: screenWidth >= 600 ? 64 : 48,
                    ),
                  ],
                ),
              ),

              // 7. POPUP HASIL (benar/salah)
              if (_showResult)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: Center(
                      child: Image.asset(
                        _isCorrect
                            ? AppImages.popupCorrect
                            : AppImages.popupTryAgain,
                        width: screenWidth * 0.7,
                        fit: BoxFit.fitWidth,
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
