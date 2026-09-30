import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/widgets/inner_shadow_container.dart';

class LoginTeacherScreen extends StatefulWidget {
  const LoginTeacherScreen({super.key});

  @override
  State<LoginTeacherScreen> createState() => _LoginTeacherScreenState();
}

class _LoginTeacherScreenState extends State<LoginTeacherScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username dan Password tidak boleh kosong!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Login pakai Firebase Auth
    // Email format: username@sieja.com
    final email = username.contains('@') ? username : '$username@sieja.com';

    final success = await FirebaseService().loginGuru(email, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      context.go('/teacher-dashboard');
    } else {
      setState(() {
        _errorMessage = 'Username atau Password salah! Periksa kembali data login Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = ResponsiveHelper.isTablet(screenWidth);
    final layoutWidth = isTablet ? TabletLayout.loginFrameWidth : screenWidth;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        AudioService().stopBGM();
        context.go('/select-role');
      },
      child: BgScaffold(
      backgroundAsset: AppImages.bgDashboardTeacher,
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
                      top: layoutWidth * (isTablet ? TabletLayout.loginContentTopFactor : 0.23),
                      left: layoutWidth * (isTablet ? TabletLayout.loginContentLeftFactor : 0.15),
                      right: layoutWidth * (isTablet ? TabletLayout.loginContentRightFactor : 0.15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Judul Login
                          Text(
                            'LOGIN GURU',
                            style: TextStyle(
                              fontSize: isTablet ? TabletLayout.loginTitleFontSize : 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              color: const Color(0xFF5A4FCF),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // TextField Username
                          InnerShadowContainer(
                            height: isTablet ? TabletLayout.loginFieldHeight : 45,
                            borderRadius: isTablet ? TabletLayout.loginFieldRadius : 10,
                            backgroundColor: const Color(0xFFE1D9CF),
                            child: TextField(
                              controller: _usernameController,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? TabletLayout.loginFieldFontSize : 14,
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A3E3D),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Username',
                                hintStyle: TextStyle(
                                  color: const Color(0x994A3E3D),
                                  fontSize: isTablet ? TabletLayout.loginHintFontSize : 14,
                                  fontFamily: 'Fredoka',
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // TextField Password
                          InnerShadowContainer(
                            height: isTablet ? TabletLayout.loginFieldHeight : 45,
                            borderRadius: isTablet ? TabletLayout.loginFieldRadius : 10,
                            backgroundColor: const Color(0xFFE1D9CF),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? TabletLayout.loginFieldFontSize : 14,
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A3E3D),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: const Color(0x994A3E3D),
                                  fontSize: isTablet ? TabletLayout.loginHintFontSize : 14,
                                  fontFamily: 'Fredoka',
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                prefixIcon: const SizedBox(width: 48),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF5A4FCF),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? TabletLayout.loginErrorFontSize : 12,
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),

                          if (_isLoading)
                            const CircularProgressIndicator(
                              color: Color(0xFF5A4FCF),
                            )
                          else
                            // Tombol Login
                            SizedBox(
                              width: layoutWidth * (isTablet ? TabletLayout.loginButtonWidthFactor : 0.30),
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

          // Tombol Back pojok kiri atas
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                AudioService().stopBGM();
                context.go('/select-role');
              },
              child: Image.asset(
                AppImages.icBack,
                width: isTablet ? TabletLayout.loginBackBtnSize : 48,
                height: isTablet ? TabletLayout.loginBackBtnSize : 48,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
