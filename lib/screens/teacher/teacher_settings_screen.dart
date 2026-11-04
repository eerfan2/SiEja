import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
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

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSaving = false;
    String? errorMessage;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.of(dialogContext).size.width;
            final isTablet = ResponsiveHelper.isTablet(screenWidth);
            final dialogWidth = isTablet ? 480.0 : (screenWidth * 0.9).clamp(280.0, 420.0);

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Container(
                  width: dialogWidth,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEAFD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                color: Color(0xFF5A4FCF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Ubah Kata Sandi Guru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Fredoka',
                                  color: Color(0xFF2C2560),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close, color: Colors.grey),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: currentPassController,
                          obscureText: obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Saat Ini',
                            hintText: 'Masukkan kata sandi lama',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPassController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Baru',
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPassController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi Baru',
                            hintText: 'Ulangi kata sandi baru',
                            prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Fredoka'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Batal', style: TextStyle(fontFamily: 'Fredoka')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final currentPass = currentPassController.text.trim();
                                        final newPass = newPassController.text.trim();
                                        final confirmPass = confirmPassController.text.trim();

                                        if (currentPass.isEmpty) {
                                          setDialogState(() => errorMessage = 'Kata sandi saat ini wajib diisi.');
                                          return;
                                        }
                                        if (newPass.length < 6) {
                                          setDialogState(() => errorMessage = 'Kata sandi baru minimal 6 karakter.');
                                          return;
                                        }
                                        if (newPass != confirmPass) {
                                          setDialogState(() => errorMessage = 'Konfirmasi kata sandi baru tidak cocok.');
                                          return;
                                        }
                                        if (currentPass == newPass) {
                                          setDialogState(() => errorMessage = 'Kata sandi baru harus berbeda dari yang lama.');
                                          return;
                                        }

                                        setDialogState(() {
                                          isSaving = true;
                                          errorMessage = null;
                                        });

                                        final err = await FirebaseService().ubahKataSandiGuru(currentPass, newPass);

                                        if (!mounted) return;

                                        if (err != null) {
                                          setDialogState(() {
                                            isSaving = false;
                                            errorMessage = err;
                                          });
                                        } else {
                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Kata sandi guru berhasil diubah!'),
                                              backgroundColor: Color(0xFF2E7D32),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5A4FCF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  isSaving ? 'Menyimpan...' : 'Simpan',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Fredoka'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

                        // Ubah Kata Sandi (Tombol Pop-up)
                        GestureDetector(
                          onTap: () => _showChangePasswordDialog(),
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
                                  Icons.lock_reset,
                                  color: Colors.white,
                                  size: isTablet
                                      ? TabletLayout.settingsCardIconSize
                                      : 36,
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                                Expanded(
                                  child: Text(
                                    'Ubah Kata Sandi',
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
