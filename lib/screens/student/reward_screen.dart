import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class RewardScreen extends StatefulWidget {
  final int score;
  final int stageId;
  
  const RewardScreen({
    super.key,
    required this.score,
    required this.stageId,
  });

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  int _starCount = 0;
  bool _showContent = false;

  int _getStarCount(int score) {
    if (score >= 90) return 3;
    if (score >= 70) return 2;
    if (score >= 50) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    AudioService().stopBGM();
    _starCount = _getStarCount(widget.score);

    // Play audio bintang sesuai skor
    if (_starCount == 3) {
      AudioService().playSFX(AppAudio.bintang3);
    } else if (_starCount == 2) {
      AudioService().playSFX(AppAudio.bintang2);
    } else {
      AudioService().playSFX(AppAudio.bintang1);
    }

    // Play BGM sesuai jumlah bintang setelah delay 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (_starCount >= 2) {
          AudioService().playBGM(AppAudio.bgmResultGood);
        } else {
          AudioService().playBGM(AppAudio.bgmResultFail);
        }
      }
    });

    // Tampilkan konten dengan animasi delay 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  void dispose() {
    AudioService().stopBGM();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/stage-map');
        }
      },
      child: BgScaffold(
      backgroundAsset: AppImages.bgReward,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = ResponsiveHelper.isTablet(screenWidth);

          return Stack(
            children: [
              // 1. JUDUL "Hasil Stage X"
              Positioned(
                top: screenHeight * 0.06,
                left: 0,
                right: 0,
                child: Text(
                  'Stage ${widget.stageId} Selesai!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 40 : 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. IKON TROPHY + SKOR (tengah)
              Positioned(
                top: screenHeight * 0.25,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      // Trophy
                      Image.asset(
                        AppImages.icTrophy,
                        width: isTablet ? 140 : 80,
                        height: isTablet ? 140 : 80,
                      ),
                      SizedBox(height: isTablet ? 16 : 8),
                      
                      // Skor
                      Text(
                        '${widget.score}',
                        style: TextStyle(
                          fontSize: isTablet ? 72 : 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Fredoka',
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black45,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Poin',
                        style: TextStyle(
                          fontSize: isTablet ? 30 : 20,
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bintang
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          return AnimatedScale(
                            scale: _showContent 
                              ? (i < _starCount ? 1.0 : 0.7)
                              : 0.0,
                            duration: Duration(
                              milliseconds: 400 + (i * 150)),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 8),
                              child: Image.asset(
                                AppImages.icStar,
                                width: isTablet ? 80 : 44,
                                height: isTablet ? 80 : 44,
                                color: i < _starCount
                                  ? null
                                  : Colors.grey.withOpacity(0.4),
                                colorBlendMode: BlendMode.modulate,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: isTablet ? 20 : 10),
                      
                      // Pesan motivasi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.score >= 90
                            ? 'Luar Biasa!\nKamu Hebat! 🎉'
                            : widget.score >= 70
                              ? 'Bagus Sekali!\nTerus Semangat! ⭐'
                              : widget.score >= 50
                                ? 'Cukup Baik!\nCoba Lagi Ya! ✨'
                                : 'Jangan Menyerah!\nAyo Coba Lagi! 💪',
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 18,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.4,
                            shadows: const [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black45,
                                offset: Offset(1, 1),
                              )
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. TOMBOL AKSI (bawah)
              Positioned(
                bottom: screenHeight * 0.04,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      // Tombol Finish → ke halaman map stage
                      AssetButton(
                        normalAsset: AppImages.btnFinishNormal,
                        pressedAsset: AppImages.btnFinishPressed,
                        onTap: () {
                          AudioService().stopBGM();
                          context.go('/stage-map');
                        },
                        width: isTablet ? (screenWidth * 0.58).clamp(380.0, 520.0) : screenWidth * 0.55,
                        height: isTablet ? 115 : 66,
                      ),
                    ],
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
