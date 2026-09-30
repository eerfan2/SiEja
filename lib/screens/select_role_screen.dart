import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  bool _studentPressed = false;
  bool _teacherPressed = false;

  @override
  void initState() {
    super.initState();
    AudioService().stopBGM();
  }

  void _onStudentTapDown(TapDownDetails _) =>
      setState(() => _studentPressed = true);

  void _onStudentTapUp(TapUpDetails _) {
    setState(() => _studentPressed = false);
    context.go('/login-student');
  }

  void _onStudentTapCancel() =>
      setState(() => _studentPressed = false);

  void _onTeacherTapDown(TapDownDetails _) =>
      setState(() => _teacherPressed = true);

  void _onTeacherTapUp(TapUpDetails _) {
    setState(() => _teacherPressed = false);
    context.go('/login-teacher');
  }

  void _onTeacherTapCancel() =>
      setState(() => _teacherPressed = false);

  bool _isShowingExitDialog = false;

  void _showExitAppDialog() {
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  padding: const EdgeInsets.fromLTRB(40, 55, 40, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Keluar Aplikasi? 🚪',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Fredoka',
                          color: Color(0xFF5A4FCF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Yakin ingin keluar dari aplikasi SiEja?',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Fredoka',
                          color: Color(0xFF7B6FD4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      StatefulBuilder(
                        builder: (context, setBtnState) {
                          bool isBatalPressed = false;
                          bool isKeluarPressed = false;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              GestureDetector(
                                onTapDown: (_) =>
                                    setBtnState(() => isKeluarPressed = true),
                                onTapUp: (_) {
                                  setBtnState(() => isKeluarPressed = false);
                                  SystemNavigator.pop();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        _showExitAppDialog();
      },
      child: BgScaffold(
        backgroundAsset: AppImages.bgSelectRole,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final layoutWidth = ResponsiveHelper.isTablet(screenWidth)
                ? TabletLayout.selectRoleLayoutWidth
                : screenWidth;
            final hPadding = (screenWidth - layoutWidth) / 2 + 24;

            return Stack(
              children: [
                // Tombol Siswa
                Positioned(
                  left: hPadding,
                  right: hPadding,
                  top: screenHeight * (ResponsiveHelper.isTablet(screenWidth)
                      ? TabletLayout.selectRoleStudentTopFactor
                      : 0.35),
                  child: GestureDetector(
                    onTapDown: _onStudentTapDown,
                    onTapUp: _onStudentTapUp,
                    onTapCancel: _onStudentTapCancel,
                    child: AnimatedScale(
                      scale: _studentPressed ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: Image.asset(
                        AppImages.btnRoleStudent,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),

                // Tombol Guru
                Positioned(
                  left: hPadding,
                  right: hPadding,
                  top: screenHeight * (ResponsiveHelper.isTablet(screenWidth)
                      ? TabletLayout.selectRoleTeacherTopFactor
                      : 0.65),
                  child: GestureDetector(
                    onTapDown: _onTeacherTapDown,
                    onTapUp: _onTeacherTapUp,
                    onTapCancel: _onTeacherTapCancel,
                    child: AnimatedScale(
                      scale: _teacherPressed ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: Image.asset(
                        AppImages.btnRoleTeacher,
                        fit: BoxFit.fitWidth,
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
