import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _siswaData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AudioService().playBGM(AppAudio.bgmHome);
    _loadData();
  }

  Future<void> _loadData() async {
    final progressService = ProgressService();
    final siswaId = progressService.currentSiswaId;

    try {
      final doc = await FirebaseFirestore.instance.collection('siswa').doc(siswaId).get();
      if (doc.exists) {
        if (!mounted) return;
        setState(() {
          _siswaData = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error get student data: $e');
    }

    if (!mounted) return;
    setState(() {
      _siswaData = {};
      _isLoading = false;
    });
  }

  Widget _buildDetailItem(String label, String value, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 20 : 14,
            fontFamily: 'Fredoka',
            color: Color(0xFFFFD966),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black87,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 26 : 18,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black87,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
      ],
    );
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
        backgroundAsset: 'assets/images/background/bg_profile.png',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isTablet = screenWidth >= 600;

            return Stack(
              children: [
                // 1. TOMBOL BACK (Pojok kiri atas)
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
                    width: MediaQuery.of(context).size.width >= 600 ? 120 : 80,
                    height: MediaQuery.of(context).size.width >= 600 ? 66 : 44,
                  ),
                ),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5A4FCF)),
                  )
                else ...[
                  // 2. NAMA SISWA & JENIS KELAMIN (Atas)
                  Positioned(
                    top: screenHeight * 0.24,
                    left: isTablet ? 12 : 24,
                    right: isTablet ? 70 : 59,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            _siswaData['namaLengkap'] ?? '-',
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                )
                              ],
                            ),
                            textAlign: TextAlign.center,
                            softWrap: true,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _siswaData['jenisKelamin'] == 'perempuan'
                              ? '👧 Perempuan'
                              : '👦 Laki-laki',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: Colors.white.withValues(alpha: 0.85),
                            shadows: const [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black45,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. DATA USER (Tanpa background putih, Rata Kiri)
                  Positioned(
                    top: screenHeight * 0.35,
                    left: screenWidth * (isTablet ? 0.36 : 0.31),
                    right: screenWidth * (isTablet ? 0.10 : 0.15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                              'Username:',
                              _siswaData['username'] ?? '-',
                              isTablet,
                            ),
                            const SizedBox(width: 16),
                            _buildDetailItem(
                              'PIN:',
                              _siswaData['pin'] ?? '-',
                              isTablet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 45),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usia:',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 14,
                                  fontFamily: 'Fredoka',
                                  color: const Color(0xFFFFD966),
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black87,
                                      offset: Offset(1, 1),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Transform.translate(
                                offset: const Offset(-15, 0),
                                child: Text(
                                  '${_siswaData['usia'] ?? '-'} tahun',
                                  style: TextStyle(
                                    fontSize: isTablet ? 26 : 18,
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 6,
                                        color: Colors.black87,
                                        offset: Offset(1, 1),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
