import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/services/stage_service.dart';
import 'package:si_eja/widgets/generic_stage_badge.dart';

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  late final TextEditingController _searchController;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AudioService().playBGM(AppAudio.bgmHome);
    _searchController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final firebaseStudents = await FirebaseService().getAllSiswa();
    final stageModels = await StageService().getStages();
    final progressService = ProgressService();
    final currentSiswaId = progressService.currentSiswaId;

    List<Map<String, dynamic>> studentList = [];

    for (var s in firebaseStudents) {
      final nama = s['namaLengkap'] ?? s['username'] ?? 'Siswa';
      final progressMap = s['progress'] as Map<String, dynamic>? ?? {};

      List<Map<String, dynamic>> stageList = [];
      int totalSkor = 0;
      int stageAktif = 1;

      for (final model in stageModels) {
        final i = model.number;
        final stageData = progressMap['stage$i'] as Map<String, dynamic>?;

        String status = stageData?['status'] ?? (i == 1 ? 'unlocked' : 'locked');
        int skor = (stageData?['skor'] as num?)?.toInt() ?? 0;

        // Sync/fallback dengan data lokal jika siswa yang sedang login di HP ini sesuai
        if (s['id'] == currentSiswaId) {
          final localSkor = progressService.getStageScore(i);
          final localStatus = progressService.getStageStatus(i);
          if (localSkor > skor) skor = localSkor;
          if (localStatus == 'completed') {
            status = 'completed';
          } else if (localStatus == 'unlocked' && status == 'locked') {
            status = 'unlocked';
          }
        }

        totalSkor += skor;
        if (status != 'locked') stageAktif = i;

        stageList.add({
          'id': i,
          'status': status,
          'skor': skor,
        });
      }

      // Stage yang perlu remedial: sudah completed tapi skor < 50
      final stuckStageIds = stageList
          .where((s) => s['status'] == 'completed' && (s['skor'] as int) < 50)
          .map((s) => s['id'] as int)
          .toList();

      studentList.add({
        'nama': nama,
        'stageAktif': stageAktif,
        'totalSkor': totalSkor,
        'stages': stageList,
        'isStuck': stuckStageIds.isNotEmpty,
        'stuckStageIds': stuckStageIds,
      });
    }

    if (!mounted) return;
    setState(() {
      _students = studentList;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchController.text.isEmpty) return _students;
    return _students
        .where((s) => s['nama']
            .toString()
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  void _showDetailProgressDialog(Map<String, dynamic> student) {
    final stages = student['stages'] as List<Map<String, dynamic>>;
    final isStuck = student['isStuck'] as bool;
    final stuckStageIds = (student['stuckStageIds'] as List<dynamic>).cast<int>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.progressPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        final dialogPadding = isTablet
            ? const EdgeInsets.fromLTRB(
                TabletLayout.progressPopupPaddingH,
                TabletLayout.progressPopupPaddingTop,
                TabletLayout.progressPopupPaddingH,
                TabletLayout.progressPopupPaddingBottom,
              )
            : ResponsiveHelper.dialogPadding(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SizedBox(
            width: dialogWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Template Frame Student List
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet
                        ? TabletLayout.progressPopupMaxWidth
                        : 560,
                  ),
                  child: Image.asset(
                    AppImages.frameStudentList,
                    width: dialogWidth,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                // Konten di dalam Frame (dibatasi oleh Positioned.fill agar tidak keluar dari frame)
                Positioned.fill(
                  child: Padding(
                    padding: dialogPadding,
                    child: Column(
                      children: [
                        // Teks Judul Nama Siswa
                        Text(
                          student['nama'],
                          style: TextStyle(
                            fontSize: isTablet
                                ? TabletLayout.progressPopupTitleFontSize
                                : 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: isStuck ? Colors.red : const Color(0xFF5A4FCF),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isStuck
                              ? '⚠️ Stage ${stuckStageIds.join(', ')} perlu remedial • Total Skor: ${student['totalSkor']} pts'
                              : 'Stage Aktif: ${student['stageAktif']} • Total Skor: ${student['totalSkor']} pts',
                          style: TextStyle(
                            fontSize: isTablet
                                ? TabletLayout.progressPopupSubtitleFontSize
                                : 11,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w600,
                            color: isStuck ? Colors.red : const Color(0xFF7B6FD4),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isTablet ? 14 : 10),

                        // List Detail Stage (1 s/d 6) - Area Scrollable dengan Rounded Corners
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: stages.map((stage) {
                                  final status = stage['status'];
                                  final skor = stage['skor'] as int;
                                  final isLocked = status == 'locked';
                                  final isStageStuck = stuckStageIds.contains(stage['id'] as int);

                                  return Container(
                                    margin: EdgeInsets.only(
                                      bottom: isTablet
                                          ? TabletLayout.progressPopupStageMarginBottom
                                          : 8,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet
                                          ? TabletLayout.progressPopupStagePaddingH
                                          : 12,
                                      vertical: isTablet
                                          ? TabletLayout.progressPopupStagePaddingV
                                          : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isStageStuck
                                          ? const Color(0xFFFFEBEE)
                                          : isLocked
                                              ? Colors.grey.withOpacity(0.15)
                                              : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isStageStuck
                                            ? Colors.red.withOpacity(0.5)
                                            : isLocked
                                                ? Colors.grey.withOpacity(0.3)
                                                : const Color(0xFF81C784),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AppImages.hasStageIcon(stage['id'] as int)
                                            ? Image.asset(
                                                AppImages.stageIcon(
                                                    status, stage['id'] as int),
                                                width: isTablet
                                                    ? TabletLayout.progressPopupStageIconSize
                                                    : 32,
                                                height: isTablet
                                                    ? TabletLayout.progressPopupStageIconSize
                                                    : 32,
                                              )
                                            : GenericStageBadge(
                                                stageNumber: stage['id'] as int,
                                                status: status,
                                                isTablet: isTablet,
                                                size: isTablet
                                                    ? TabletLayout.progressPopupStageIconSize
                                                    : 32,
                                              ),
                                        SizedBox(width: isTablet ? 14 : 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Stage ${stage['id']}',
                                                    style: TextStyle(
                                                      fontSize: isTablet
                                                          ? TabletLayout.progressPopupStageTitleFontSize
                                                          : 13,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Fredoka',
                                                      color: isStageStuck
                                                          ? Colors.red
                                                          : isLocked
                                                              ? Colors.grey
                                                              : const Color(0xFF1B5E20),
                                                    ),
                                                  ),
                                                  if (isStageStuck) ...[
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '⚠️ Perlu Remedial',
                                                      style: TextStyle(
                                                        fontSize: isTablet
                                                            ? TabletLayout.progressPopupStageRemedialFontSize
                                                            : 10,
                                                        fontFamily: 'Fredoka',
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (!isLocked) ...[
                                                SizedBox(height: isTablet ? 5 : 3),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: skor / 100,
                                                    backgroundColor:
                                                        Colors.grey.withOpacity(0.2),
                                                    valueColor: AlwaysStoppedAnimation(
                                                      skor >= 90
                                                          ? Colors.green
                                                          : skor >= 70
                                                              ? const Color(0xFF5A4FCF)
                                                              : skor >= 50
                                                                  ? Colors.orange
                                                                  : Colors.red,
                                                    ),
                                                    minHeight: isTablet
                                                        ? TabletLayout.progressPopupProgressHeight
                                                        : 6,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 14 : 10),
                                        Text(
                                          isLocked ? '🔒' : '$skor pts',
                                          style: TextStyle(
                                            fontSize: isTablet
                                                ? TabletLayout.progressPopupStageScoreFontSize
                                                : 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Fredoka',
                                            color: isStageStuck
                                                ? Colors.red
                                                : isLocked
                                                    ? Colors.grey
                                                    : const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 14 : 10),

                        // Tombol Tutup dengan efek tekan
                        Container(
                          margin: EdgeInsets.only(
                            bottom: isTablet
                                ? TabletLayout.progressPopupCloseBtnBottomMargin
                                : 0,
                          ),
                          child: StatefulBuilder(
                            builder: (context, setOuterState) {
                              bool isPressed = false;
                              return StatefulBuilder(
                                builder: (context, setBtnState) {
                                  return GestureDetector(
                                    onTapDown: (_) => setBtnState(() => isPressed = true),
                                    onTapUp: (_) {
                                      setBtnState(() => isPressed = false);
                                      Navigator.pop(context);
                                    },
                                    onTapCancel: () => setBtnState(() => isPressed = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 80),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet
                                            ? TabletLayout.progressPopupCloseBtnPaddingH
                                            : 32,
                                        vertical: isTablet
                                            ? TabletLayout.progressPopupCloseBtnPaddingV
                                            : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPressed
                                            ? const Color(0xFF3A309E)
                                            : const Color(0xFF5A4FCF),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF5A4FCF)
                                                .withOpacity(isPressed ? 0.2 : 0.4),
                                            blurRadius: isPressed ? 3 : 6,
                                            offset: Offset(0, isPressed ? 1 : 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Tutup',
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? TabletLayout.progressPopupCloseBtnFontSize
                                              : 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Fredoka',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Silang (X) di Pojok Kanan Atas Pop-up
                Positioned(
                  top: isTablet
                      ? TabletLayout.progressPopupCloseIconTop
                      : 22,
                  right: isTablet
                      ? TabletLayout.progressPopupCloseIconRight
                      : 32,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      AppImages.icWrong,
                      width: isTablet
                          ? TabletLayout.progressPopupCloseIconSize
                          : 32,
                      height: isTablet
                          ? TabletLayout.progressPopupCloseIconSize
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
      resizeToAvoidBottomInset: false,
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
                      ? TabletLayout.progressBackBtnWidth
                      : 80,
                  height: isTablet
                      ? TabletLayout.progressBackBtnHeight
                      : 44,
                ),
              ),

              // 2. JUDUL HALAMAN
              Positioned(
                top: screenHeight *
                    (isTablet
                        ? TabletLayout.progressTitleTopFactor
                        : 0.20),
                left: screenWidth *
                    (isTablet
                        ? TabletLayout.progressTitleHFactor
                        : 0.23),
                right: screenWidth *
                    (isTablet
                        ? TabletLayout.progressTitleHFactor
                        : 0.23),
                child: Center(
                  child: Text(
                    'Progress Siswa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet
                          ? TabletLayout.progressTitleFontSize
                          : 20,
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
              ),

              // 3. SEARCH BAR
              Positioned(
                top: screenHeight *
                    (isTablet
                        ? TabletLayout.progressSearchTopFactor
                        : 0.26),
                left: screenWidth *
                    (isTablet
                        ? TabletLayout.progressSearchHFactor
                        : 0.23),
                right: screenWidth *
                    (isTablet
                        ? TabletLayout.progressSearchHFactor
                        : 0.23),
                child: Container(
                  height: isTablet
                      ? TabletLayout.progressSearchHeight
                      : 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(
                      isTablet
                          ? TabletLayout.progressSearchHeight / 2
                          : 21,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari nama siswa...',
                      hintStyle: TextStyle(
                        fontFamily: 'Fredoka',
                        color: const Color(0xFF616161),
                        fontSize: isTablet
                            ? TabletLayout.progressSearchFontSize
                            : 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFF1B5E20),
                        size: isTablet
                            ? TabletLayout.progressSearchIconSize
                            : 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: isTablet ? 22 : 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: isTablet
                          ? TabletLayout.progressSearchFontSize
                          : 13,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ),

              // 4. LIST PROGRESS SISWA (Scroll Area pas di Papan Background)
              Positioned(
                top: screenHeight *
                    (isTablet
                        ? TabletLayout.progressListTopFactor
                        : 0.34),
                bottom: screenHeight *
                    (isTablet
                        ? TabletLayout.progressListBottomFactor
                        : 0.31),
                left: screenWidth *
                    (isTablet
                        ? TabletLayout.progressListHFactor
                        : 0.21),
                right: screenWidth *
                    (isTablet
                        ? TabletLayout.progressListHFactor
                        : 0.21),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF5A4FCF)),
                        )
                      : _filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    AppImages.icProgressReport,
                                    width: isTablet ? 80 : 60,
                                    height: isTablet ? 80 : 60,
                                    color: Colors.white.withOpacity(0.6),
                                    colorBlendMode: BlendMode.modulate,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada data progress siswa',
                                    style: TextStyle(
                                      fontSize: isTablet ? 17 : 14,
                                      fontFamily: 'Fredoka',
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 6),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                final isStuck = student['isStuck'] as bool;

                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: isTablet
                                        ? TabletLayout.progressCardMarginBottom
                                        : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStuck
                                        ? const Color(0xFFFFEBEE).withOpacity(0.95)
                                        : const Color(0xFFE8F5E9).withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isStuck
                                          ? Colors.red.withOpacity(0.4)
                                          : const Color(0xFF1B5E20).withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () =>
                                          _showDetailProgressDialog(student),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet
                                              ? TabletLayout.progressCardPaddingH
                                              : 16,
                                          vertical: isTablet
                                              ? TabletLayout.progressCardPaddingV
                                              : 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student['nama'],
                                                    style: TextStyle(
                                                      fontSize: isTablet
                                                          ? TabletLayout.progressCardNameFontSize
                                                          : 15,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Fredoka',
                                                      color: isStuck
                                                          ? Colors.red
                                                          : const Color(0xFF1B5E20),
                                                    ),
                                                  ),
                                                  SizedBox(height: isTablet ? 5 : 3),
                                                  Text(
                                                    isStuck
                                                        ? '⚠️ Stage ${(student['stuckStageIds'] as List<dynamic>).join(', ')} perlu remedial'
                                                        : 'Stage Aktif: ${student['stageAktif']} • Total Skor: ${student['totalSkor']} pts',
                                                    style: TextStyle(
                                                      fontSize: isTablet
                                                          ? TabletLayout.progressCardInfoFontSize
                                                          : 11,
                                                      fontFamily: 'Fredoka',
                                                      color: isStuck
                                                          ? Colors.red
                                                          : const Color(0xFF616161),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isTablet
                                                    ? TabletLayout.progressCardDetailPaddingH
                                                    : 10,
                                                vertical: isTablet
                                                    ? TabletLayout.progressCardDetailPaddingV
                                                    : 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isStuck
                                                    ? Colors.red.withOpacity(0.1)
                                                    : const Color(0xFF1B5E20)
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Detail',
                                                    style: TextStyle(
                                                      fontSize: isTablet
                                                          ? TabletLayout.progressCardDetailFontSize
                                                          : 11,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Fredoka',
                                                      color: isStuck
                                                          ? Colors.red
                                                          : const Color(0xFF1B5E20),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    size: isTablet
                                                        ? TabletLayout.progressCardDetailChevronSize
                                                        : 16,
                                                    color: isStuck
                                                        ? Colors.red
                                                        : const Color(0xFF1B5E20),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
