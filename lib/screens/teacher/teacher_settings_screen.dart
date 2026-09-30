import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _isBgmOn = true;

  @override
  void initState() {
    super.initState();
    _isBgmOn = !AudioService().isMuted;
  }

  Widget _buildDialogAboutRow(String label, String value, {bool isTablet = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 5 : 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet
                  ? TabletLayout.settingsAboutLabelFontSize
                  : 12,
              fontFamily: 'Fredoka',
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet
                  ? TabletLayout.settingsAboutValueFontSize
                  : 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Fredoka',
              color: const Color(0xFF5A4FCF),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.settingsAboutPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        final dialogPadding = isTablet
            ? const EdgeInsets.fromLTRB(
                TabletLayout.settingsAboutPopupPaddingH,
                TabletLayout.settingsAboutPopupPaddingTop,
                TabletLayout.settingsAboutPopupPaddingH,
                TabletLayout.settingsAboutPopupPaddingBottom,
              )
            : ResponsiveHelper.dialogPadding(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Background Frame
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet
                          ? TabletLayout.settingsAboutPopupMaxWidth
                          : 560,
                    ),
                    child: Image.asset(
                      'assets/images/template/frame_student_list.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),

                  // 2. Konten Informasi Aplikasi
                  Positioned.fill(
                    child: Padding(
                      padding: dialogPadding,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppImages.logoAplikasiInfo,
                              width: isTablet
                                  ? TabletLayout.settingsAboutLogoSize
                                  : 60,
                              height: isTablet
                                  ? TabletLayout.settingsAboutLogoSize
                                  : 60,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Icon(
                                Icons.apps,
                                size: isTablet ? 65 : 50,
                                color: const Color(0xFF5A4FCF),
                              ),
                            ),
                            SizedBox(height: isTablet ? 8 : 6),
                            Text(
                              'SiEja',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? TabletLayout.settingsAboutTitleFontSize
                                    : 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: const Color(0xFF5A4FCF),
                              ),
                            ),
                            Text(
                              'Versi 1.0',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? TabletLayout.settingsAboutVersionFontSize
                                    : 12,
                                fontFamily: 'Fredoka',
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            Divider(color: Colors.grey.withValues(alpha: 0.3)),
                            SizedBox(height: isTablet ? 8 : 6),
                            _buildDialogAboutRow('Pengembang', 'Muhammad Irfan', isTablet: isTablet),
                            _buildDialogAboutRow('Universitas', 'Universitas Bale Bandung', isTablet: isTablet),
                            _buildDialogAboutRow('Tahun', '2026', isTablet: isTablet),
                            SizedBox(height: isTablet ? 8 : 6),
                            Text(
                              'Aplikasi edukasi mengeja\nuntuk anak usia dini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet
                                    ? TabletLayout.settingsAboutDescFontSize
                                    : 11,
                                fontFamily: 'Fredoka',
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Tombol Tutup (Hanya Ikon ic_wrong di sudut kanan atas)
                  Positioned(
                    top: isTablet ? 30 : 10,
                    right: isTablet ? 35 : 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Image.asset(
                        AppImages.icWrong,
                        width: isTablet
                            ? TabletLayout.settingsAboutCloseBtnSize
                            : 36,
                        height: isTablet
                            ? TabletLayout.settingsAboutCloseBtnSize
                            : 36,
                      ),
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
        backgroundAsset: 'assets/images/background/bg_settings.png',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isTablet = ResponsiveHelper.isTablet(screenWidth);
            assert(screenWidth >= 0);

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
                        context.go('/teacher-dashboard');
                      }
                    },
                    width: isTablet ? TabletLayout.settingsBackBtnWidth : 80,
                    height: isTablet ? TabletLayout.settingsBackBtnHeight : 44,
                  ),
                ),

                // 2a. JUDUL FIXED (tidak ikut scroll)
                Positioned(
                  top: isTablet ? screenHeight * 0.18 : screenHeight * 0.20,
                  left: screenWidth * 0.11,
                  right: screenWidth * 0.36,
                  child: Text(
                    'Pengaturan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? TabletLayout.settingsTitleFontSize : 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2b. MENU SETTING GURU (scrollable)
                Positioned(
                  top: isTablet ? screenHeight * 0.26 : screenHeight * 0.265,
                  bottom: isTablet ? screenHeight * 0.25 : screenHeight * 0.40,
                  left: screenWidth * 0.11,
                  right: screenWidth * 0.36,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                        // BGM On/Off
                        Container(
                          margin: EdgeInsets.only(
                            bottom: isTablet
                                ? TabletLayout.settingsCardMarginBottom
                                : 12,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet
                                ? TabletLayout.settingsCardPaddingH
                                : 16,
                            vertical: isTablet
                                ? TabletLayout.settingsCardPaddingV
                                : 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4D3E).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF81C784).withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                AppImages.icSound,
                                width: isTablet
                                    ? TabletLayout.settingsCardIconSize
                                    : 36,
                                height: isTablet
                                    ? TabletLayout.settingsCardIconSize
                                    : 36,
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Musik Latar',
                                      style: TextStyle(
                                        fontSize: isTablet
                                            ? TabletLayout.settingsCardTitleFontSize
                                            : 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Fredoka',
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _isBgmOn
                                          ? 'Musik menyala'
                                          : 'Musik dimatikan',
                                      style: TextStyle(
                                        fontSize: isTablet
                                            ? TabletLayout.settingsCardSubtitleFontSize
                                            : 11,
                                        fontFamily: 'Fredoka',
                                        color: const Color(0xFFA5D6A7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: isTablet
                                    ? TabletLayout.settingsSwitchScale
                                    : 1.0,
                                child: Switch(
                                  value: _isBgmOn,
                                  onChanged: (value) {
                                    setState(() => _isBgmOn = value);
                                    AudioService().toggleMute();
                                  },
                                  activeThumbColor: const Color(0xFF81C784),
                                  activeTrackColor: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tentang Aplikasi (Tombol Pop-up)
                        GestureDetector(
                          onTap: () => _showAboutDialog(),
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: isTablet
                                  ? TabletLayout.settingsCardMarginBottom
                                  : 12,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet
                                  ? TabletLayout.settingsCardPaddingH
                                  : 16,
                              vertical: isTablet
                                  ? TabletLayout.settingsCardPaddingV
                                  : 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4D3E).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF81C784).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: isTablet
                                      ? TabletLayout.settingsCardIconSize
                                      : 36,
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                                Expanded(
                                  child: Text(
                                    'Tentang Aplikasi',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? TabletLayout.settingsCardTitleFontSize
                                          : 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _DialogActionButton extends StatefulWidget {
  final String label;
  final Color normalColor;
  final Color pressedColor;
  final VoidCallback onTap;

  const _DialogActionButton({
    required this.label,
    required this.normalColor,
    required this.pressedColor,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isPressed ? widget.pressedColor : widget.normalColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
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
