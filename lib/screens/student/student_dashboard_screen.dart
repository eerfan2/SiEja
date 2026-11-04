import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with TickerProviderStateMixin {
  String _studentName = '';
  bool _isPerempuan = false;
  late AnimationController _breatheController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _studentName = ProgressService().getStudentName();
    if (_studentName.isEmpty) _studentName = 'Siswa';
    _isPerempuan = ProgressService().currentJenisKelamin == 'perempuan';



    // Animasi bernapas (mengembang-mengempis) santai dan lembut khusus untuk 4 menu utama
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AudioService().playBGM(AppAudio.bgmHome);
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _buildMenuCard({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
    required int index,
  }) {
    final start = (index * 0.12).clamp(0.0, 1.0);
    final end = (start + 0.50).clamp(0.0, 1.0);
    final entranceAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    bool isPressed = false;
    return AnimatedBuilder(
      animation: Listenable.merge([entranceAnim, _breatheController]),
      builder: (context, child) {
        // Fase 90 derajat per index kartu agar pergerakan mengembang-mengempis tenang & bergantian
        final phase = index * (math.pi / 2);
        final cycle = math.sin((_breatheController.value * 2 * math.pi) + phase);
        final breatheScale = 1.0 + (0.045 * cycle); // Mengembang 1.045, mengempis 0.955 dengan ritme santai

        return Opacity(
          opacity: entranceAnim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - entranceAnim.value) * 35),
            child: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTapDown: (_) => setState(() => isPressed = true),
                  onTapUp: (_) {
                    setState(() => isPressed = false);
                    onTap();
                  },
                  onTapCancel: () => setState(() => isPressed = false),
                  child: Transform.scale(
                    scale: breatheScale,
                    child: AnimatedScale(
                      scale: isPressed ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            icon,
                            width: isTablet ? StudentTabletLayout.dashboardMenuIconSize : 110,
                            height: isTablet ? StudentTabletLayout.dashboardMenuIconSize : 110,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? StudentTabletLayout.dashboardMenuLabelFontSize : 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              color: Colors.white,
                              shadows: const [
                                // Shadow gelap tebal supaya
                                // tidak silau dengan background
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black87,
                                  offset: Offset(2, 2),
                                ),
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black87,
                                  offset: Offset(-2, -2),
                                ),
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black87,
                                  offset: Offset(2, -2),
                                ),
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black87,
                                  offset: Offset(-2, 2),
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
            ),
          ),
        );
      },
    );
  }

  bool _isShowingExitDialog = false;

  void _showExitDialog() {
    if (_isShowingExitDialog) return;
    _isShowingExitDialog = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);

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
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Image.asset(
                    'assets/images/template/frame_login.png',
                    width: dialogWidth,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                // Konten popup
                Padding(
                padding: const EdgeInsets.fromLTRB(40, 55, 40, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teks utama
                    const Text(
                      'Keluar? 🚪',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: Color(0xFF5A4FCF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Teks penjelasan
                    const Text(
                      'Yakin ingin keluar dan ganti akun?',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Fredoka',
                        color: Color(0xFF7B6FD4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // Tombol aksi
                    StatefulBuilder(
                      builder: (context, setBtnState) {
                        bool isBatalPressed = false;
                        bool isKeluarPressed = false;

                        return StatefulBuilder(
                          builder: (context, setBtnState) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Tombol Batal
                                GestureDetector(
                                  onTapDown: (_) =>
                                      setBtnState(() => isBatalPressed = true),
                                  onTapUp: (_) {
                                    setBtnState(() => isBatalPressed = false);
                                    Navigator.pop(context);
                                  },
                                  onTapCancel: () =>
                                      setBtnState(() => isBatalPressed = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 7),
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
                                    child: const Text(
                                      'Batal',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        color: Color(0xFF4A3E3D),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Tombol Keluar
                                GestureDetector(
                                  onTapDown: (_) =>
                                      setBtnState(() => isKeluarPressed = true),
                                  onTapUp: (_) {
                                    setBtnState(() => isKeluarPressed = false);
                                    Navigator.pop(context);
                                    AudioService().stopBGM();
                                    ProgressService().setCurrentSiswa('', '');
                                    context.go('/select-role');
                                  },
                                  onTapCancel: () =>
                                      setBtnState(() => isKeluarPressed = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 7),
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
                                    child: const Text(
                                      'Keluar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        _showExitDialog();
      },
      child: BgScaffold(
      backgroundAsset: AppImages.bgDashboardStudent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = ResponsiveHelper.isTablet(screenWidth);

          return Stack(
            children: [
              // 1. Header (pojok kiri atas)
              Positioned(
                top: screenHeight * (isTablet ? StudentTabletLayout.dashboardHeaderTopFactor : 0.04),
                left: isTablet ? StudentTabletLayout.dashboardHeaderLeft : 12,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Nametag dinamis
                    Padding(
                      padding: EdgeInsets.only(
                        left: isTablet ? StudentTabletLayout.dashboardNametagPaddingLeft : 28,
                      ),
                      child: IntrinsicWidth(
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: screenWidth * (isTablet ? 0.28 : 0.25),
                            maxWidth: screenWidth * 0.55,
                          ),
                          child: Image.asset(
                            'assets/images/template/name_tag.png',
                            fit: BoxFit.fill,
                            height: isTablet ? StudentTabletLayout.dashboardNametagHeight : 44,
                          ),
                        ),
                      ),
                    ),
                    // Avatar profil (statis tanpa animasi)
                    Positioned(
                      left: 0,
                      top: isTablet ? StudentTabletLayout.dashboardAvatarTopOffset : -8,
                      child: SizedBox(
                        width: isTablet ? StudentTabletLayout.dashboardAvatarSize : 55,
                        height: isTablet ? StudentTabletLayout.dashboardAvatarSize : 55,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/template/profile_avatar.png',
                              width: isTablet ? StudentTabletLayout.dashboardAvatarSize : 55,
                              height: isTablet ? StudentTabletLayout.dashboardAvatarSize : 55,
                              fit: BoxFit.fill,
                            ),
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 11 : 8),
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
                    ),
                    // Teks nama
                    Positioned(
                      left: isTablet ? StudentTabletLayout.dashboardNameTextLeft : 56,
                      top: 0,
                      bottom: 0,
                      right: isTablet ? 14 : 8,
                      child: Center(
                        child: Text(
                          _studentName,
                          style: TextStyle(
                            fontSize: isTablet ? StudentTabletLayout.dashboardNameFontSize : 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5A4FCF),
                            fontFamily: 'Fredoka',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              // 3. Grid 2x2 Menu Utama (tengah layar)
              Positioned(
                top: screenHeight * (isTablet ? StudentTabletLayout.dashboardGridTopFactor : 0.35),
                left: isTablet ? StudentTabletLayout.dashboardGridHorizontalPadding : 16,
                right: isTablet ? StudentTabletLayout.dashboardGridHorizontalPadding : 16,
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: isTablet ? StudentTabletLayout.dashboardGridSpacingH : 16,
                  mainAxisSpacing: isTablet ? StudentTabletLayout.dashboardGridSpacingV : 16,
                  children: [
                    _buildMenuCard(
                      icon: AppImages.icLearnLetter,
                      label: 'Belajar Huruf',
                      isTablet: isTablet,
                      index: 0,
                      onTap: () async {
                        await context.push('/learn-letter');
                        if (mounted) {
                          AudioService().playBGM(AppAudio.bgmHome);
                        }
                      },
                    ),
                    _buildMenuCard(
                      icon: AppImages.icSpellWord,
                      label: 'Mengeja Kata',
                      isTablet: isTablet,
                      index: 1,
                      onTap: () async {
                        await context.push('/select-objek');
                        if (mounted) {
                          AudioService().playBGM(AppAudio.bgmHome);
                        }
                      },
                    ),
                    _buildMenuCard(
                      icon: AppImages.icGame,
                      label: 'Permainan',
                      isTablet: isTablet,
                      index: 2,
                      onTap: () async {
                        await context.push('/stage-map');
                        if (mounted) {
                          AudioService().playBGM(AppAudio.bgmHome);
                        }
                      },
                    ),
                    _buildMenuCard(
                      icon: AppImages.icMyProgress,
                      label: 'Progress Saya',
                      isTablet: isTablet,
                      index: 3,
                      onTap: () async {
                        await context.push('/progress');
                        if (mounted) {
                          AudioService().playBGM(AppAudio.bgmHome);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 4. Bottom Navigation Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: isTablet ? StudentTabletLayout.navbarTotalHeight : 70,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Background navbar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/template/navbar_bg.png',
                          width: screenWidth,
                          height: isTablet ? StudentTabletLayout.navbarBgHeight : 65,
                          fit: BoxFit.fill,
                        ),
                      ),
                      
                      // Ikon kiri - Profil
                      Positioned(
                        bottom: isTablet ? StudentTabletLayout.navbarIconBottom : 18,
                        left: screenWidth * (isTablet ? StudentTabletLayout.navbarProfileLeftFactor : 0.15),
                        child: () {
                          bool isPressed = false;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return GestureDetector(
                                onTapDown: (_) =>
                                    setState(() => isPressed = true),
                                onTapUp: (_) async {
                                  setState(() => isPressed = false);
                                  await Future.delayed(
                                      const Duration(milliseconds: 100));
                                  if (context.mounted) {
                                    await context.push('/profile');
                                    if (mounted) {
                                      AudioService().playBGM(AppAudio.bgmHome);
                                    }
                                  }
                                },
                                onTapCancel: () =>
                                    setState(() => isPressed = false),
                                child: AnimatedScale(
                                  scale: isPressed ? 1.25 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Image.asset(
                                    AppImages.icProfileManDefault,
                                    width: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                                    height: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                                  ),
                                ),
                              );
                            },
                          );
                        }(),
                      ),
                      
                      // Maskot tengah (menonjol ke atas)
                      Positioned(
                        bottom: isTablet ? StudentTabletLayout.navbarMascotBottom : 8,
                        child: GestureDetector(
                          onTap: () {},
                          child: Image.asset(
                            'assets/images/template/mascot_navbar.png',
                            width: isTablet ? StudentTabletLayout.navbarMascotSize : 75,
                            height: isTablet ? StudentTabletLayout.navbarMascotSize : 75,
                          ),
                        ),
                      ),
                      
                      // Ikon kanan - Pengaturan
                      Positioned(
                        bottom: isTablet ? StudentTabletLayout.navbarIconBottom : 18,
                        right: screenWidth * (isTablet ? StudentTabletLayout.navbarSettingsRightFactor : 0.15),
                        child: () {
                          bool isPressed = false;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return GestureDetector(
                                onTapDown: (_) =>
                                    setState(() => isPressed = true),
                                onTapUp: (_) async {
                                  setState(() => isPressed = false);
                                  await Future.delayed(
                                      const Duration(milliseconds: 100));
                                  if (context.mounted) {
                                    await context.push('/settings');
                                    if (mounted) {
                                      AudioService().playBGM(AppAudio.bgmHome);
                                    }
                                  }
                                },
                                onTapCancel: () =>
                                    setState(() => isPressed = false),
                                child: AnimatedScale(
                                  scale: isPressed ? 1.25 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Image.asset(
                                    AppImages.icSettings,
                                    width: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                                    height: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                                  ),
                                ),
                              );
                            },
                          );
                        }(),
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
