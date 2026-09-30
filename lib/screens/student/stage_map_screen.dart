import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/services/firebase_service.dart';

class StageMapScreen extends StatefulWidget {
  const StageMapScreen({super.key});

  @override
  State<StageMapScreen> createState() => _StageMapScreenState();
}

class _StageMapScreenState extends State<StageMapScreen> {
  List<Map<String, dynamic>> _stages = [];
  List<String> _statusList = [];
  List<int> _skorList = [];

  @override
  void initState() {
    super.initState();

    _stages = [
      {'id': 1, 'nama': 'Stage 1', 'huruf': 'A - E', 'lokasi': 'Awal Petualangan'},
      {'id': 2, 'nama': 'Stage 2', 'huruf': 'F - J', 'lokasi': 'Taman Bintang'},
      {'id': 3, 'nama': 'Stage 3', 'huruf': 'K - O', 'lokasi': 'Desa Alfabet'},
      {'id': 4, 'nama': 'Stage 4', 'huruf': 'P - T', 'lokasi': 'Pelangi Mengeja'},
      {'id': 5, 'nama': 'Stage 5', 'huruf': 'U - Z', 'lokasi': 'Taman Huruf'},
      {'id': 6, 'nama': 'Stage 6', 'huruf': 'A - Z', 'lokasi': 'Istana Literasi'},
    ];

    _loadStageData();
    _initBGM();
  }

  Future<void> _loadStageData() async {
    // 1. Tampilkan data lokal terlebih dahulu agar UI cepat
    final List<String> statusList = [];
    final List<int> skorList = [];
    for (int i = 1; i <= 6; i++) {
      statusList.add(ProgressService().getStageStatus(i));
      skorList.add(ProgressService().getStageScore(i));
    }
    if (mounted) {
      setState(() {
        _statusList = statusList;
        _skorList = skorList;
      });
    }

    // 2. Sinkronisasi dengan Firebase (mengambil status lock/unlock terbaru dari guru)
    final siswaId = ProgressService().currentSiswaId;
    if (siswaId.isNotEmpty) {
      try {
        final progress = await FirebaseService().getProgress(siswaId);
        await ProgressService().loadStudentProgressFromFirebase({'progress': progress});
        
        // 3. Perbarui UI jika ada perubahan status
        final List<String> updatedStatus = [];
        final List<int> updatedSkor = [];
        for (int i = 1; i <= 6; i++) {
          updatedStatus.add(ProgressService().getStageStatus(i));
          updatedSkor.add(ProgressService().getStageScore(i));
        }
        
        if (mounted) {
          setState(() {
            _statusList = updatedStatus;
            _skorList = updatedSkor;
          });
        }
      } catch (e) {
        // Abaikan jika offline / gagal fetch
      }
    }
  }

  Future<void> _initBGM() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      AudioService().playBGM(AppAudio.bgmStage);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _getStarCount(int skor) {
    if (skor >= 90) return 3;
    if (skor >= 70) return 2;
    if (skor >= 50) return 1;
    return 0;
  }

