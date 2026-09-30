import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/widgets/asset_button.dart';

class LearnLetterScreen extends StatefulWidget {
  const LearnLetterScreen({super.key});

  @override
  State<LearnLetterScreen> createState() => _LearnLetterScreenState();
}

class _LearnLetterScreenState extends State<LearnLetterScreen> {
  String _selectedLetter = 'a';

  @override
  void initState() {
    super.initState();
    AudioService().stopBGM();
  }

  @override
  void dispose() {
    AudioService().stopSFX();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (context.canPop()) {
          context.pop();
        } else if (ProgressService().currentSiswaId.isNotEmpty) {
          context.go('/student-dashboard');
        } else {
          context.go('/offline-dashboard');
        }
      },
      child: BgScaffold(
      backgroundAsset: AppImages.bgLearnLetter,
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
                    } else if (ProgressService().currentSiswaId.isNotEmpty) {
                      context.go('/student-dashboard');
                    } else {
                      context.go('/offline-dashboard');
                    }
                  },
                  width: isTablet ? 120 : 80,
                  height: isTablet ? 66 : 44,
                ),
              ),

              // 2. KARTU HURUF (tengah atas)
              Positioned(
                top: screenHeight * 0.10,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: SizedBox(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Template kartu fullsize
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/template/card_huruf.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        // Konten 2 kolom
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // KOLOM KIRI — Gambar + Nama
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: () => AudioService().playSFX(
                                      AppAudio.kata(
                                        AppImages.hurufKeKata[_selectedLetter]!
                                          .toLowerCase()
                                      )
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppImages.hurufKeGambar[_selectedLetter]!,
                                          width: screenWidth * 0.33,
                                          height: screenWidth * 0.33,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stack) =>
                                            const Icon(Icons.image_not_supported,
                                              size: 60, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppImages.hurufKeKata[_selectedLetter]!,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Fredoka',
                                            color: Color(0xFF5A4FCF),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // GARIS PEMBATAS TENGAH
                                Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A4FCF).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                                // KOLOM KANAN — Huruf Besar | Huruf Kecil
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: () => AudioService().playSFX(
                                      AppAudio.huruf(_selectedLetter)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _selectedLetter.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: isTablet ? 72 : 52,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Fredoka',
                                            color: const Color(0xFF5A4FCF),
                                          ),
                                        ),
                                        Container(
                                          width: isTablet ? 50 : 40,
                                          height: isTablet ? 3 : 2,
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          color: const Color(0xFF5A4FCF).withOpacity(0.3),
                                        ),
                                        Text(
                                          _selectedLetter,
                                          style: TextStyle(
                                            fontSize: isTablet ? 72 : 52,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Fredoka',
                                            color: const Color(0xFFFF8FAB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hint tap untuk dengar di luar kartu
              Positioned(
                top: screenHeight * (isTablet ? 0.50 : 0.58),
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => AudioService().playSFX(
                    AppAudio.kata(
                      AppImages.hurufKeKata[_selectedLetter]!
                        .toLowerCase()
                    )
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        AppImages.icSound,
                        width: isTablet ? 72 : 56,
                        height: isTablet ? 72 : 56,
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      Text(
                        'Ketuk untuk dengar',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Fredoka',
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. KEYBOARD HURUF A-Z (bawah layar)
              if (isTablet)
                Positioned(
                  bottom: screenHeight * 0.05,
                  left: 4,
                  right: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: 'abcdefg'.split('').map((l) => Expanded(flex: 2, child: _buildTabletKey(l))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: 'hijklmn'.split('').map((l) => Expanded(flex: 2, child: _buildKeyTablet(l))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: 'opqrstu'.split('').map((l) => Expanded(flex: 2, child: _buildKeyTablet(l))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          ...('vwxyz'.split('').map((l) => Expanded(flex: 2, child: _buildKeyTablet(l)))),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Positioned(
                  bottom: screenHeight * 0.02,
                  left: 8,
                  right: 8,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(26, (index) {
                      final letter = String.fromCharCode('a'.codeUnitAt(0) + index);
                      final isSelected = letter == _selectedLetter;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedLetter = letter);
                          AudioService().playSFX(AppAudio.huruf(letter));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7F77DD)
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF5A4FCF)
                                  : Colors.transparent,
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
                              letter.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF5A4FCF),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
  }

  Widget _buildTabletKey(String letter) => _buildKeyTablet(letter);

  Widget _buildKeyTablet(String letter) {
    final isSelected = letter == _selectedLetter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLetter = letter);
        AudioService().playSFX(AppAudio.huruf(letter));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7F77DD)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5A4FCF)
                : Colors.transparent,
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
            letter.toUpperCase(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Fredoka',
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF5A4FCF),
            ),
          ),
        ),
      ),
    );
  }
}
