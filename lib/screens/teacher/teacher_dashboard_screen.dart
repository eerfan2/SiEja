import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _hasUnreadNotification = false;
  bool _isLogoutPressed = false;
  int _totalStudents = 0;
  int _activeStudents = 0;
  int _activeStagesCount = 0;

  @override
  void initState() {
    super.initState();
    AudioService().playBGM(AppAudio.bgmHome);
    _loadData();
  }

  @override
  void dispose() {
    AudioService().stopBGM();
    super.dispose();
  }

  Future<void> _loadData() async {
    final progressService = ProgressService();
    final firebaseStudents = await FirebaseService().getAllSiswa();

    // 1. Hitung stage aktif dan cari stage terbuka tertinggi dari data siswa di Firestore
    int activeStages = 0;
    int highestUnlockedStage = 1;
    for (int i = 1; i <= 6; i++) {
      bool isUnlocked = i == 1; // Stage 1 selalu aktif
      
      for (var s in firebaseStudents) {
        final progressMap = s['progress'] as Map<String, dynamic>? ?? {};
        final stageData = progressMap['stage$i'] as Map<String, dynamic>?;
        String sStatus = stageData?['status'] ?? (i == 1 ? 'unlocked' : 'locked');
        
        if (sStatus == 'unlocked' || sStatus == 'completed') {
          isUnlocked = true;
          break;
        }
      }
      
      if (isUnlocked) {
        activeStages++;
        highestUnlockedStage = i;
      }
    }

    // 2. Hitung siswa yang sudah menyelesaikan stage terbuka tertinggi
    int completedHighestCount = 0;
    if (firebaseStudents.isNotEmpty) {
      for (var s in firebaseStudents) {
        final progressMap = s['progress'] as Map<String, dynamic>? ?? {};
        final highestStageData =
            progressMap['stage$highestUnlockedStage'] as Map<String, dynamic>?;
        String status = highestStageData?['status'] as String? ?? 'locked';
        int skor = (highestStageData?['skor'] as num?)?.toInt() ?? 0;

        if (s['id'] == progressService.currentSiswaId) {
          final localSkor =
              progressService.getStageScore(highestUnlockedStage);
          final localStatus =
              progressService.getStageStatus(highestUnlockedStage);
          if (localSkor > skor) skor = localSkor;
          if (localStatus == 'completed') status = 'completed';
        }

        if (status == 'completed' || skor > 0) {
          completedHighestCount++;
        }
      }
    }

    List<Map<String, dynamic>> notifs = [];
    final readKeys = progressService.getReadNotifications();

    for (var s in firebaseStudents) {
      final nama = s['namaLengkap'] ?? s['username'] ?? 'Siswa';
      final siswaId = s['id'] ?? nama;
      final progressMap = s['progress'] as Map<String, dynamic>? ?? {};

      for (int i = 1; i <= 6; i++) {
        final stageData = progressMap['stage$i'] as Map<String, dynamic>?;
        String status = stageData?['status'] ?? (i == 1 ? 'unlocked' : 'locked');
        int skor = (stageData?['skor'] as num?)?.toInt() ?? 0;

        if (s['id'] == progressService.currentSiswaId) {
          final localSkor = progressService.getStageScore(i);
          final localStatus = progressService.getStageStatus(i);
          if (localSkor > skor) skor = localSkor;
          if (localStatus == 'completed') status = 'completed';
        }

        if (status == 'completed' || skor > 0) {
          final notifKey = '${siswaId}_stage_$i';
          final isRead = readKeys.contains(notifKey);

          notifs.add({
            'key': notifKey,
            'nama': nama,
            'stageId': i,
            'skor': skor,
            'isRead': isRead,
          });
        }
      }
    }

    // Urutkan: Notifikasi BELUM DIBACA (isRead == false) DI ATAS, yang SUDAH DIBACA (isRead == true) DI BAWAH
    notifs.sort((a, b) {
      if (a['isRead'] == b['isRead']) {
        return 0;
      }
      return (a['isRead'] as bool) ? 1 : -1;
    });

    final hasUnread = notifs.any((n) => n['isRead'] == false);

    if (!mounted) return;
    setState(() {
      _totalStudents = firebaseStudents.length;
      _activeStudents = completedHighestCount;
      _activeStagesCount = activeStages;
      _notifications = notifs;
      _hasUnreadNotification = hasUnread;
    });
  }

  void _showNotificationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.teacherNotifPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        final dialogPadding = isTablet
            ? const EdgeInsets.fromLTRB(
                TabletLayout.teacherNotifPopupPaddingH,
                TabletLayout.teacherNotifPopupPaddingTop,
                TabletLayout.teacherNotifPopupPaddingH,
                TabletLayout.teacherNotifPopupPaddingBottom,
              )
            : ResponsiveHelper.dialogPadding(screenWidth);

        return StatefulBuilder(
          builder: (context, setNotifState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: dialogWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Template Frame Student List
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet
                            ? TabletLayout.teacherNotifPopupMaxWidth
                            : 560,
                      ),
                      child: Image.asset(
                        AppImages.frameStudentList,
                        width: dialogWidth,
                        fit: BoxFit.fitWidth,
                      ),
                    ),

                    // 2. Konten Popup dalam Positioned.fill
                    Positioned.fill(
                      child: Padding(
                        padding: dialogPadding,
                        child: Column(
                          children: [
                            // Header Judul
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppImages.icNotification,
                                  width: isTablet
                                      ? TabletLayout.teacherNotifPopupHeaderIconSize
                                      : 24,
                                  height: isTablet
                                      ? TabletLayout.teacherNotifPopupHeaderIconSize
                                      : 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pemberitahuan',
                                  style: TextStyle(
                                    fontSize: isTablet
                                        ? TabletLayout.teacherNotifPopupTitleFontSize
                                        : 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Fredoka',
                                    color: const Color(0xFF5A4FCF),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 16 : 12),

                            // Area Scroll Notifikasi
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _notifications.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Belum ada pemberitahuan',
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 13,
                                            fontFamily: 'Fredoka',
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemCount: _notifications.length,
                                        itemBuilder: (context, index) {
                                          final notif = _notifications[index];
                                          final isRead =
                                              notif['isRead'] == true;

                                          return GestureDetector(
                                            onTap: () async {
                                              if (!isRead) {
                                                await ProgressService()
                                                    .markNotificationAsRead(
                                                        notif['key']);
                                                setNotifState(() {
                                                  if (!isRead) {
                                                    notif['isRead'] = true;
                                                  }
                                                  _notifications.sort((a, b) {
                                                    if (a['isRead'] ==
                                                        b['isRead']) {
                                                      return 0;
                                                    }
                                                    return (a['isRead'] as bool)
                                                        ? 1
                                                        : -1;
                                                  });
                                                });
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              margin: EdgeInsets.only(
                                                  bottom: isTablet ? 10 : 8),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isTablet
                                                    ? TabletLayout.teacherNotifPopupItemPaddingH
                                                    : 12,
                                                vertical: isTablet
                                                    ? TabletLayout.teacherNotifPopupItemPaddingV
                                                    : 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isRead
                                                    ? const Color(0xFFF5F5F5)
                                                    : const Color(0xFFE8F5E9),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isRead
                                                      ? const Color(0xFFE0E0E0)
                                                      : const Color(0xFF81C784),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    AppImages.stageIcon(
                                                        'completed',
                                                        notif['stageId']),
                                                    width: isTablet
                                                        ? TabletLayout.teacherNotifPopupStageIconSize
                                                        : 32,
                                                    height: isTablet
                                                        ? TabletLayout.teacherNotifPopupStageIconSize
                                                        : 32,
                                                  ),
                                                  SizedBox(width: isTablet ? 14 : 10),
                                                  Expanded(
                                                    child: Text(
                                                      '${notif['nama']} telah selesai mengerjakan Stage ${notif['stageId']} dengan skor ${notif['skor']} pts.',
                                                      style: TextStyle(
                                                        fontSize: isTablet
                                                            ? TabletLayout.teacherNotifPopupItemFontSize
                                                            : 12,
                                                        fontFamily: 'Fredoka',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isRead
                                                            ? const Color(
                                                                0xFF616161)
                                                            : const Color(
                                                                0xFF1B5E20),
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      margin:
                                                          EdgeInsets.only(
                                                              left: isTablet ? 8 : 6),
                                                      width: isTablet ? 10 : 8,
                                                      height: isTablet ? 10 : 8,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF2E7D32),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Tombol Keluar ic_wrong di pojok sebelah kanan atas
                    Positioned(
                      top: isTablet ? 30 : 22,
                      right: isTablet ? 40 : 32,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Image.asset(
                          AppImages.icWrong,
                          width: isTablet
                              ? TabletLayout.teacherNotifPopupCloseBtnSize
                              : 32,
                          height: isTablet
                              ? TabletLayout.teacherNotifPopupCloseBtnSize
                              : 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Ketika dialog pemberitahuan ditutup, tandai semua notifikasi yang sempat dibuka sebagai telah dibaca
    final unreadKeys = _notifications
        .where((n) => n['isRead'] == false)
        .map((n) => n['key'] as String)
        .toList();
    if (unreadKeys.isNotEmpty) {
      await ProgressService().markAllNotificationsAsRead(unreadKeys);
      _loadData();
    }
  }

  bool _isShowingExitDialog = false;

  void _showLogoutDialog() {
    if (_isShowingExitDialog) return;
    _isShowingExitDialog = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.teacherLogoutPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: dialogWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background popup template
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet
                        ? TabletLayout.teacherLogoutPopupMaxWidth
                        : 560,
                  ),
                  child: Image.asset(
                    'assets/images/template/frame_login.png',
                    width: dialogWidth,
                    fit: BoxFit.fitWidth,
                  ),
                ),

              // Konten popup
              Padding(
                padding: isTablet
                    ? EdgeInsets.fromLTRB(
                        TabletLayout.teacherLogoutPopupPaddingH,
                        TabletLayout.teacherLogoutPopupPaddingTop,
                        TabletLayout.teacherLogoutPopupPaddingH,
                        TabletLayout.teacherLogoutPopupPaddingBottom,
                      )
                    : const EdgeInsets.fromLTRB(40, 55, 40, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teks utama
                    Text(
                      'Keluar? 🚪',
                      style: TextStyle(
                        fontSize: isTablet
                            ? TabletLayout.teacherLogoutPopupTitleFontSize
                            : 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF5A4FCF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 14 : 8),

                    // Teks penjelasan
                    Text(
                      'Yakin ingin keluar dari\ndashboard guru?',
                      style: TextStyle(
                        fontSize: isTablet
                            ? TabletLayout.teacherLogoutPopupSubtitleFontSize
                            : 14,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF7B6FD4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 24 : 18),

                    // Tombol aksi (lebih besar & responsif di tablet)
                    StatefulBuilder(
                      builder: (context, setDialogState) {
                        bool isBatalPressed = false;
                        bool isKeluarPressed = false;

                        return StatefulBuilder(
                          builder: (context, setBtnState) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Tombol Batal
                                GestureDetector(
                                  onTapDown: (_) => setBtnState(() => isBatalPressed = true),
                                  onTapUp: (_) {
                                    setBtnState(() => isBatalPressed = false);
                                    Navigator.pop(context);
                                  },
                                  onTapCancel: () => setBtnState(() => isBatalPressed = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isTablet
                                            ? TabletLayout.teacherLogoutPopupBtnPaddingH
                                            : 18,
                                        vertical: isTablet
                                            ? TabletLayout.teacherLogoutPopupBtnPaddingV
                                            : 7),
                                    decoration: BoxDecoration(
                                      color: isBatalPressed
                                          ? const Color(0xFFBDB3A6)
                                          : const Color(0xFFE1D9CF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isBatalPressed
                                            ? const Color(0xFF9E9283)
                                            : const Color(0xFFC5BCB1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      'Batal',
                                      style: TextStyle(
                                        fontSize: isTablet
                                            ? TabletLayout.teacherLogoutPopupBtnFontSize
                                            : 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        color: const Color(0xFF4A3E3D),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 18 : 12),

                                // Tombol Keluar
                                GestureDetector(
                                  onTapDown: (_) => setBtnState(() => isKeluarPressed = true),
                                  onTapUp: (_) async {
                                    setBtnState(() => isKeluarPressed = false);
                                    Navigator.pop(context);
                                    AudioService().stopBGM();
                                    await FirebaseService().logoutGuru();
                                    if (context.mounted) {
                                      context.go('/select-role');
                                    }
                                  },
                                  onTapCancel: () => setBtnState(() => isKeluarPressed = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isTablet
                                            ? TabletLayout.teacherLogoutPopupBtnPaddingH
                                            : 18,
                                        vertical: isTablet
                                            ? TabletLayout.teacherLogoutPopupBtnPaddingV
                                            : 7),
                                    decoration: BoxDecoration(
                                      color: isKeluarPressed
                                          ? const Color(0xFFD8524B)
                                          : const Color(0xFFF89E96),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isKeluarPressed
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFFE57373),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      'Keluar',
                                      style: TextStyle(
                                        fontSize: isTablet
                                            ? TabletLayout.teacherLogoutPopupBtnFontSize
                                            : 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
    ).then((_) {
      _isShowingExitDialog = false;
    });
  }

  void _showStageInfoDialog(String namaSiswa, int stageId, String status) {
    final isLocked = status == 'locked';
    final titleText = isLocked ? 'Stage Terkunci 🔒' : 'Belum Dikerjakan ⏳';
    final bodyText = isLocked
        ? 'Siswa $namaSiswa belum mencapai Stage $stageId.\n\nStage ini masih terkunci.'
        : 'Siswa $namaSiswa belum mengerjakan Stage $stageId.\n\nStage ini sudah terbuka tetapi belum ada nilai yang perlu direset.';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (infoContext) {
        final screenWidth = MediaQuery.of(infoContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.teacherResetPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        bool isPressed = false;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: dialogWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? TabletLayout.teacherResetPopupMaxWidth : 560,
                  ),
                  child: Image.asset(
                    'assets/images/template/frame_login.png',
                    width: dialogWidth,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              Padding(
                padding: isTablet
                    ? const EdgeInsets.fromLTRB(48, 60, 48, 40)
                    : const EdgeInsets.fromLTRB(40, 50, 40, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF5A4FCF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 14 : 10),
                    Text(
                      bodyText,
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 12,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF4A3E3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    StatefulBuilder(
                      builder: (context, setBtnState) {
                        return GestureDetector(
                          onTapDown: (_) =>
                              setBtnState(() => isPressed = true),
                          onTapUp: (_) {
                            setBtnState(() => isPressed = false);
                            Navigator.pop(infoContext);
                          },
                          onTapCancel: () =>
                              setBtnState(() => isPressed = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 32 : 24,
                                vertical: isTablet ? 12 : 8),
                            decoration: BoxDecoration(
                              color: isPressed
                                   ? const Color(0xFF3A309E)
                                  : const Color(0xFF5A4FCF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Mengerti',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: isTablet ? 16 : 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
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

  Future<bool?> _showKonfirmasiResetDialog(String targetText) {
    bool isBatalPressed = false;
    bool isYaPressed = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (confirmContext) {
        final screenWidth = MediaQuery.of(confirmContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.teacherResetPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: dialogWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? TabletLayout.teacherResetPopupMaxWidth : 560,
                  ),
                  child: Image.asset(
                    'assets/images/template/frame_login.png',
                    width: dialogWidth,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              Padding(
                padding: isTablet
                    ? const EdgeInsets.fromLTRB(48, 60, 48, 40)
                    : const EdgeInsets.fromLTRB(42, 50, 42, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Konfirmasi Reset ⚠️',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFFD32F2F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Text(
                      'Yakin ingin mereset progress $targetText?\nData yang direset tidak dapat dikembalikan!',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 12,
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF4A3E3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tombol Batal (berubah warna saat ditekan)
                        StatefulBuilder(
                          builder: (context, setBatalState) {
                            return GestureDetector(
                              onTapDown: (_) =>
                                  setBatalState(() => isBatalPressed = true),
                              onTapUp: (_) {
                                setBatalState(() => isBatalPressed = false);
                                Navigator.pop(confirmContext, false);
                              },
                              onTapCancel: () =>
                                  setBatalState(() => isBatalPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 28 : 20,
                                    vertical: isTablet ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: isBatalPressed
                                      ? const Color(0xFFBDBDBD)
                                      : const Color(0xFFE0E0E0),
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
                            );
                          },
                        ),

                        // Tombol Ya, Reset (berubah warna saat ditekan)
                        StatefulBuilder(
                          builder: (context, setYaState) {
                            return GestureDetector(
                              onTapDown: (_) =>
                                  setYaState(() => isYaPressed = true),
                              onTapUp: (_) {
                                setYaState(() => isYaPressed = false);
                                Navigator.pop(confirmContext, true);
                              },
                              onTapCancel: () =>
                                  setYaState(() => isYaPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 28 : 20,
                                    vertical: isTablet ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: isYaPressed
                                      ? const Color(0xFFB71C1C)
                                      : const Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    if (!isYaPressed)
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Text(
                                  'Ya, Reset',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: isTablet ? 15 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

  void _showResetDialog() async {
    final students = await FirebaseService().getAllSiswa();
    if (!mounted) return;

    String targetMode = 'all'; // 'all' atau 'specific'
    String? selectedSiswaId = students.isNotEmpty ? students.first['id'] : null;
    Map<String, dynamic> selectedStudentProgress = {};
    if (selectedSiswaId != null) {
      selectedStudentProgress =
          await FirebaseService().getProgress(selectedSiswaId);
    }

    bool isResetting = false;
    bool isSemuaPressed = false;
    bool isSpesifikPressed = false;
    bool isResetPressed = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.teacherResetPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        final dialogPadding = isTablet
            ? const EdgeInsets.fromLTRB(
                TabletLayout.teacherResetPopupPaddingH,
                TabletLayout.teacherResetPopupPaddingTop,
                TabletLayout.teacherResetPopupPaddingH,
                TabletLayout.teacherResetPopupPaddingBottom,
              )
            : ResponsiveHelper.dialogPadding(screenWidth);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: dialogWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Template Frame
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet
                            ? TabletLayout.teacherResetPopupMaxWidth
                            : 560,
                      ),
                      child: Image.asset(
                        AppImages.frameStudentList,
                        width: dialogWidth,
                        fit: BoxFit.fitWidth,
                      ),
                    ),

                    // 2. Konten Popup (Scrollable agar pas dalam frame)
                    Positioned.fill(
                      child: Padding(
                        padding: dialogPadding,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    AppImages.icReset,
                                    width: isTablet ? 30 : 24,
                                    height: isTablet ? 30 : 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reset Progress Siswa',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? TabletLayout.teacherResetPopupTitleFontSize
                                          : 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: const Color(0xFF5A4FCF),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              Text(
                                'Pilih target siswa yang akan di-reset progress belajarnya:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? TabletLayout.teacherResetPopupSubtitleFontSize
                                      : 12,
                                  fontFamily: 'Fredoka',
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: isTablet ? 16 : 12),

                              // Pilihan Mode: Semua vs Siswa Tertentu
                              Row(
                                children: [
                                  Expanded(
                                    child: StatefulBuilder(
                                      builder: (context, setSemuaPressed) {
                                        return GestureDetector(
                                          onTapDown: (_) => setSemuaPressed(
                                              () => isSemuaPressed = true),
                                          onTapUp: (_) {
                                            setSemuaPressed(
                                                () => isSemuaPressed = false);
                                            setDialogState(
                                                () => targetMode = 'all');
                                          },
                                          onTapCancel: () => setSemuaPressed(
                                              () => isSemuaPressed = false),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 100),
                                            padding: EdgeInsets.symmetric(
                                                vertical: isTablet
                                                    ? TabletLayout.teacherResetPopupModeBtnPaddingV
                                                    : 8),
                                            decoration: BoxDecoration(
                                              color: isSemuaPressed
                                                  ? (targetMode == 'all'
                                                      ? const Color(0xFF3A309E)
                                                      : const Color(0xFFE0E0E0))
                                                  : (targetMode == 'all'
                                                      ? const Color(0xFF5A4FCF)
                                                      : Colors.white),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF5A4FCF),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              'Semua Siswa',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontSize: isTablet
                                                    ? TabletLayout.teacherResetPopupModeBtnFontSize
                                                    : 12,
                                                fontWeight: FontWeight.bold,
                                                color: targetMode == 'all'
                                                    ? Colors.white
                                                    : const Color(0xFF5A4FCF),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatefulBuilder(
                                      builder: (context, setSpesifikPressed) {
                                        return GestureDetector(
                                          onTapDown: (_) => setSpesifikPressed(
                                              () => isSpesifikPressed = true),
                                          onTapUp: (_) {
                                            setSpesifikPressed(
                                                () => isSpesifikPressed = false);
                                            setDialogState(
                                                () => targetMode = 'specific');
                                          },
                                          onTapCancel: () => setSpesifikPressed(
                                              () => isSpesifikPressed = false),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 100),
                                            padding: EdgeInsets.symmetric(
                                                vertical: isTablet
                                                    ? TabletLayout.teacherResetPopupModeBtnPaddingV
                                                    : 8),
                                            decoration: BoxDecoration(
                                              color: isSpesifikPressed
                                                  ? (targetMode == 'specific'
                                                      ? const Color(0xFF3A309E)
                                                      : const Color(0xFFE0E0E0))
                                                  : (targetMode == 'specific'
                                                      ? const Color(0xFF5A4FCF)
                                                      : Colors.white),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF5A4FCF),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              'Siswa Tertentu',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontSize: isTablet
                                                    ? TabletLayout.teacherResetPopupModeBtnFontSize
                                                    : 12,
                                                fontWeight: FontWeight.bold,
                                                color: targetMode == 'specific'
                                                    ? Colors.white
                                                    : const Color(0xFF5A4FCF),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 16 : 12),

                              // Dropdown pilih nama siswa & Daftar Stage jika 'Siswa Tertentu'
                              if (targetMode == 'specific') ...[
                                if (students.isEmpty)
                                  Text(
                                    'Belum ada data siswa terdaftar',
                                    style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.red),
                                  )
                                else ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 14,
                                        vertical: isTablet ? 4 : 0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFF81C784)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedSiswaId,
                                        isExpanded: true,
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: isTablet
                                              ? TabletLayout.teacherResetPopupDropdownFontSize
                                              : 13,
                                          color: const Color(0xFF1B5E20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        items: students.map((s) {
                                          return DropdownMenuItem<String>(
                                            value: s['id'] as String,
                                            child: Text(
                                              '${s['namaLengkap']} (${s['username']})',
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) async {
                                          if (val != null) {
                                            setDialogState(
                                                () => selectedSiswaId = val);
                                            final prog = await FirebaseService()
                                                .getProgress(val);
                                            setDialogState(() =>
                                                selectedStudentProgress = prog);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 14 : 10),
                                  Text(
                                    'Klik Stage untuk reset per-stage:',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: isTablet ? 14 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5A4FCF),
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 12 : 8),

                                  // Grid 6 Stage untuk Reset Per-Stage
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: isTablet ? 12 : 8,
                                      mainAxisSpacing: isTablet ? 12 : 8,
                                      childAspectRatio: isTablet ? 0.90 : 0.78,
                                    ),
                                    itemCount: 6,
                                    itemBuilder: (context, index) {
                                      final stageId = index + 1;
                                      final stageKey = 'stage$stageId';
                                      final stageData =
                                          selectedStudentProgress[stageKey] !=
                                                  null
                                              ? Map<String, dynamic>.from(
                                                  selectedStudentProgress[
                                                      stageKey])
                                              : null;

                                      final teacherStatus =
                                          ProgressService().getStageStatus(stageId);
                                      final prevStageKey = 'stage${stageId - 1}';
                                      final prevStageData = stageId > 1 &&
                                              selectedStudentProgress[
                                                      prevStageKey] !=
                                                  null
                                          ? Map<String, dynamic>.from(
                                              selectedStudentProgress[
                                                  prevStageKey])
                                          : null;
                                      final isPrevCompleted = prevStageData != null &&
                                          prevStageData['status'] == 'completed';

                                      String status = 'locked';
                                      int score = 0;

                                      if (stageData != null) {
                                        status = stageData['status']
                                                as String? ??
                                            'locked';
                                        score = (stageData['skor'] as num?)
                                                ?.toInt() ??
                                            0;
                                      } else if (stageId == 1 ||
                                          teacherStatus == 'unlocked' ||
                                          isPrevCompleted) {
                                        status = 'unlocked';
                                      }

                                      final stageImg =
                                          AppImages.stageIcon(status, stageId);

                                      return GestureDetector(
                                        onTap: () async {
                                          if (selectedSiswaId == null) return;
                                          final targetSiswa =
                                              students.firstWhere(
                                            (s) => s['id'] == selectedSiswaId,
                                            orElse: () => {},
                                          );
                                          final namaSiswa =
                                              targetSiswa['namaLengkap'] ??
                                                  'siswa';

                                          // Jika stage terkunci atau belum dikerjakan (status bukan 'completed')
                                          if (status != 'completed') {
                                            _showStageInfoDialog(
                                                namaSiswa, stageId, status);
                                            return;
                                          }

                                          // Tampilkan Pop-up Konfirmasi reset khusus stage ini
                                          final setuju =
                                              await _showKonfirmasiResetDialog(
                                                  'Stage $stageId untuk $namaSiswa');
                                          if (setuju != true) return;

                                          setDialogState(
                                              () => isResetting = true);

                                          // Reset stage tertentu di Firebase & local
                                          await FirebaseService()
                                              .resetStageProgress(
                                                  selectedSiswaId!, stageId);

                                          if (ProgressService().currentSiswaId ==
                                              selectedSiswaId) {
                                            await ProgressService()
                                                .resetStageProgress(stageId);
                                          }

                                          // Update data progress siswa di dialog
                                          final updatedProg =
                                              await FirebaseService()
                                                  .getProgress(selectedSiswaId!);

                                          if (mounted) {
                                            setDialogState(() {
                                              selectedStudentProgress =
                                                  updatedProg;
                                              isResetting = false;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Progress Stage $stageId milik $namaSiswa berhasil direset!',
                                                  style: const TextStyle(
                                                      fontFamily: 'Fredoka'),
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            _loadData();
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: isTablet ? 6 : 4,
                                              vertical: isTablet ? 8 : 6),
                                          decoration: BoxDecoration(
                                            color: status == 'completed'
                                                ? const Color(0xFFE8F5E9)
                                                : (status == 'unlocked'
                                                    ? const Color(0xFFFFF8E1)
                                                    : const Color(0xFFF5F5F5)),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: status == 'completed'
                                                  ? const Color(0xFF81C784)
                                                  : (status == 'unlocked'
                                                      ? const Color(0xFFFFD54F)
                                                      : Colors.grey.shade300),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.04),
                                                blurRadius: 3,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                stageImg,
                                                width: isTablet
                                                    ? TabletLayout.teacherResetPopupStageIconSize
                                                    : 32,
                                                height: isTablet
                                                    ? TabletLayout.teacherResetPopupStageIconSize
                                                    : 32,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(height: isTablet ? 4 : 2),
                                              Text(
                                                'Stage $stageId',
                                                style: TextStyle(
                                                  fontFamily: 'Fredoka',
                                                  fontSize: isTablet
                                                      ? TabletLayout.teacherResetPopupStageTitleFontSize
                                                      : 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF333333),
                                                ),
                                              ),
                                              Text(
                                                status == 'completed'
                                                    ? 'Skor: $score'
                                                    : (status == 'unlocked'
                                                        ? 'Terbuka'
                                                        : 'Terkunci'),
                                                style: TextStyle(
                                                  fontFamily: 'Fredoka',
                                                  fontSize: isTablet
                                                      ? TabletLayout.teacherResetPopupStageScoreFontSize
                                                      : 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: status == 'completed'
                                                      ? Colors.green.shade800
                                                      : (status == 'unlocked'
                                                          ? Colors.orange.shade800
                                                          : Colors.grey),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                SizedBox(height: isTablet ? 16 : 12),
                              ],

                              // Tombol Eksekusi Reset Semua Stage (berubah warna saat ditekan)
                              StatefulBuilder(
                                builder: (context, setResetPressedState) {
                                  return GestureDetector(
                                    onTapDown: (_) => setResetPressedState(
                                        () => isResetPressed = true),
                                    onTapUp: (_) => setResetPressedState(
                                        () => isResetPressed = false),
                                    onTapCancel: () => setResetPressedState(
                                        () => isResetPressed = false),
                                    onTap: isResetting
                                        ? null
                                        : () async {
                                            String targetText = 'semua siswa';
                                            if (targetMode == 'specific' &&
                                                selectedSiswaId != null) {
                                              final targetSiswa =
                                                  students.firstWhere(
                                                (s) => s['id'] == selectedSiswaId,
                                                orElse: () => {},
                                              );
                                              targetText =
                                                  'semua stage siswa ${targetSiswa['namaLengkap'] ?? ''}';
                                            }

                                            // Tampilkan Pop-up Konfirmasi terlebih dahulu
                                            final setuju =
                                                await _showKonfirmasiResetDialog(
                                                    targetText);
                                            if (setuju != true) return;

                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            setDialogState(
                                                () => isResetting = true);

                                            if (targetMode == 'all') {
                                              await FirebaseService()
                                                  .resetAllProgress();
                                              await ProgressService()
                                                  .resetAllProgress();
                                            } else if (selectedSiswaId != null) {
                                              await FirebaseService()
                                                  .resetProgress(selectedSiswaId!);
                                              if (ProgressService()
                                                      .currentSiswaId ==
                                                  selectedSiswaId) {
                                                await ProgressService()
                                                    .resetAllProgress();
                                              }
                                            }

                                            if (mounted) {
                                              setDialogState(
                                                  () => isResetting = false);
                                              Navigator.pop(dialogContext);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    targetMode == 'all'
                                                        ? 'Progress semua siswa berhasil direset!'
                                                        : 'Seluruh progress siswa berhasil direset!',
                                                    style: const TextStyle(
                                                        fontFamily: 'Fredoka'),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              _loadData();
                                            }
                                          },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 100),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: isTablet
                                              ? TabletLayout.teacherResetPopupActionBtnPaddingH
                                              : 24,
                                          vertical: isTablet
                                              ? TabletLayout.teacherResetPopupActionBtnPaddingV
                                              : 10),
                                      decoration: BoxDecoration(
                                        color: isResetting
                                            ? Colors.grey
                                            : (isResetPressed
                                                ? const Color(0xFFB71C1C)
                                                : const Color(0xFFD32F2F)),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          if (!isResetting && !isResetPressed)
                                            BoxShadow(
                                              color: Colors.red.withOpacity(0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isResetting)
                                            SizedBox(
                                              width: isTablet ? 20 : 16,
                                              height: isTablet ? 20 : 16,
                                              child: const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else
                                            Image.asset(
                                              AppImages.icReset,
                                              width: isTablet
                                                  ? TabletLayout.teacherResetPopupActionIconSize
                                                  : 18,
                                              height: isTablet
                                                  ? TabletLayout.teacherResetPopupActionIconSize
                                                  : 18,
                                            ),
                                          SizedBox(width: isTablet ? 12 : 8),
                                          Text(
                                            isResetting
                                                ? 'Mereset...'
                                                : (targetMode == 'specific'
                                                    ? 'Reset Semua Stage Siswa Ini'
                                                    : 'Reset Semua Siswa'),
                                            style: TextStyle(
                                              fontSize: isTablet
                                                  ? TabletLayout.teacherResetPopupActionBtnFontSize
                                                  : 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Fredoka',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Tombol Tutup ic_wrong di pojok sebelah kanan atas
                    Positioned(
                      top: isTablet ? 30 : 22,
                      right: isTablet ? 40 : 32,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Image.asset(
                          AppImages.icWrong,
                          width: isTablet
                              ? TabletLayout.teacherResetPopupCloseBtnSize
                              : 32,
                          height: isTablet
                              ? TabletLayout.teacherResetPopupCloseBtnSize
                              : 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, String icon, Color color, {bool isTablet = false}) {
    return Expanded(
      child: Column(
        children: [
          Image.asset(
            icon,
            width: isTablet ? TabletLayout.teacherDashStatIconSize : 22,
            height: isTablet ? TabletLayout.teacherDashStatIconSize : 22,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? TabletLayout.teacherDashStatValueFontSize : 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Fredoka',
              color: color,
              shadows: const [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black45,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? TabletLayout.teacherDashStatTitleFontSize : 10,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.w500,
              shadows: const [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black45,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    bool isTablet = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? TabletLayout.teacherDashMenuPaddingH : 12,
          vertical: isTablet ? TabletLayout.teacherDashMenuPaddingV : 10,
        ),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFE8F5E9).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: isTablet ? TabletLayout.teacherDashMenuIconSize : 24,
              height: isTablet ? TabletLayout.teacherDashMenuIconSize : 24,
            ),
            SizedBox(width: isTablet ? 14 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? TabletLayout.teacherDashMenuTitleFontSize : 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: color != null ? Colors.red.shade700 : const Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isTablet ? TabletLayout.teacherDashMenuSubtitleFontSize : 11,
                      fontFamily: 'Fredoka',
                      color: const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color != null ? Colors.red.shade700 : const Color(0xFF1B5E20),
              size: isTablet ? TabletLayout.teacherDashMenuChevronSize : 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        _showLogoutDialog();
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
              // 1. HEADER GURU & STATS
              Positioned(
                top: screenHeight * (isTablet ? TabletLayout.teacherDashHeaderTopFactor : 0.20),
                left: screenWidth * (isTablet ? TabletLayout.teacherDashHeaderHFactor : 0.22),
                right: screenWidth * (isTablet ? TabletLayout.teacherDashHeaderHFactor : 0.22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row (Profil, Nama, Lonceng & Setting)
                    Row(
                      children: [
                        Image.asset(
                          AppImages.icProfileWomanDefault,
                          width: isTablet ? TabletLayout.teacherDashAvatarSize : 32,
                          height: isTablet ? TabletLayout.teacherDashAvatarSize : 32,
                        ),
                        SizedBox(width: isTablet ? 10 : 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, Bu Guru!',
                                style: TextStyle(
                                  fontSize: isTablet ? TabletLayout.teacherDashGreetingFontSize : 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Fredoka',
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
                              Text(
                                'Pantau perkembangan anak di sini',
                                style: TextStyle(
                                  fontSize: isTablet ? TabletLayout.teacherDashSubtitleFontSize : 11,
                                  fontFamily: 'Fredoka',
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasUnreadNotification = false;
                            });
                            _showNotificationDialog();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Image.asset(
                                AppImages.icNotification,
                                width: isTablet ? TabletLayout.teacherDashHeaderIconSize : 25,
                                height: isTablet ? TabletLayout.teacherDashHeaderIconSize : 25,
                              ),
                              if (_hasUnreadNotification)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: isTablet ? 12 : 9,
                                    height: isTablet ? 12 : 9,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: isTablet ? 10 : 6),
                        GestureDetector(
                          onTap: () => context.go('/teacher-settings'),
                          child: Image.asset(
                            AppImages.icSettings,
                            width: isTablet ? TabletLayout.teacherDashHeaderIconSize : 25,
                            height: isTablet ? TabletLayout.teacherDashHeaderIconSize : 25,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 16 : 12),

                    // Stats Row
                    Row(
                      children: [
                        _buildStatCard(
                          'Total Siswa',
                          '$_totalStudents',
                          AppImages.icStudentList,
                          const Color(0xFF7F77DD),
                          isTablet: isTablet,
                        ),
                        SizedBox(width: isTablet ? TabletLayout.teacherDashStatSpacing : 6),
                        _buildStatCard(
                          'Sudah Belajar',
                          '$_activeStudents',
                          AppImages.icMyProgress,
                          const Color(0xFF4FC3F7),
                          isTablet: isTablet,
                        ),
                        SizedBox(width: isTablet ? TabletLayout.teacherDashStatSpacing : 6),
                        _buildStatCard(
                          'Stage Aktif',
                          '$_activeStagesCount',
                          AppImages.icLevel,
                          const Color(0xFF81C784),
                          isTablet: isTablet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. AREA SCROLLABLE: DARI "BUKA LEVEL" SAMPAI "KELUAR"
              Positioned(
                top: screenHeight * (isTablet ? TabletLayout.teacherDashMenuTopFactor : 0.42),
                bottom: screenHeight * (isTablet ? TabletLayout.teacherDashMenuBottomFactor : 0.28),
                left: screenWidth * (isTablet ? TabletLayout.teacherDashMenuHFactor : 0.20),
                right: screenWidth * (isTablet ? TabletLayout.teacherDashMenuHFactor : 0.20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Menu List Guru
                        _buildMenuTile(
                          icon: AppImages.icUnlockLevel,
                          title: 'Buka Stage',
                          subtitle: 'Buka stage baru untuk anak',
                          isTablet: isTablet,
                          onTap: () async {
                            await context.push('/unlock-level');
                            _loadData();
                          },
                        ),
                        SizedBox(height: isTablet ? TabletLayout.teacherDashMenuItemSpacing : 8),
                        _buildMenuTile(
                          icon: AppImages.icProgressReport,
                          title: 'Lihat Progress Anak',
                          subtitle: 'Pantau hasil belajar setiap anak',
                          isTablet: isTablet,
                          onTap: () async {
                            await context.push('/progress-report');
                            _loadData();
                          },
                        ),
                        SizedBox(height: isTablet ? TabletLayout.teacherDashMenuItemSpacing : 8),
                        _buildMenuTile(
                          icon: AppImages.icStudentList,
                          title: 'Daftar Siswa',
                          subtitle: 'Lihat data siswa yang terdaftar',
                          isTablet: isTablet,
                          onTap: () async {
                            await context.push('/student-list');
                            _loadData();
                          },
                        ),
                        SizedBox(height: isTablet ? TabletLayout.teacherDashMenuItemSpacing : 8),
                        _buildMenuTile(
                          icon: AppImages.icReset,
                          title: 'Reset Progress',
                          subtitle: 'Ulangi progress semua siswa',
                          color: const Color(0xFFFFEBEE).withOpacity(0.9),
                          isTablet: isTablet,
                          onTap: () => _showResetDialog(),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),

                        // Tombol Logout (Keluar dengan efek tekan)
                        StatefulBuilder(
                          builder: (context, setBtnState) {
                            return GestureDetector(
                              onTapDown: (_) => setBtnState(() => _isLogoutPressed = true),
                              onTapUp: (_) => setBtnState(() => _isLogoutPressed = false),
                              onTapCancel: () => setBtnState(() => _isLogoutPressed = false),
                              onTap: () => _showLogoutDialog(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet
                                      ? TabletLayout.teacherDashLogoutPaddingV
                                      : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLogoutPressed
                                      ? const Color(0xFFC63E34)
                                      : const Color(0xFFF89E96),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _isLogoutPressed
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFFC63E34)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      AppImages.icLogout,
                                      width: isTablet
                                          ? TabletLayout.teacherDashLogoutIconSize
                                          : 22,
                                      height: isTablet
                                          ? TabletLayout.teacherDashLogoutIconSize
                                          : 22,
                                    ),
                                    SizedBox(width: isTablet ? 10 : 8),
                                    Text(
                                      'Keluar',
                                      style: TextStyle(
                                        fontSize: isTablet
                                            ? TabletLayout.teacherDashLogoutFontSize
                                            : 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
