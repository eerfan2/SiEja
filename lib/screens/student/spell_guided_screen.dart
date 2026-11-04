import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class SpellGuidedScreen extends StatefulWidget {
  final String letter;
  final String kata;
  final String gambar;

  const SpellGuidedScreen({
    super.key,
    required this.letter,
    required this.kata,
    required this.gambar,
  });

  @override
  State<SpellGuidedScreen> createState() => _SpellGuidedScreenState();
}

class _SpellGuidedScreenState extends State<SpellGuidedScreen> {
  List<String> _userAnswer = [];
  bool _isComplete = false;
  bool _showSuccess = false;
  int _shakeIndex = -1;

  @override
  void initState() {
    super.initState();
    _userAnswer = [];
    _isComplete = false;
    _showSuccess = false;
    _shakeIndex = -1;
    AudioService().stopBGM();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await AudioService().playSFX(AppAudio.introSusun);
      }
    });
  }

  @override
  void dispose() {
    AudioService().stopSFX();
    super.dispose();
  }

  void _onLetterTap(String letter) {
    if (_isComplete) return;
    final currentIndex = _userAnswer.length;
    if (currentIndex >= widget.kata.length) return;

    final expectedLetter = widget.kata[currentIndex].toUpperCase();

    if (letter == expectedLetter) {
      // Huruf benar → masukkan ke jawaban
      setState(() {
        _userAnswer.add(letter);
        if (_userAnswer.length == widget.kata.length) {
          _isComplete = true;
        }
      });
    } else {
      // Huruf salah → animasi shake pada kotak + suara huruf yang benar
      setState(() => _shakeIndex = currentIndex);
      AudioService().playSFX(AppAudio.huruf(expectedLetter.toLowerCase()));
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _shakeIndex = -1);
        }
      });
    }
  }

  void _onComplete() {
    if (_showSuccess) return; // Mencegah pemanggilan ganda feedback
    // Mainkan suara instruksi random (feedback_benar, feedback_benar2, feedback_benar3)
    final random = Random();
    final feedbacks = [
      AppAudio.feedbackBenar,
      AppAudio.feedbackBenar2,
      AppAudio.feedbackBenar3,
    ];
    final chosenFeedback = feedbacks[random.nextInt(feedbacks.length)];
    AudioService().playSFX(chosenFeedback);

    setState(() {
      _showSuccess = true;
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
          final isTablet = screenWidth >= 600;

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
                  width: isTablet ? 120 : 80,
                  height: isTablet ? 66 : 44,
                ),
              ),

              // 2. GAMBAR OBJEK (tengah atas)
              Positioned(
                top: screenHeight * 0.08,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Gambar objek dalam frame
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          AppImages.cardTemplateBlue,
                          width: screenWidth * 0.55,
                          fit: BoxFit.fitWidth,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            widget.gambar,
                            width: screenWidth * 0.35,
                            height: screenWidth * 0.30,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Nama objek
                    Text(
                      widget.kata.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black54,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => AudioService().playSFX(AppAudio.kata(widget.kata.toLowerCase())),
                      child: Image.asset(
                        AppImages.icSound,
                        width: isTablet ? 72 : 56,
                        height: isTablet ? 72 : 56,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. KOTAK JAWABAN DENGAN PANDUAN HURUF
              Positioned(
                top: screenHeight * (isTablet ? 0.58 : 0.52),
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'Isi huruf yang tepat!',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.kata.length, (i) {
                        final isFilledByUser = _userAnswer.length > i;
                        final guideChar = widget.kata[i].toUpperCase();

                        return TweenAnimationBuilder(
                          tween: Tween<double>(
                              begin: 0, end: _shakeIndex == i ? 1 : 0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(
                                  value > 0.5
                                      ? (value - 0.5) * 20
                                      : value * -20,
                                  0),
                              child: child,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: isTablet ? 68 : 42,
                            height: isTablet ? 76 : 50,
                            decoration: BoxDecoration(
                              color: isFilledByUser
                                  ? const Color(0xFF7F77DD)
                                  : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF5A4FCF),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isFilledByUser
                                  ? TweenAnimationBuilder<double>(
                                      key: ValueKey<String>('guided_slot_${i}_${_userAnswer[i]}'),
                                      tween: Tween<double>(begin: 0.6, end: 1.0),
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutBack,
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: Text(
                                        _userAnswer[i].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: isTablet ? 40 : 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Fredoka',
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      guideChar,
                                      style: TextStyle(
                                        fontSize: isTablet ? 40 : 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        // Huruf panduan: putus-putus/transparan
                                        color: const Color(0xFF5A4FCF)
                                            .withOpacity(0.25),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // 4. KEYBOARD HURUF A-Z
              if (isTablet)
                Positioned(
                  top: screenHeight * 0.73,
                  left: 4,
                  right: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: 'abcdefg'.split('').map((l) => Expanded(flex: 2, child: _buildKey(l.toUpperCase()))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: 'hijklmn'.split('').map((l) => Expanded(flex: 2, child: _buildKey(l.toUpperCase()))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: 'opqrstu'.split('').map((l) => Expanded(flex: 2, child: _buildKey(l.toUpperCase()))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          ...('vwxyz'.split('').map((l) => Expanded(flex: 2, child: _buildKey(l.toUpperCase())))),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Positioned(
                  top: screenHeight * 0.67,
                  left: 8,
                  right: 8,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: 'abcdefghijklmnopqrstuvwxyz'.split('').map((l) {
                      final letter = l.toUpperCase();
                      return GestureDetector(
                        onTap: () => _onLetterTap(letter),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF5A4FCF),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: Color(0xFF5A4FCF),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // 5. TOMBOL CENTANG (aktif/nonaktif)
              Positioned(
                bottom: screenHeight * 0.01,
                right: 18,
                child: GestureDetector(
                  onTap: _isComplete ? _onComplete : null,
                  child: AnimatedScale(
                    scale: _isComplete ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _isComplete ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        AppImages.icCorrect,
                        width: isTablet ? 90 : 60,
                        height: isTablet ? 90 : 60,
                      ),
                    ),
                  ),
                ),
              ),

              // Popup sukses
              if (_showSuccess)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/template/frame_login.png',
                              width: isTablet ? 500 : 300,
                              fit: BoxFit.fitWidth,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    AppImages.icTrophy,
                                    width: isTablet ? 100 : 50,
                                    height: isTablet ? 60 : 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hebat! Kamu bisa\nmengeja ${widget.kata.toUpperCase()}!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 32 : 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: const Color(0xFF5A4FCF),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Tombol Kembali
                                      AssetButton(
                                        normalAsset: AppImages.btnBackNormal,
                                        pressedAsset: AppImages.btnBackPressed,
                                        onTap: () {
                                          if (context.canPop()) {
                                            context.pop();
                                          } else {
                                            context.go('/select-objek');
                                          }
                                        },
                                        width: isTablet ? 140 : 100,
                                        height: isTablet ? 56 : 44,
                                      ),
                                      const SizedBox(width: 12),
                                      // Tombol Lanjut
                                      AssetButton(
                                        normalAsset: AppImages.btnNextNormal,
                                        pressedAsset: AppImages.btnNextPressed,
                                        onTap: () {
                                          // Tutup popup dulu
                                          setState(() => _showSuccess = false);

                                          // Hitung index objek berikutnya
                                          final letters = AppImages.hurufKeGambar.keys.toList();
                                          final currentIndex = letters.indexOf(widget.letter);
                                          final nextIndex = (currentIndex + 1) % letters.length;
                                          final nextLetter = letters[nextIndex];
                                          final nextKata = AppImages.hurufKeKata[nextLetter]!;
                                          final nextGambar = AppImages.hurufKeGambar[nextLetter]!;

                                          // Navigate ke halaman baru dengan objek berikutnya
                                          context.go(
                                            '/spell-guided',
                                            extra: {
                                              'letter': nextLetter,
                                              'kata': nextKata,
                                              'gambar': nextGambar,
                                            },
                                          );
                                        },
                                        width: isTablet ? 140 : 100,
                                        height: isTablet ? 56 : 44,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildKey(String letter) {
    return GestureDetector(
      onTap: () => _onLetterTap(letter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF5A4FCF),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Fredoka',
              color: Color(0xFF5A4FCF),
            ),
          ),
        ),
      ),
    );
  }
}
