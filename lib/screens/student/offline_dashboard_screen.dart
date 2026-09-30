import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/connectivity_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class OfflineDashboardScreen extends StatefulWidget {
  const OfflineDashboardScreen({super.key});

  @override
  State<OfflineDashboardScreen> createState() =>
      _OfflineDashboardScreenState();
}

class _OfflineDashboardScreenState extends State<OfflineDashboardScreen> {
  bool _isChecking = false;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    // Listen perubahan koneksi real-time
    _subscription = ConnectivityService().onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected && mounted) {
          // Koneksi kembali → ke select role
          _showConnectionRestoredDialog();
        }
      },
    );

    // Play BGM home
    AudioService().playBGM(AppAudio.bgmHome);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    AudioService().stopBGM();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Methods
  // ---------------------------------------------------------------------------

  Future<void> _checkAndReconnect() async {
    setState(() => _isChecking = true);

    final isConnected = await ConnectivityService().checkConnection();

    setState(() => _isChecking = false);

    if (!mounted) return;

    if (isConnected) {
      AudioService().stopBGM();
      context.go('/select-role');
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Tidak Terhubung',
            style: TextStyle(fontFamily: 'Fredoka'),
          ),
          content: const Text(
            'Belum terhubung pada jaringan.\n'
            'Periksa koneksi internet kamu.',
            style: TextStyle(fontFamily: 'Fredoka'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
  }

  void _showOfflinePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);
        final isTablet = ResponsiveHelper.isTablet(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 650 : 560),
                    child: Image.asset(
                      'assets/images/template/frame_login.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Padding(
                    padding: isTablet
                        ? const EdgeInsets.fromLTRB(40, 100, 40, 36)
                        : const EdgeInsets.fromLTRB(32, 75, 32, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: isTablet ? 55 : 35,
                          color: const Color(0xFF5A4FCF),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          'Fitur Terbatas!',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF5A4FCF),
                          ),
                        ),
                        SizedBox(height: isTablet ? 10 : 6),
                        Text(
                          'Untuk mengakses fitur ini\n'
                          'diharuskan terhubung\n'
                          'pada jaringan internet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 12,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF7B6FD4),
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: isTablet ? 20 : 14),
                        AssetButton(
                          normalAsset: AppImages.btnCheckConnectionNormal,
                          pressedAsset: AppImages.btnCheckConnectionPressed,
                          onTap: () {
                            Navigator.pop(context);
                            _checkAndReconnect();
                          },
                          height: isTablet ? 60 : 42,
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

  void _showConnectionRestoredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = ResponsiveHelper.dialogWidth(screenWidth);
        final isTablet = ResponsiveHelper.isTablet(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background popup template
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 650 : 560),
                    child: Image.asset(
                      'assets/images/template/frame_login.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),

                  // Konten popup
                  Padding(
                    padding: isTablet
                        ? const EdgeInsets.fromLTRB(40, 100, 40, 36)
                        : const EdgeInsets.fromLTRB(32, 75, 32, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          size: isTablet ? 55 : 35,
                          color: const Color(0xFF5A4FCF),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          'Koneksi Tersambung! 🎉',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF5A4FCF),
                          ),
                        ),
                        SizedBox(height: isTablet ? 10 : 6),
                        Text(
                          'Jaringan internet terdeteksi.\nMau masuk ke akun kamu?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 12,
                            fontFamily: 'Fredoka',
                            color: const Color(0xFF7B6FD4),
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: isTablet ? 20 : 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _DialogActionButton(
                              label: 'Nanti Saja',
                              normalColor: Colors.grey.shade400,
                              pressedColor: Colors.grey.shade700,
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 18 : 10,
                                vertical: isTablet ? 10 : 6,
                              ),
                              fontSize: isTablet ? 16 : 11,
                              onTap: () => Navigator.pop(dialogContext),
                            ),
                            SizedBox(width: isTablet ? 14 : 8),
                            _DialogActionButton(
                              label: 'Masuk Sekarang',
                              normalColor: const Color(0xFF5A4FCF),
                              pressedColor: const Color(0xFF3D32A6),
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 18 : 10,
                                vertical: isTablet ? 10 : 6,
                              ),
                              fontSize: isTablet ? 16 : 11,
                              onTap: () {
                                Navigator.pop(dialogContext);
                                AudioService().stopBGM();
                                context.go('/select-role');
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
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  Widget _buildMenuCard({
    required String icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isTablet = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: ColorFiltered(
          colorFilter: isEnabled
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                width: isTablet
                    ? StudentTabletLayout.dashboardMenuIconSize
                    : 110,
                height: isTablet
                    ? StudentTabletLayout.dashboardMenuIconSize
                    : 110,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet
                      ? StudentTabletLayout.dashboardMenuLabelFontSize
                      : 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: Colors.white,
                  shadows: const [
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
          child: Center(
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
                          'Yakin ingin keluar ke menu utama?',
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
          ),
        );
      },
    ).then((_) {
      _isShowingExitDialog = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                // 1. IKON KONEKSI + STATUS (tengah atas)
                Positioned(
                  top: screenHeight * (isTablet ? 0.05 : 0.04),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _ConnectionIconButton(
                      isChecking: _isChecking,
                      onTap: _checkAndReconnect,
                      isTablet: isTablet,
                    ),
                  ),
                ),

                // 4. GRID 2x2 MENU
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
                      // Belajar Huruf - AKTIF
                      _buildMenuCard(
                        icon: AppImages.icLearnLetter,
                        label: 'Belajar Huruf',
                        isEnabled: true,
                        isTablet: isTablet,
                        onTap: () => context.push('/learn-letter'),
                      ),
                      // Mengeja Kata - AKTIF
                      _buildMenuCard(
                        icon: AppImages.icSpellWord,
                        label: 'Mengeja Kata',
                        isEnabled: true,
                        isTablet: isTablet,
                        onTap: () => context.push('/select-objek'),
                      ),
                      // Permainan - NONAKTIF (abu-abu)
                      _buildMenuCard(
                        icon: AppImages.icGame,
                        label: 'Permainan',
                        isEnabled: false,
                        isTablet: isTablet,
                        onTap: () => _showOfflinePopup(),
                      ),
                      // Progress Saya - NONAKTIF (abu-abu)
                      _buildMenuCard(
                        icon: AppImages.icMyProgress,
                        label: 'Progress Saya',
                        isEnabled: false,
                        isTablet: isTablet,
                        onTap: () => _showOfflinePopup(),
                      ),
                    ],
                  ),
                ),

                // 5. NAVBAR
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: isTablet ? StudentTabletLayout.navbarTotalHeight : 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
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
                        // Profil
                        Positioned(
                          bottom: isTablet ? StudentTabletLayout.navbarIconBottom : 18,
                          left: screenWidth * (isTablet ? StudentTabletLayout.navbarProfileLeftFactor : 0.15),
                          child: GestureDetector(
                            onTap: () => context.push('/offline-profile'),
                            child: Image.asset(
                              AppImages.icProfileManDefault,
                              width: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                              height: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                            ),
                          ),
                        ),
                        // Maskot tengah
                        Positioned(
                          bottom: isTablet ? StudentTabletLayout.navbarMascotBottom : 8,
                          child: Image.asset(
                            'assets/images/template/mascot_navbar.png',
                            width: isTablet ? StudentTabletLayout.navbarMascotSize : 75,
                            height: isTablet ? StudentTabletLayout.navbarMascotSize : 75,
                          ),
                        ),
                        // Setting
                        Positioned(
                          bottom: isTablet ? StudentTabletLayout.navbarIconBottom : 18,
                          right: screenWidth * (isTablet ? StudentTabletLayout.navbarSettingsRightFactor : 0.15),
                          child: GestureDetector(
                            onTap: () => context.push('/offline-settings'),
                            child: Image.asset(
                              AppImages.icSettings,
                              width: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                              height: isTablet ? StudentTabletLayout.navbarIconSize : 38,
                            ),
                          ),
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

class _ConnectionIconButton extends StatefulWidget {
  final bool isChecking;
  final VoidCallback onTap;
  final bool isTablet;

  const _ConnectionIconButton({
    required this.isChecking,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  State<_ConnectionIconButton> createState() => _ConnectionIconButtonState();
}

class _ConnectionIconButtonState extends State<_ConnectionIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.isTablet ? 65.0 : 40.0;
    final textFontSize = widget.isTablet ? 17.0 : 11.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: widget.isChecking
          ? SizedBox(
              width: widget.isTablet ? 36 : 24,
              height: widget.isTablet ? 36 : 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: widget.isTablet ? 3.5 : 2.5,
              ),
            )
          : Column(
              children: [
                AnimatedScale(
                  scale: _isPressed ? 0.80 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Image.asset(
                    AppImages.icConnection,
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
                SizedBox(height: widget.isTablet ? 6 : 4),
                Text(
                  'Offline - Tap untuk cek koneksi',
                  style: TextStyle(
                    fontSize: textFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DialogActionButton extends StatefulWidget {
  final String label;
  final Color normalColor;
  final Color pressedColor;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const _DialogActionButton({
    required this.label,
    required this.normalColor,
    required this.pressedColor,
    required this.onTap,
    this.padding,
    this.fontSize,
  });

  @override
  State<_DialogActionButton> createState() => _DialogActionButtonState();
}

class _DialogActionButtonState extends State<_DialogActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isPressed ? widget.pressedColor : widget.normalColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize ?? 12,
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
