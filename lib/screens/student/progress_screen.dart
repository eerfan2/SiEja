import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/services/stage_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _studentName = '';
  bool _isPerempuan = false;
  int _completedStagesCount = 0;
  int _totalStarsCount = 0;
  int _totalScore = 0;
  List<Map<String, dynamic>> _stageList = [];


  @override
  void initState() {
    super.initState();
    AudioService().playBGM(AppAudio.bgmHome);
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    final progressService = ProgressService();
    _studentName = progressService.getStudentName();
    if (_studentName.isEmpty) _studentName = 'Siswa';
    _isPerempuan = progressService.currentJenisKelamin == 'perempuan';

    final stageModels = await StageService().getStages();
    int completed = 0;
    int stars = 0;
    int score = 0;
    final List<Map<String, dynamic>> stages = [];

    for (var model in stageModels) {
      final int stageId = model.number;
      final status = progressService.getStageStatus(stageId);
      final stageScore = progressService.getStageScore(stageId);
      final stageStars = _getStarCount(stageScore);

      if (status == 'completed') {
        completed++;
      }
      stars += stageStars;
      score += stageScore;

      stages.add({
        'id': stageId,
        'nama': model.nama,
        'huruf': model.huruf,
        'lokasi': model.lokasi,
        'status': status,
        'score': stageScore,
        'stars': stageStars,
      });
    }

    if (!mounted) return;
    setState(() {
      _completedStagesCount = completed;
      _totalStarsCount = stars;
      _totalScore = score;
      _stageList = stages;
    });
  }

  int _getStarCount(int score) {
    if (score >= 90) return 3;
    if (score >= 70) return 2;
    if (score >= 50) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;

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
      backgroundAsset: AppImages.bgProgress,
      child: Stack(
        children: [
          // 1. TOMBOL BACK pojok kiri atas
          Positioned(
            top: (screenHeight * 0.11 - 22 - paddingTop).clamp(8.0, screenHeight),
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



          // 2. JUDUL HALAMAN (Tengah Atas)
          Positioned(
            top: (screenHeight * 0.075 - paddingTop).clamp(4.0, screenHeight),
            left: screenWidth * 0.2,
            right: screenWidth * 0.2,
            height: screenHeight * 0.07,
            child: Center(
              child: Text(
                'Progress Belajar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth >= 600 ? 30 : 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: Colors.white,
                  shadows: [
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

          // 3. PROFIL - FIXED (tidak scroll)
          Positioned(
            top: screenHeight * 0.22,
            left: screenWidth * 0.24,
            right: screenWidth * 0.24,
            child: Column(
              children: [
                // Avatar + Nama
                Row(
                  children: [
                    SizedBox(
                      width: screenWidth >= 600 ? 80 : 48,
                      height: screenWidth >= 600 ? 80 : 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/template/profile_avatar.png',
                            width: screenWidth >= 600 ? 80 : 48,
                            height: screenWidth >= 600 ? 80 : 48,
                            fit: BoxFit.fill,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              _isPerempuan
                                  ? 'assets/images/characters/Eva_char.png'
                                  : 'assets/images/characters/Eja_char.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _studentName,
                            style: TextStyle(
                              fontSize: screenWidth >= 600 ? 24 : 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              color: Color(0xFF4E342E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Siswa SiEja',
                            style: TextStyle(
                              fontSize: screenWidth >= 600 ? 18 : 12,
                              fontFamily: 'Fredoka',
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Stats Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: AppImages.icLevel,
                      title: 'Stage',
                      value: '$_completedStagesCount / ${_stageList.isNotEmpty ? _stageList.length : 6}',
                      color: const Color(0xFF4FC3F7),
                      isTablet: screenWidth >= 600,
                    ),
                    _buildStatItem(
                      icon: AppImages.icStar,
                      title: 'Bintang',
                      value: '$_totalStarsCount',
                      color: const Color(0xFFFFD54F),
                      isTablet: screenWidth >= 600,
                    ),
                    _buildStatItem(
                      icon: AppImages.icTrophy,
                      title: 'Skor',
                      value: '$_totalScore',
                      color: const Color(0xFF81C784),
                      isTablet: screenWidth >= 600,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. LIST STAGE - SCROLLABLE
          Positioned(
            top: screenHeight * 0.40, // Disesuaikan sedikit karena space kosong di atas dihapus
            left: screenWidth * 0.24,
            right: screenWidth * 0.24,
            // Beri jarak dari bawah supaya tidak menimpa gambar buku prestasi
            bottom: screenHeight * 0.31,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: _stageList.map((stage) {
                    final status = stage['status'];
                    final score = stage['score'] as int;
                    final stars = stage['stars'] as int;
                    final isLocked = status == 'locked';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLocked
                              ? Colors.grey.withOpacity(0.3)
                              : const Color(0xFF5A4FCF).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Info stage (Langsung tanpa ikon stage)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${stage['nama']}',
                                  style: TextStyle(
                                    fontSize: screenWidth >= 600 ? 20 : 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Fredoka',
                                    color: isLocked ? Colors.grey : const Color(0xFF4E342E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (!isLocked) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: score / 100,
                                      backgroundColor: Colors.grey.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation(
                                        score >= 90
                                            ? Colors.green
                                            : score >= 70
                                                ? const Color(0xFF5A4FCF)
                                                : Colors.orange,
                                      ),
                                      minHeight: screenWidth >= 600 ? 12 : 6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(3, (i) {
                                      return Image.asset(
                                        AppImages.icStar,
                                        width: screenWidth >= 600 ? 22 : 14,
                                        height: screenWidth >= 600 ? 22 : 14,
                                        color: i < stars ? null : Colors.grey.withOpacity(0.4),
                                        colorBlendMode: BlendMode.modulate,
                                      );
                                    }),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Skor / Gembok
                          if (isLocked)
                            Image.asset(
                              AppImages.icLock,
                              width: screenWidth >= 600 ? 36 : 24,
                              height: screenWidth >= 600 ? 36 : 24,
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: screenWidth >= 600 ? 26 : 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Fredoka',
                                    color: Color(0xFF5A4FCF),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'completed')
                                      Text(
                                        '✅ Selesai',
                                        style: TextStyle(
                                          fontSize: screenWidth >= 600 ? 14 : 10,
                                          fontFamily: 'Fredoka',
                                          color: Colors.green,
                                        ),
                                      )
                                    else ...[
                                      Image.asset(
                                        AppImages.icUnlock,
                                        width: screenWidth >= 600 ? 22 : 14,
                                        height: screenWidth >= 600 ? 22 : 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Terbuka',
                                        style: TextStyle(
                                          fontSize: screenWidth >= 600 ? 14 : 10,
                                          fontFamily: 'Fredoka',
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildStatItem({
    required String icon,
    required String title,
    required String value,
    required Color color,
    required bool isTablet,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            icon,
            width: isTablet ? 32 : 20,
            height: isTablet ? 32 : 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 16 : 10,
            fontFamily: 'Fredoka',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
            color: Color(0xFF4E342E),
          ),
        ),
      ],
    );
  }
}
