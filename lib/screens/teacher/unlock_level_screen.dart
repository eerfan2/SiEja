import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class UnlockLevelScreen extends StatefulWidget {
  const UnlockLevelScreen({super.key});

  @override
  State<UnlockLevelScreen> createState() => _UnlockLevelScreenState();
}

class _UnlockLevelScreenState extends State<UnlockLevelScreen> {
  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AudioService().playBGM(AppAudio.bgmHome);
    _loadStageData();
  }

  Future<void> _loadStageData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final firebaseStudents = await FirebaseService().getAllSiswa();
    final progressService = ProgressService();
    final currentSiswaId = progressService.currentSiswaId;

    final totalStudents = firebaseStudents.length;

    List<Map<String, dynamic>> stages = [];
    for (int i = 1; i <= 6; i++) {
      final stageId = i;
      int completedCount = 0;
      bool isUnlocked = stageId == 1;
      
      for (var s in firebaseStudents) {
        final progressMap = s['progress'] as Map<String, dynamic>? ?? {};
        final stageData = progressMap['stage$stageId'] as Map<String, dynamic>?;
        String sStatus = stageData?['status'] ?? (stageId == 1 ? 'unlocked' : 'locked');
        int sSkor = (stageData?['skor'] as num?)?.toInt() ?? 0;

        if (sStatus == 'unlocked' || sStatus == 'completed') {
          isUnlocked = true;
        }

        if (s['id'] == currentSiswaId) {
          final localSkor = progressService.getStageScore(stageId);
          final localStatus = progressService.getStageStatus(stageId);
          if (localSkor > sSkor) sSkor = localSkor;
          if (localStatus == 'completed') sStatus = 'completed';
        }

        if (sStatus == 'completed' || sSkor > 0) {
          completedCount++;
        }
      }

      stages.add({
        'id': stageId,
        'nama': 'Stage $stageId',
        'huruf': _getHurufRange(stageId),
        'status': isUnlocked ? 'unlocked' : 'locked',
        'completedCount': completedCount,
        'totalStudents': totalStudents,
      });
    }

    if (!mounted) return;
    setState(() {
      _stages = stages;
      _isLoading = false;
    });
  }

  String _getHurufRange(int stageId) {
    switch (stageId) {
      case 1:
        return 'A - E';
      case 2:
        return 'F - J';
      case 3:
        return 'K - O';
      case 4:
        return 'P - T';
      case 5:
        return 'U - Z';
      case 6:
        return 'A - Z';
      default:
        return '';
    }
  }

  Future<bool?> _showKonfirmasiToggleDialog(int stageId, bool unlock) {
    bool isBatalPressed = false;
    bool isYaPressed = false;

    final actionText = unlock ? 'membuka' : 'mengunci';
    final titleText =
        unlock ? 'Konfirmasi Buka Stage 🔓' : 'Konfirmasi Kunci Stage 🔒';
    final btnText = unlock ? 'Ya, Buka' : 'Ya, Kunci';
    final btnColor =
        unlock ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final btnPressColor =
        unlock ? const Color(0xFF1B5E20) : const Color(0xFF9A0007);

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (confirmContext) {
        final screenWidth = MediaQuery.of(confirmContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 48 : 42,
                  isTablet ? 56 : 50,
                  isTablet ? 48 : 42,
                  isTablet ? 36 : 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: unlock
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 12 : 10),
                    Text(
                      'Apakah Anda yakin ingin $actionText Stage $stageId?',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 12,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF4A3E3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 22 : 18),
                    StatefulBuilder(
                      builder: (context, setBtnState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTapDown: (_) =>
                                  setBtnState(() => isBatalPressed = true),
                              onTapUp: (_) {
                                setBtnState(() => isBatalPressed = false);
                                Navigator.pop(confirmContext, false);
                              },
                              onTapCancel: () =>
                                  setBtnState(() => isBatalPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 18,
                                  vertical: isTablet ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isBatalPressed
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: isTablet ? 15 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTapDown: (_) =>
                                  setBtnState(() => isYaPressed = true),
                              onTapUp: (_) {
                                setBtnState(() => isYaPressed = false);
                                Navigator.pop(confirmContext, true);
                              },
                              onTapCancel: () =>
                                  setBtnState(() => isYaPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 18,
                                  vertical: isTablet ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isYaPressed ? btnPressColor : btnColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  btnText,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: isTablet ? 15 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  void _toggleStage(int stageId, bool unlock) async {
    final setuju = await _showKonfirmasiToggleDialog(stageId, unlock);
    if (setuju != true) return;

    final progressService = ProgressService();
    final firebaseService = FirebaseService();
    if (unlock) {
      await progressService.unlockStageByTeacher(stageId);
      await firebaseService.unlockStageAllSiswa(stageId);
    } else {
      await progressService.lockStageByTeacher(stageId);
      await firebaseService.lockStageAllSiswa(stageId);
    }
    await _loadStageData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unlock
              ? 'Stage $stageId berhasil dibuka!'
              : 'Stage $stageId berhasil dikunci!',
          style: const TextStyle(fontFamily: 'Fredoka'),
        ),
        backgroundColor: unlock ? Colors.green : const Color(0xFF5A4FCF),
        duration: const Duration(seconds: 1),
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
        } else {
          context.go('/teacher-dashboard');
        }
      },
      child: BgScaffold(
      backgroundAsset: AppImages.bgDashboardTeacher,
      backgroundScale: 1.1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = ResponsiveHelper.isTablet(screenWidth);

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
                    } else {
                      context.go('/teacher-dashboard');
                    }
                  },
                  width: isTablet
                      ? TabletLayout.unlockStageBackBtnWidth
                      : 80,
                  height: isTablet
                      ? TabletLayout.unlockStageBackBtnHeight
                      : 44,
                ),
              ),

              // 2. JUDUL HALAMAN (Badge / Banner warna #f8dc8f)
              Positioned(
                top: screenHeight *
                    (isTablet
                        ? TabletLayout.unlockStageTitleTopFactor
                        : 0.16),
                left: screenWidth *
                    (isTablet
                        ? TabletLayout.unlockStageTitleHFactor
                        : 0.21),
                right: screenWidth *
                    (isTablet
                        ? TabletLayout.unlockStageTitleHFactor
                        : 0.21),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet
                        ? TabletLayout.unlockStageTitlePaddingH
                        : 16,
                    vertical: isTablet
                        ? TabletLayout.unlockStageTitlePaddingV
                        : 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8DC8F),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppImages.icLevelSettings,
                        width: isTablet
                            ? TabletLayout.unlockStageTitleIconSize
                            : 24,
                        height: isTablet
                            ? TabletLayout.unlockStageTitleIconSize
                            : 24,
                      ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Text(
                        'Kelola Stage Siswa',
                        style: TextStyle(
                          fontSize: isTablet
                              ? TabletLayout.unlockStageTitleFontSize
                              : 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Fredoka',
                          color: const Color(0xFF4E342E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. LIST STAGE DENGAN TOGGLE (Area Scroll sesuai Papan)
              Positioned(
                top: screenHeight *
                    (isTablet
                        ? TabletLayout.unlockStageListTopFactor
                        : 0.25),
                bottom: screenHeight *
                    (isTablet
                        ? TabletLayout.unlockStageListBottomFactor
                        : 0.31),
                left: screenWidth *
                    (isTablet
                        ? TabletLayout.unlockStageListHFactor
                        : 0.21),
                right: screenWidth *
                    (isTablet
                        ? TabletLayout.unlockStageListHFactor
                        : 0.21),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5A4FCF),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _stages.length,
                          itemBuilder: (context, index) {
                            final stage = _stages[index];
                            final status = stage['status'];
                            final isLocked = status == 'locked';
                            final completedCount = stage['completedCount'] ?? 0;
                            final totalStudents = stage['totalStudents'] ?? 0;

                            return Container(
                              margin: EdgeInsets.only(
                                bottom: isTablet
                                    ? TabletLayout.unlockStageCardMarginBottom
                                    : 12,
                              ),
                              padding: EdgeInsets.all(
                                isTablet
                                    ? TabletLayout.unlockStageCardPadding
                                    : 14,
                              ),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? Colors.white.withOpacity(0.75)
                                    : const Color(0xFFE8F5E9).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLocked
                                      ? Colors.grey.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Gambar status
                                  Image.asset(
                                    AppImages.stageIcon(status, stage['id'] as int),
                                    width: isTablet
                                        ? TabletLayout.unlockStageIconSize
                                        : 50,
                                    height: isTablet
                                        ? TabletLayout.unlockStageIconSize
                                        : 50,
                                  ),
                                  SizedBox(width: isTablet ? 16 : 12),

                                  // Info stage
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${stage['nama']} — Materi Bawaan ${stage['huruf']}',
                                          style: TextStyle(
                                            fontSize: isTablet
                                                ? TabletLayout.unlockStageNameFontSize
                                                : 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Fredoka',
                                            color: const Color(0xFF5A4FCF),
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 4 : 2),
                                        Text(
                                          'Selesai $completedCount / $totalStudents anak',
                                          style: TextStyle(
                                            fontSize: isTablet
                                                ? TabletLayout.unlockStageProgressFontSize
                                                : 11,
                                            fontFamily: 'Fredoka',
                                            fontWeight: FontWeight.w600,
                                            color: completedCount > 0
                                                ? const Color(0xFF1B5E20)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Toggle Switch & Status Text
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.scale(
                                        scale: isTablet
                                            ? TabletLayout.unlockStageSwitchScale
                                            : 1.0,
                                        child: Switch(
                                          value: !isLocked,
                                          onChanged: (value) {
                                            _toggleStage(stage['id'], value);
                                          },
                                          activeColor: const Color(0xFF5A4FCF),
                                        ),
                                      ),
                                      Text(
                                        !isLocked ? '🔓 Terbuka' : '🔒 Terkunci',
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? TabletLayout.unlockStageStatusFontSize
                                              : 11,
                                          fontFamily: 'Fredoka',
                                          fontWeight: FontWeight.bold,
                                          color: !isLocked
                                              ? const Color(0xFF1B5E20)
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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
