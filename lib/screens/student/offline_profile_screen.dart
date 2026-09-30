import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/connectivity_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class OfflineProfileScreen extends StatefulWidget {
  const OfflineProfileScreen({super.key});

  @override
  State<OfflineProfileScreen> createState() => _OfflineProfileScreenState();
}

class _OfflineProfileScreenState extends State<OfflineProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/offline-dashboard');
        }
      },
      child: BgScaffold(
        backgroundAsset: 'assets/images/background/bg_profile.png',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            assert(screenWidth >= 0 && screenHeight >= 0);

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
                        context.go('/offline-dashboard');
                      }
                    },
                    width: MediaQuery.of(context).size.width >= 600 ? 120 : 80,
                    height: MediaQuery.of(context).size.width >= 600 ? 66 : 44,
                  ),
                ),

                // 2. KONTEN TENGAH LAYAR (Ikon wifi off + Teks pesan)
                Positioned(
                  top: 0,
                  bottom: 155,
                  left: 18,
                  right: 54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon wifi off
                        Icon(
                          Icons.wifi_off_rounded,
                          size: screenWidth >= 600 ? 105 : 70,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 16),

                        // Teks utama
                        Text(
                          'Silahkan hubungkan ke jaringan\nuntuk melihat profil anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth >= 600 ? 16 : 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black45,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. TOMBOL HUBUNGKAN PADA JARINGAN (Terpisah di Tengah Bawah)
                Positioned(
                  bottom: screenHeight * 0.12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        final isConnected =
                            await ConnectivityService().checkConnection();
                        if (!context.mounted) return;
                        if (isConnected) {
                          context.go('/select-role');
                        } else {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text(
                                'Tidak Terhubung',
                                style: TextStyle(fontFamily: 'Fredoka'),
                              ),
                              content: const Text(
                                'Belum terhubung pada jaringan.\nPeriksa koneksi internet kamu.',
                                style: TextStyle(fontFamily: 'Fredoka'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      color: Color(0xFF5A4FCF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A4FCF),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5A4FCF)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi,
                              color: Colors.white,
                              size: screenWidth >= 600 ? 30 : 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Hubungkan pada jaringan',
                              style: TextStyle(
                                fontSize: screenWidth >= 600 ? 20 : 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: Colors.white,
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
}
