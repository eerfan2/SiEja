import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/services/stage_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class StageMapScreen extends StatefulWidget {
  const StageMapScreen({super.key});

  @override
  State<StageMapScreen> createState() => _StageMapScreenState();
}

class _StageMapScreenState extends State<StageMapScreen> {
  List<Map<String, dynamic>> _stages = [];
  List<String> _statusList = [];
  List<int> _skorList = [];
  bool _isLoading = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Bersihkan cache gambar agar aset gambar baru langsung di-reload dari disk
    PaintingBinding.instance.imageCache.clear();
    const AssetImage(AppImages.stageLockedBlank).evict();
    const AssetImage(AppImages.stageUnlockedBlank).evict();
    const AssetImage(AppImages.stageCompletedBlank).evict();

    // Default awal 6 stage sebelum data async siap
    _stages = StageService.defaultStages
        .map((s) => {
              'id': s.number,
              'nama': s.nama,
              'huruf': s.huruf,
              'lokasi': s.lokasi,
            })
        .toList();

    _loadStageData();
    _initBGM();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStageData() async {
    // 1. Ambil daftar stage dinamis dari StageService (default + Firestore)
    final stageModels = await StageService().getStages();
    final dynamicStages = stageModels
        .map((s) => {
              'id': s.number,
              'nama': s.nama,
              'huruf': s.huruf,
              'lokasi': s.lokasi,
              'isOpenByTeacher': s.isOpenByTeacher,
            })
        .toList();

    // 2. Tampilkan data lokal terlebih dahulu agar UI cepat responsif
    final List<String> statusList = [];
    final List<int> skorList = [];
    for (final stg in dynamicStages) {
      final int stageId = stg['id'] as int;
      statusList.add(ProgressService().getStageStatus(stageId));
      skorList.add(ProgressService().getStageScore(stageId));
    }

    if (mounted) {
      setState(() {
        _stages = dynamicStages;
        _statusList = statusList;
        _skorList = skorList;
        _isLoading = false;
      });
    }

    // 3. Sinkronisasi dengan Firebase jika siswa sedang login
    final siswaId = ProgressService().currentSiswaId;
    if (siswaId.isNotEmpty) {
      try {
        final progress = await FirebaseService().getProgress(siswaId);
        await ProgressService().loadStudentProgressFromFirebase({'progress': progress});

        // Perbarui UI jika ada sinkronisasi status terbaru dari guru
        final List<String> updatedStatus = [];
        final List<int> updatedSkor = [];
        for (final stg in dynamicStages) {
          final int stageId = stg['id'] as int;
          updatedStatus.add(ProgressService().getStageStatus(stageId));
          updatedSkor.add(ProgressService().getStageScore(stageId));
        }

        if (mounted) {
          setState(() {
            _statusList = updatedStatus;
            _skorList = updatedSkor;
          });
        }
      } catch (e) {
        // Fallback offline aman
      }
    }
  }