  void _showLockedPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600;
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background popup
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Image.asset(
                      'assets/images/template/frame_login.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),

                  // Konten popup
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Teks utama
                        Text(
                          'Stage Terkunci! 🔒',
                          style: TextStyle(
                            fontSize: isTablet ? 30 : 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF5A4FCF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Teks penjelasan
                        Text(
                          'Tunggu gurumu untuk\nmembuka stage ini ya!',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 16,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF7B6FD4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Tombol OK
                        AssetButton(
                          normalAsset: AppImages.btnContinueNormal,
                          pressedAsset: AppImages.btnContinuePressed,
                          onTap: () => Navigator.of(context).pop(),
                          width: isTablet ? 200 : 140,
                          height: isTablet ? 75 : 50,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCompletedPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600;
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background popup
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Image.asset(
                      'assets/images/template/frame_login.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),

                  // Konten popup
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Teks utama
                        Text(
                          'Stage Selesai! 🎉',
                          style: TextStyle(
                            fontSize: isTablet ? 30 : 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF5A4FCF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Teks penjelasan
                        Text(
                          'Kamu sudah berhasil melewati stage ini!',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 16,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF7B6FD4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Tombol OK
                        AssetButton(
                          normalAsset: AppImages.btnContinueNormal,
                          pressedAsset: AppImages.btnContinuePressed,
                          onTap: () => Navigator.of(context).pop(),
                          width: isTablet ? 200 : 140,
                          height: isTablet ? 75 : 50,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMustCompletePreviousPopup(
      BuildContext context, int prevStageId, int targetStageId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600;
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Image.asset(
                      'assets/images/template/frame_login.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 55, 40, 35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stage $prevStageId Belum Selesai! 🔒',
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF5A4FCF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Kamu harus menyelesaikan Stage $prevStageId dulu ya sebelum bisa bermain di Stage $targetStageId!',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 13,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF7B6FD4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        AssetButton(
                          normalAsset: AppImages.btnContinueNormal,
                          pressedAsset: AppImages.btnContinuePressed,
                          onTap: () => Navigator.of(context).pop(),
                          width: isTablet ? 200 : 140,
                          height: isTablet ? 72 : 48,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageNode(
    Map<String, dynamic> stage,
    String status,
    int skor,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: () async {
        final stageId = stage['id'] as int;
        String currentStatus = status;

        final siswaId = ProgressService().currentSiswaId;
        if (siswaId.isNotEmpty) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          );

          final progress = await FirebaseService().getProgress(siswaId);
          if (context.mounted) Navigator.pop(context);

          final stageData = progress['stage$stageId'];
          if (stageData != null && stageData['status'] == 'locked') {
            currentStatus = 'locked';
            await ProgressService().lockStageByTeacher(stageId);
            if (mounted) {
              setState(() {
                _statusList[stageId - 1] = 'locked';
              });
            }
          }
        }

        if (currentStatus == 'locked') {
          _showLockedPopup(context);
        } else if (currentStatus == 'completed') {
          _showCompletedPopup(context);
        } else {
          // Pengecekan: harus menyelesaikan stage sebelumnya (stageId - 1)
          if (stageId > 1) {
            final prevStageId = stageId - 1;
            final prevStatus = ProgressService().getStageStatus(prevStageId);
            if (prevStatus != 'completed') {
              _showMustCompletePreviousPopup(context, prevStageId, stageId);
              return;
            }
          }

          await context.push('/stage', extra: {'stageId': stageId});
          if (mounted) {
            _loadStageData();
            AudioService().playBGM(AppAudio.bgmStage);
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gambar stage (ikon sudah include angka)
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                AppImages.stageIcon(status, stage['id'] as int),
                width: isTablet ? 110 : 75,
                height: isTablet ? 110 : 75,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Bintang skor
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Image.asset(
                AppImages.icStar,
                width: isTablet ? 22 : 16,
                height: isTablet ? 22 : 16,
                color: i < _getStarCount(skor)
                    ? null
                    : Colors.grey.withOpacity(0.5),
                colorBlendMode: BlendMode.modulate,
              );
            }),
          ),
        ],
      ),
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
      child: _statusList.length < 6
          ? const BgScaffold(
              backgroundAsset: AppImages.bgStageMap,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          : BgScaffold(
      backgroundAsset: AppImages.bgStageMap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = ResponsiveHelper.isTablet(screenWidth);

          return Stack(
            children: [
              // 1. TOMBOL BACK pojok kiri atas
              Positioned(
                top: 105,
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
                  width: screenWidth >= 600 ? 120 : 80,
                  height: screenWidth >= 600 ? 66 : 44,
                ),
              ),

              // 2. STAGE NODES — mengikuti jalur background

              // Stage 1 — bawah tengah
              Positioned(
                bottom: screenHeight * 0.02,
                left: screenWidth * 0.41,
                child: _buildStageNode(
                  _stages[0], _statusList[0], _skorList[0], isTablet),
              ),

              // Stage 2 — naik, geser kanan sedikit
              Positioned(
                bottom: screenHeight * 0.21,
                left: screenWidth * 0.46,
                child: _buildStageNode(
                  _stages[1], _statusList[1], _skorList[1], isTablet),
              ),

              // Stage 3 — naik, geser kiri
              Positioned(
                bottom: screenHeight * 0.37,
                left: screenWidth * 0.46,
                child: _buildStageNode(
                  _stages[2], _statusList[2], _skorList[2], isTablet),
              ),

              // Stage 4 — naik, geser kiri lagi
              Positioned(
                bottom: screenHeight * 0.53,
                left: screenWidth * 0.36,
                child: _buildStageNode(
                  _stages[3], _statusList[3], _skorList[3], isTablet),
              ),

              // Stage 5 — naik, kembali ke tengah
              Positioned(
                bottom: screenHeight * 0.61,
                left: screenWidth * 0.57,
                child: _buildStageNode(
                  _stages[4], _statusList[4], _skorList[4], isTablet),
              ),

              // Stage 6 — paling atas dekat kastil
              Positioned(
                bottom: screenHeight * 0.74,
                left: screenWidth * 0.64,
                child: _buildStageNode(
                  _stages[5], _statusList[5], _skorList[5], isTablet),
              ),
            ],
          );
        },
      ),
    ),
  );
  }
}
