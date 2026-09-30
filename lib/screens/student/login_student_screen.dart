import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/widgets/inner_shadow_container.dart';

class LoginStudentScreen extends StatefulWidget {
  const LoginStudentScreen({super.key});

  @override
  State<LoginStudentScreen> createState() => _LoginStudentScreenState();
}

class _LoginStudentScreenState extends State<LoginStudentScreen> {
  final _namaController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _handleLogin() async {
    if (_isLoading) return;

    final nama = _namaController.text.trim();
    final pin = _pinController.text.trim();

    if (nama.isEmpty || pin.isEmpty) {
      setState(() {
        _errorMessage = 'Username dan PIN tidak boleh kosong!';
      });
      return;
    }

    if (pin.length != 3) {
      setState(() {
        _errorMessage = 'PIN harus 3 digit!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Login siswa via Firebase
    try {
      final siswa = await FirebaseService().loginSiswa(nama, pin);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (siswa != null) {
        // Simpan data siswa yang login
        final progressService = ProgressService();
        progressService.setCurrentSiswa(
          siswa['id'],
          siswa['jenisKelamin'] ?? 'laki-laki',
        );
        await progressService.saveStudent(
          siswa['username'] ?? nama,
          pin,
        );
        await progressService.loadStudentProgressFromFirebase(siswa);

        if (!mounted) return;
        context.go('/student-dashboard');
      } else {
        setState(() {
          _errorMessage =
              'Username atau PIN salah! Minta gurumu untuk mendaftarkanmu.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errorMsg = e.toString();
      if (kDebugMode) {
        debugPrint('Login siswa error: $errorMsg');
      }
      setState(() {
        if (errorMsg.contains('permission-denied')) {
          _errorMessage =
              'Gagal mengakses database. Pastikan koneksi atau izin database benar (permission-denied).';
        } else if (errorMsg.contains('unavailable')) {
          _errorMessage = 'Tidak ada koneksi internet (unavailable).';
        } else {
          _errorMessage = 'Terjadi kesalahan: $errorMsg';
        }
      });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = ResponsiveHelper.isTablet(screenWidth);
    final layoutWidth = isTablet ? StudentTabletLayout.loginFrameWidth : screenWidth;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        context.go('/select-role');
      },
      child: BgScaffold(
        backgroundAsset: AppImages.bgDashboardStudent,
        resizeToAvoidBottomInset: false,
        child: Stack(
          children: [
            // Konten Utama
            Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                  width: layoutWidth * 0.85,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bingkai
                      Image.asset(
                        'assets/images/template/frame_login.png',
                        width: layoutWidth * 0.85,
                        fit: BoxFit.fitWidth,
                      ),

                      // Konten di dalam bingkai
                      Positioned(
                        top: layoutWidth * (isTablet ? StudentTabletLayout.loginContentTopFactor : 0.23),
                        left: layoutWidth * (isTablet ? StudentTabletLayout.loginContentLeftFactor : 0.15),
                        right: layoutWidth * (isTablet ? StudentTabletLayout.loginContentRightFactor : 0.15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Judul Login
                            Text(
                              'LOGIN SISWA',
                              style: TextStyle(
                                fontSize: isTablet ? StudentTabletLayout.loginTitleFontSize : 19,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: const Color(0xFF5A4FCF),
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: isTablet ? 12 : 6),

                            // TextField Username
                            InnerShadowContainer(
                              height: isTablet ? StudentTabletLayout.loginFieldHeight : 45,
                              borderRadius: isTablet ? StudentTabletLayout.loginFieldRadius : 10,
                              backgroundColor: const Color(0xFFE1D9CF),
                              child: TextField(
                                controller: _namaController,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? StudentTabletLayout.loginFieldFontSize : 14,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A3E3D),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: TextStyle(
                                    color: const Color(0x994A3E3D),
                                    fontSize: isTablet ? StudentTabletLayout.loginHintFontSize : 14,
                                    fontFamily: 'Fredoka',
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: isTablet ? 16 : 12),
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 14 : 8),

                            // TextField PIN
                            InnerShadowContainer(
                              height: isTablet ? StudentTabletLayout.loginFieldHeight : 45,
                              borderRadius: isTablet ? StudentTabletLayout.loginFieldRadius : 10,
                              backgroundColor: const Color(0xFFE1D9CF),
                              child: TextField(
                                controller: _pinController,
                                textAlign: TextAlign.center,
                                obscureText: true,
                                maxLength: 3,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: TextStyle(
                                  fontSize: isTablet ? StudentTabletLayout.loginFieldFontSize : 14,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A3E3D),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'PIN (3 digit)',
                                  hintStyle: TextStyle(
                                    color: const Color(0x994A3E3D),
                                    fontSize: isTablet ? StudentTabletLayout.loginHintFontSize : 14,
                                    fontFamily: 'Fredoka',
                                  ),
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: isTablet ? 16 : 12),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? StudentTabletLayout.loginErrorFontSize : 12,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                            SizedBox(height: isTablet ? 12 : 6),

                            if (_isLoading)
                              const CircularProgressIndicator(
                                color: Color(0xFF5A4FCF),
                              )
                            else
                              // Tombol Login
                              SizedBox(
                                width: layoutWidth * (isTablet ? StudentTabletLayout.loginButtonWidthFactor : 0.30),
                                child: AssetButton(
                                  normalAsset: AppImages.btnLoginNormal,
                                  pressedAsset: AppImages.btnLoginPressed,
                                  onTap: _handleLogin,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tombol Back pojok kiri atas halaman
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => context.go('/select-role'),
                child: Image.asset(
                  AppImages.icBack,
                  width: isTablet ? StudentTabletLayout.loginBackBtnSize : 48,
                  height: isTablet ? StudentTabletLayout.loginBackBtnSize : 48,
                ),
              ),
            ),

            // Tombol Mode Offline pojok kanan atas
            Positioned(
              top: isTablet ? 30 : 25,
              right: isTablet ? 25 : 16,
              child: Column(
                children: [
                  SizedBox(
                    width: isTablet ? StudentTabletLayout.loginOfflineBtnWidth : 90,
                    child: AssetButton(
                      normalAsset: AppImages.btnOfflineNormal,
                      pressedAsset: AppImages.btnOfflinePressed,
                      onTap: () => context.go('/offline-dashboard'),
                    ),
                  ),
                  SizedBox(height: isTablet ? 4 : 2),
                  Text(
                    'Tanpa Akun',
                    style: TextStyle(
                      fontSize: isTablet ? StudentTabletLayout.loginOfflineLabelFontSize : 10,
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
