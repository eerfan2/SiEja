import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class SelectObjekScreen extends StatefulWidget {
  const SelectObjekScreen({super.key});

  @override
  State<SelectObjekScreen> createState() => _SelectObjekScreenState();
}

class _SelectObjekScreenState extends State<SelectObjekScreen> {
  @override
  void initState() {
    super.initState();
    AudioService().stopBGM();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await AudioService().playSFX(AppAudio.introPilihGambar);
      }
    });
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

                // 2. JUDUL di atas
                Positioned(
                  top: screenHeight * 0.05,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Pilih Gambar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 24,
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
                ),

                // 3. GRID 26 OBJEK (KATA A-Z)
                Positioned(
                  top: screenHeight * 0.12,
                  left: isTablet ? 20 : 12,
                  right: isTablet ? 20 : 12,
                  bottom: 16,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: isTablet ? 16 : 8,
                      mainAxisSpacing: isTablet ? 16 : 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: AppImages.hurufKeGambar.length,
                    itemBuilder: (context, index) {
                      final letter = AppImages.hurufKeGambar.keys.elementAt(index);
                      final kata = AppImages.hurufKeKata[letter]!;
                      final gambar = AppImages.hurufKeGambar[letter]!;

                      return GestureDetector(
                        onTap: () async {
                          await context.push('/spell-guided', extra: {
                            'letter': letter,
                            'kata': kata,
                            'gambar': gambar,
                          });
                          if (mounted) {
                            AudioService().playBGM(AppAudio.bgmHome);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Template kartu selang-seling
                            Image.asset(
                              index % 2 == 0
                                  ? AppImages.cardTemplateBlue
                                  : AppImages.cardTemplateGreen,
                              fit: BoxFit.fill,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            // Gambar objek saja (tanpa nama)
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              child: Image.asset(
                                gambar,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