  Future<void> _initBGM() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      AudioService().playBGM(AppAudio.bgmStage);
    }
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Image.asset(
                      'assets/images/template/frame_login.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
    BuildContext context,
    int prevStageId,
    int targetStageId,
  ) {
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

  void _showCompletedPopup(BuildContext context, int stageId) {
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
                    padding: const EdgeInsets.fromLTRB(40, 50, 40, 35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        Text(
                          'Kamu sudah berhasil menyelesaikan stage ini!\nSilakan lanjutkan ke stage berikutnya.',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 14,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF7B6FD4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: AssetButton(
                            normalAsset: AppImages.btnContinueNormal,
                            pressedAsset: AppImages.btnContinuePressed,
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            width: isTablet ? 170 : 130,
                            height: isTablet ? 64 : 48,
                          ),
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
    final stageId = stage['id'] as int;

    return GestureDetector(
      onTap: () async {
        // 1. Sinkronisasi status stage secara defensif dari Firebase jika online
        final siswaId = ProgressService().currentSiswaId;
        if (siswaId.isNotEmpty) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );

          try {
            final progress = await FirebaseService().getProgress(siswaId);
            if (context.mounted) Navigator.pop(context);

            final stageData = progress['stage$stageId'];
            if (stageData != null && stageData['status'] == 'locked') {
              await ProgressService().lockStageByTeacher(stageId);
            }
          } catch (_) {
            if (context.mounted) Navigator.pop(context);
          }
        }

        // 2. Evaluasi Aturan Akses Fase 3
        final accessResult = ProgressService().checkStageAccess(stageId);

        if (accessResult == StageAccessResult.lockedByTeacher) {
          _showLockedPopup(context);
          return;
        }

        if (accessResult == StageAccessResult.prevStageIncomplete) {
          _showMustCompletePreviousPopup(context, stageId - 1, stageId);
          return;
        }

        // 3. Stage dapat dimainkan
        if (status == 'completed') {
          _showCompletedPopup(context, stageId);
        } else {
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
          // Medallion Stage: Aset gambar khusus 3D asli untuk seluruh stage
          _buildStageMedallion(
            stageId: stageId,
            status: status,
            isTablet: isTablet,
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


  /// Membangun medallion 3D menggunakan aset gambar asli SiEja (locked, unlocked, completed)
  /// Untuk stage 1–6: menggunakan aset bergambar angka asli SiEja
  /// Untuk stage 7+: menggunakan template medallion blank SiEja dengan teks angka yang berpenampilan seragam (putih + outline)
  Widget _buildStageMedallion({
    required int stageId,
    required String status,
    required bool isTablet,
  }) {
    final double size = isTablet ? 110.0 : 75.0;

    if (stageId <= 6) {
      return Image.asset(
        AppImages.stageIcon(status, stageId),
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    // Untuk stage 7 dan seterusnya: gunakan medallion blank SiEja dengan angka dinamis
    final String blankAsset;
    final double verticalShift;
    final Widget numberWidget;

    if (status == 'completed') {
      blankAsset = AppImages.stageCompletedBlank;
      verticalShift = size * 0.05;
      numberWidget = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$stageId',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w900,
              fontSize: isTablet ? 36 : 24,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = isTablet ? 3.5 : 2.5
                ..color = const Color(0xFF6B1B0A),
            ),
          ),
          Text(
            '$stageId',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w900,
              fontSize: isTablet ? 36 : 24,
              color: const Color(0xFFFFE082),
            ),
          ),
        ],
      );
    } else if (status == 'unlocked') {
      blankAsset = AppImages.stageUnlockedBlank;
      // Posisi optik piringan krem di atas buku terbuka A-Z (-7.5% dari tinggi medallion)
      // Diselaraskan presisi dengan letak angka stage 4, 5, 6 default
      verticalShift = -size * 0.075;

      final bool isTwoDigit = stageId >= 10;
      final double fontSize = isTablet
          ? (isTwoDigit ? 46.0 : 54.0)
          : (isTwoDigit ? 32.0 : 38.0);
      final double strokeWidth = isTablet ? 5.2 : 3.8;
      final double bevelOffset = isTablet ? 3.0 : 2.0;

      numberWidget = Stack(
        alignment: Alignment.center,
        children: [
          // 1. Lapisan bayangan bevel 3D tebal ke arah bawah (meniru efek 3D timbul stage 4, 5, 6 asli)
          Transform.translate(
            offset: Offset(0, bevelOffset),
            child: Text(
              '$stageId',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round
                  ..color = const Color(0xFF5D2002),
              ),
            ),
          ),
          // 2. Outline cokelat gelap sekeliling angka dengan sambungan membulat
          Text(
            '$stageId',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFF7A2E05),
            ),
          ),
          // 3. Isian gradien keemasan 3D (krem cerah di atas -> kuning emas cerah -> oranye hangat di bawah)
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF9C4), // Krem kuning terang di atas
                Color(0xFFFFD54F), // Emas di tengah
                Color(0xFFFF9800), // Oranye keemasan hangat di bawah
              ],
              stops: [0.0, 0.45, 1.0],
            ).createShader(bounds),
            child: Text(
              '$stageId',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      // Locked: Desain persis seperti nomor stage 4, 5, 6 (Isian putih dengan outline gelap)
      blankAsset = AppImages.stageLockedBlank;
      verticalShift = size * 0.09; // Tepat di tengah piringan putih (berdasarkan ukuran aset 760x973)
      numberWidget = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$stageId',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w900,
              fontSize: isTablet ? 36 : 24,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = isTablet ? 3.8 : 2.8
                ..color = const Color(0xFF2E2E2E),
            ),
          ),
          Text(
            '$stageId',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w900,
              fontSize: isTablet ? 36 : 24,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            blankAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          Transform.translate(
            offset: Offset(0, verticalShift),
            child: numberWidget,
          ),
        ],
      ),
    );
  }

  // 6 Slot posisi asli pada ilustrasi bg_stage_map.png
  static const List<Offset> _slotFactors = [
    Offset(0.41, 0.02), // Stage 1 (Slot 0): Bawah tengah
    Offset(0.46, 0.21), // Stage 2 (Slot 1): Jembatan
    Offset(0.46, 0.37), // Stage 3 (Slot 2): Desa Alfabet
    Offset(0.36, 0.53), // Stage 4 (Slot 3): Rumah A
    Offset(0.57, 0.61), // Stage 5 (Slot 4): Pelangi Mengeja
    Offset(0.64, 0.74), // Stage 6 (Slot 5): Istana Literasi
  ];

  /// Menghitung koordinat horizontal (factorX) dan vertikal (factorY)
  /// serta opasitas untuk stage pada posisi virtual slot `s`.
  ({double factorX, double factorY, double opacity}) _getPathPosition(double s) {
    if (s < 0.0) {
      // Stage bergulir ke bawah keluar dari layar (di bawah Slot 0)
      final double diff = -s;
      final double factorX = _slotFactors[0].dx + s * 0.04;
      final double factorY = _slotFactors[0].dy + s * 0.20;
      final double opacity = (1.0 - diff).clamp(0.0, 1.0);
      return (factorX: factorX, factorY: factorY, opacity: opacity);
    } else if (s > 5.0) {
      // Stage baru berada di luar area layar di atas sebelum digulir
      final double diff = s - 5.0;
      final double factorX = _slotFactors[5].dx + diff * 0.06;
      final double factorY = _slotFactors[5].dy + diff * 0.22;
      final double opacity = (1.0 - diff).clamp(0.0, 1.0);
      return (factorX: factorX, factorY: factorY, opacity: opacity);
    } else {
      // Stage berada di dalam 6 slot ilustrasi jalur
      final int k = s.floor();
      final double frac = s - k;
      if (k >= 5 || frac == 0.0) {
        return (
          factorX: _slotFactors[k.clamp(0, 5)].dx,
          factorY: _slotFactors[k.clamp(0, 5)].dy,
          opacity: 1.0,
        );
      }
      // Smoothstep interpolation di antara dua slot
      final double f = frac * frac * (3.0 - 2.0 * frac);
      final double factorX = _slotFactors[k].dx + (_slotFactors[k + 1].dx - _slotFactors[k].dx) * f;
      final double factorY = _slotFactors[k].dy + (_slotFactors[k + 1].dy - _slotFactors[k].dy) * f;
      return (factorX: factorX, factorY: factorY, opacity: 1.0);
    }
  }

  /// Menempatkan node stage secara dinamis pada jalur ilustrasi
  Widget _buildDynamicStageNode({
    required int index,
    required double t,
    required double scrollOffset,
    required double screenWidth,
    required double screenHeight,
    required double nodeWidth,
    required double nodeHeight,
    required bool isTablet,
  }) {
    final double s = index - t;
    final pos = _getPathPosition(s);

    if (pos.opacity <= 0.0) {
      return const SizedBox.shrink();
    }

    // Koordinat layar relatif terhadap viewport
    final double screenBottom = screenHeight * pos.factorY;
    final double screenTop = screenHeight - screenBottom - nodeHeight;
    final double screenLeft = screenWidth * pos.factorX;

    // Flutter SingleChildScrollView menggeser anak secara vertikal sebesar -scrollOffset.
    // Agar posisinya tepat berada di screenTop saat digulir:
    final double localTop = screenTop + scrollOffset;

    final stage = _stages[index];
    final status = index < _statusList.length ? _statusList[index] : 'locked';
    final skor = index < _skorList.length ? _skorList[index] : 0;

    return Positioned(
      top: localTop,
      left: screenLeft,
      width: nodeWidth,
      child: IgnorePointer(
        ignoring: pos.opacity < 0.3,
        child: Opacity(
          opacity: pos.opacity,
          child: _buildStageNode(stage, status, skor, isTablet),
        ),
      ),
    );
  }

  /// Tombol navigasi scroll ke stage baru (Stage 7+) atau kembali ke stage 1
  /// Menggunakan aset "btn_lanjut" untuk scroll ke atas (Stage 7+) dan "btn_kembalibulat" untuk scroll ke bawah (Stage 1).
  /// Diposisikan di sisi kanan tengah layar (vertically centered).
  /// Tombol ini HANYA muncul jika terdapat stage ekstra (extraStages > 0).
  /// Jika stage ekstra dihapus, tombol ini otomatis tidak muncul sama sekali.
  Widget _buildScrollNavButton({
    required int extraStages,
    required double scrollOffset,
    required double maxScroll,
    required bool isTablet,
    required double screenHeight,
  }) {
    if (extraStages <= 0) return const SizedBox.shrink();

    // Jika berada di paruh bawah -> btn_lanjut (untuk scroll ke stage 7 dan seterusnya)
    // Jika berada di paruh atas -> btn_kembalibulat (untuk scroll kembali ke stage 1)
    final bool isNearBottom = scrollOffset < (maxScroll * 0.5);

    final String normalAsset = isNearBottom
        ? AppImages.btnLanjutNormal
        : AppImages.btnKembaliBulatNormal;
    final String pressedAsset = isNearBottom
        ? AppImages.btnLanjutPressed
        : AppImages.btnKembaliBulatPressed;

    final VoidCallback onTap = () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          isNearBottom ? maxScroll : 0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    };

    final double btnWidth = isTablet ? 76.0 : 56.0;
    final double btnHeight = isTablet ? 78.0 : 58.0;

    // Posisi di sisi kanan tengah layar, dinaikkan sedikit ke atas
    final double topPosition = ((screenHeight - btnHeight) / 2) - (isTablet ? 60.0 : 40.0);

    return Positioned(
      top: topPosition,
      right: 16,
      child: AssetButton(
        normalAsset: normalAsset,
        pressedAsset: pressedAsset,
        onTap: onTap,
        width: btnWidth,
        height: btnHeight,
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
      child: _isLoading
          ? const BgScaffold(
              backgroundAsset: AppImages.bgStageMap,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : BgScaffold(
              backgroundAsset: AppImages.bgStageMap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;
                  final isTablet = ResponsiveHelper.isTablet(screenWidth);

                  final double nodeWidth = isTablet ? 110.0 : 75.0;
                  final double nodeHeight = isTablet ? 136.0 : 95.0;
                  final double stepScroll = isTablet ? 180.0 : 140.0;
                  final int stageCount = _stages.length;
                  final int extraStages = math.max(0, stageCount - 6);
                  final double maxScroll = extraStages * stepScroll;

                  return Stack(
                    children: [
                      // 1. AREA SCROLL TAHAP PERMAINAN
                      Positioned.fill(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              if (extraStages > 0 && _scrollController.hasClients) {
                                final currentOffset = _scrollController.offset;
                                final targetIndex = (currentOffset / stepScroll)
                                    .round()
                                    .clamp(0, extraStages);
                                final targetOffset = targetIndex * stepScroll;
                                if ((currentOffset - targetOffset).abs() > 4.0 &&
                                    (currentOffset - targetOffset).abs() < stepScroll * 0.9) {
                                  Future.microtask(() {
                                    if (_scrollController.hasClients) {
                                      _scrollController.animateTo(
                                        targetOffset,
                                        duration: const Duration(milliseconds: 260),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  });
                                }
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            key: const PageStorageKey('stage_map_scroll'),
                            controller: _scrollController,
                            physics: extraStages > 0
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: Container(
                              width: screenWidth,
                              height: screenHeight + maxScroll,
                              color: Colors.transparent, // Mendeteksi drag/geser di seluruh layar
                              child: AnimatedBuilder(
                                animation: _scrollController,
                                builder: (context, _) {
                                  final double scrollOffset = _scrollController.hasClients
                                      ? _scrollController.offset
                                      : 0.0;
                                  final double rawT = extraStages > 0
                                      ? (scrollOffset / stepScroll)
                                      : 0.0;
                                  final double t = rawT.clamp(-0.35, extraStages + 0.35);

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      for (int i = 0; i < stageCount; i++)
                                        _buildDynamicStageNode(
                                          index: i,
                                          t: t,
                                          scrollOffset: scrollOffset,
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          nodeWidth: nodeWidth,
                                          nodeHeight: nodeHeight,
                                          isTablet: isTablet,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. TOMBOL BACK (Fixed di pojok kiri atas, tidak tergulir)
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

                      // 3. TOMBOL NAVIGASI SCROLL PANAH (Hanya muncul jika ada stage ekstra > 6)
                      AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, _) {
                          final double scrollOffset = _scrollController.hasClients
                              ? _scrollController.offset
                              : 0.0;
                          return _buildScrollNavButton(
                            extraStages: extraStages,
                            scrollOffset: scrollOffset,
                            maxScroll: maxScroll,
                            isTablet: isTablet,
                            screenHeight: screenHeight,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
