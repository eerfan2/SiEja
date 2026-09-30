import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/core/responsive_helper.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/firebase_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/widgets/asset_button.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';
import 'package:si_eja/widgets/inner_shadow_container.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    AudioService().playBGM(AppAudio.bgmHome);
    _searchController = TextEditingController();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await FirebaseService().getAllSiswa();
    if (!mounted) return;
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchController.text.isEmpty) return _students;
    return _students
        .where((s) =>
            (s['namaLengkap'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (s['username'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  void _showTambahSiswaDialog() {
    final namaLengkapController = TextEditingController();
    final usernameController = TextEditingController();
    final usiaController = TextEditingController();
    String jenisKelamin = 'laki-laki';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.studentListPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        final dialogPadding = isTablet
            ? const EdgeInsets.fromLTRB(
                TabletLayout.studentListPopupPaddingH,
                TabletLayout.studentListPopupPaddingTop,
                TabletLayout.studentListPopupPaddingH,
                TabletLayout.studentListPopupPaddingBottom,
              )
            : ResponsiveHelper.dialogPadding(screenWidth);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: dialogWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet
                            ? TabletLayout.studentListPopupMaxWidth
                            : 560,
                      ),
                      child: Image.asset(
                        AppImages.frameStudentList,
                        width: dialogWidth,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    Padding(
                      padding: dialogPadding,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tambah Siswa Baru',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? TabletLayout.studentListPopupTitleFontSize
                                    : 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                                color: const Color(0xFF5A4FCF),
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Nama Lengkap
                            _buildDialogTextField(
                              controller: namaLengkapController,
                              hint: 'Nama Lengkap',
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 12 : 10),

                            // Username
                            _buildDialogTextField(
                              controller: usernameController,
                              hint: 'Username Login',
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 12 : 10),

                            // Usia
                            _buildDialogTextField(
                              controller: usiaController,
                              hint: 'Usia (tahun)',
                              keyboardType: TextInputType.number,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 12 : 10),

                            // Jenis Kelamin Dropdown
                            InnerShadowContainer(
                              height: isTablet
                                  ? TabletLayout.studentListPopupInputHeight
                                  : 45,
                              borderRadius: 10,
                              backgroundColor: const Color(0xFFE1D9CF),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButton<String>(
                                  value: jenisKelamin,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  alignment: Alignment.center,
                                  dropdownColor: const Color(0xFFE1D9CF),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4A3E3D),
                                    fontSize: isTablet
                                        ? TabletLayout.studentListPopupInputFontSize
                                        : 14,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'laki-laki',
                                      child: Center(
                                        child: Text(
                                          '👦 Laki-laki',
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF4A3E3D),
                                            fontSize: isTablet
                                                ? TabletLayout.studentListPopupInputFontSize
                                                : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'perempuan',
                                      child: Center(
                                        child: Text(
                                          '👧 Perempuan',
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF4A3E3D),
                                            fontSize: isTablet
                                                ? TabletLayout.studentListPopupInputFontSize
                                                : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      jenisKelamin = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 12 : 10),

                            // Info PIN otomatis
                            FutureBuilder<String>(
                              future: FirebaseService().generatePin(),
                              builder: (context, snapshot) {
                                final pin = snapshot.data ?? '...';
                                return InnerShadowContainer(
                                  height: isTablet
                                      ? TabletLayout.studentListPopupInputHeight
                                      : 45,
                                  borderRadius: 10,
                                  backgroundColor: const Color(0xFFC5BCB1),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: isTablet ? 22 : 18,
                                        color: const Color(0xFF4A3E3D),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'PIN Otomatis: $pin',
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? TabletLayout.studentListPopupInputFontSize
                                              : 14,
                                          fontFamily: 'Fredoka',
                                          color: const Color(0xFF4A3E3D),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: isTablet ? 22 : 18),

                            // Tombol aksi
                            Row(
                              children: [
                                // Tombol Batal
                                Expanded(
                                  child: StatefulBuilder(
                                    builder: (context, setBatalState) {
                                      bool isBatalPressed = false;
                                      return StatefulBuilder(
                                        builder: (context, setPressed) {
                                          return GestureDetector(
                                            onTapDown: (_) => setPressed(
                                                () => isBatalPressed = true),
                                            onTapUp: (_) {
                                              setPressed(
                                                  () => isBatalPressed = false);
                                              Navigator.pop(context);
                                            },
                                            onTapCancel: () => setPressed(
                                                () => isBatalPressed = false),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: isTablet
                                                    ? TabletLayout.studentListPopupBtnPaddingV
                                                    : 12,
                                              ),
                                              color: Colors.transparent,
                                              child: Center(
                                                child: Text(
                                                  'Batal',
                                                  style: TextStyle(
                                                    fontFamily: 'Fredoka',
                                                    fontSize: isTablet
                                                        ? TabletLayout.studentListPopupBtnFontSize
                                                        : 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: isBatalPressed
                                                        ? Colors.red
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Tombol Simpan
                                Expanded(
                                  child: StatefulBuilder(
                                    builder: (context, setSimpanState) {
                                      bool isSimpanPressed = false;
                                      return StatefulBuilder(
                                        builder: (context, setPressed) {
                                          return GestureDetector(
                                            onTapDown: (_) => setPressed(
                                                () => isSimpanPressed = true),
                                            onTapUp: (_) async {
                                              setPressed(() =>
                                                  isSimpanPressed = false);

                                              final namaLengkap =
                                                  namaLengkapController.text
                                                      .trim();
                                              final username =
                                                  usernameController.text
                                                      .trim();
                                              final usia = int.tryParse(
                                                      usiaController.text) ??
                                                  0;

                                              if (namaLengkap.isEmpty ||
                                                  username.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Nama dan username harus diisi!',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'Fredoka'),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              final pin =
                                                  await FirebaseService()
                                                      .generatePin();

                                              final errorMessage =
                                                  await FirebaseService()
                                                      .tambahSiswa(
                                                namaLengkap: namaLengkap,
                                                username: username,
                                                pin: pin,
                                                usia: usia,
                                                jenisKelamin: jenisKelamin,
                                              );

                                              if (!context.mounted) return;
                                              Navigator.pop(context);

                                              if (errorMessage == null) {
                                                _loadStudents();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Siswa berhasil ditambahkan! PIN: $pin',
                                                      style: const TextStyle(
                                                          fontFamily:
                                                              'Fredoka'),
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration: const Duration(
                                                        seconds: 3),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      errorMessage,
                                                      style: const TextStyle(
                                                          fontFamily:
                                                              'Fredoka'),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            onTapCancel: () => setPressed(
                                                () => isSimpanPressed = false),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 100),
                                              padding: EdgeInsets.symmetric(
                                                vertical: isTablet
                                                    ? TabletLayout.studentListPopupBtnPaddingV
                                                    : 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSimpanPressed
                                                    ? const Color(0xFF3A309E)
                                                    : const Color(0xFF5A4FCF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF5A4FCF)
                                                            .withOpacity(
                                                                isSimpanPressed
                                                                    ? 0.2
                                                                    : 0.4),
                                                    blurRadius:
                                                        isSimpanPressed ? 4 : 8,
                                                    offset: Offset(
                                                        0,
                                                        isSimpanPressed
                                                            ? 2
                                                            : 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Simpan',
                                                  style: TextStyle(
                                                    fontFamily: 'Fredoka',
                                                    fontSize: isTablet
                                                        ? TabletLayout.studentListPopupBtnFontSize
                                                        : 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isTablet = false,
  }) {
    return InnerShadowContainer(
      height: isTablet ? TabletLayout.studentListPopupInputHeight : 45,
      borderRadius: 10,
      backgroundColor: const Color(0xFFE1D9CF),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTablet ? TabletLayout.studentListPopupInputFontSize : 14,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4A3E3D),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0x994A3E3D),
            fontSize: isTablet ? TabletLayout.studentListPopupInputFontSize : 14,
            fontFamily: 'Fredoka',
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _showHapusDialog(String siswaId, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Hapus Siswa?', style: TextStyle(fontFamily: 'Fredoka')),
        content: Text(
          'Yakin ingin menghapus data $nama? Data tidak bisa dikembalikan!',
          style: const TextStyle(fontFamily: 'Fredoka'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Fredoka')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseService().hapusSiswa(siswaId);
              await ProgressService().clearStudentData(siswaId);
              _loadStudents();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Siswa berhasil dihapus!',
                    style: TextStyle(fontFamily: 'Fredoka')),
                backgroundColor: Colors.green,
              ));
            },
            child: const Text('Hapus',
                style: TextStyle(fontFamily: 'Fredoka', color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDetailSiswaDialog(Map<String, dynamic> student) {
    final isPerempuan = student['jenisKelamin'] == 'perempuan';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isTablet = ResponsiveHelper.isTablet(screenWidth);
        final dialogWidth = isTablet
            ? (screenWidth * 0.88).clamp(320.0, TabletLayout.studentListPopupMaxWidth)
            : ResponsiveHelper.dialogWidth(screenWidth);
        final dialogPadding = isTablet
            ? const EdgeInsets.fromLTRB(
                TabletLayout.studentListPopupPaddingH,
                TabletLayout.studentListPopupPaddingTop,
                TabletLayout.studentListPopupPaddingH,
                TabletLayout.studentListPopupPaddingBottom,
              )
            : ResponsiveHelper.dialogPadding(screenWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: SizedBox(
              width: dialogWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Frame Background
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet
                          ? TabletLayout.studentListPopupMaxWidth
                          : 560,
                    ),
                    child: Image.asset(
                      'assets/images/template/frame_student_list.png',
                      width: dialogWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  ),

                  // 2. Konten Profil Siswa
                  Padding(
                    padding: dialogPadding,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/template/profile_avatar.png',
                                width: isTablet
                                    ? TabletLayout.studentListPopupAvatarFrameSize
                                    : 60,
                                height: isTablet
                                    ? TabletLayout.studentListPopupAvatarFrameSize
                                    : 60,
                              ),
                              Padding(
                                padding: EdgeInsets.all(isTablet ? 8 : 6),
                                child: Image.asset(
                                  isPerempuan
                                      ? 'assets/images/characters/Eva_char.png'
                                      : 'assets/images/characters/Eja_char.png',
                                  width: isTablet
                                      ? TabletLayout.studentListPopupAvatarCharSize
                                      : 44,
                                  height: isTablet
                                      ? TabletLayout.studentListPopupAvatarCharSize
                                      : 44,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            student['namaLengkap'] ?? '-',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? TabletLayout.studentListPopupTitleFontSize
                                  : 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              color: const Color(0xFF5A4FCF),
                            ),
                          ),
                          SizedBox(height: isTablet ? 14 : 10),
                          Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A4FCF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  'Username',
                                  student['username'] ?? '-',
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 8 : 6),
                                _buildDetailRow(
                                  'PIN Masuk',
                                  student['pin'] ?? '-',
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 8 : 6),
                                _buildDetailRow(
                                  'Usia',
                                  '${student['usia'] ?? '-'} Tahun',
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 8 : 6),
                                _buildDetailRow(
                                  'Jenis Kelamin',
                                  isPerempuan
                                      ? 'Perempuan 👧'
                                      : 'Laki-laki 👦',
                                  isTablet: isTablet,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 18 : 14),

                          // Tombol Hapus Siswa dalam Popup
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _showHapusDialog(
                                student['id'],
                                student['namaLengkap'] ?? '',
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 22 : 16,
                                vertical: isTablet
                                    ? TabletLayout.studentListPopupBtnPaddingV
                                    : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: isTablet ? 22 : 18,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hapus Siswa',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? TabletLayout.studentListPopupBtnFontSize
                                          : 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: Colors.red.shade700,
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

                  // 3. Tombol Tutup (Hanya Ikon ic_wrong di sudut kanan atas)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Image.asset(
                        AppImages.icWrong,
                        width: isTablet ? 44 : 36,
                        height: isTablet ? 44 : 36,
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

  Widget _buildDetailRow(String label, String value, {bool isTablet = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet
                ? TabletLayout.studentListPopupDetailLabelFontSize
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
                ? TabletLayout.studentListPopupDetailValueFontSize
                : 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
            color: const Color(0xFF2E7D32),
          ),
        ),
      ],
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
                    width: isTablet ? TabletLayout.studentListBackBtnWidth : 80,
                    height: isTablet ? TabletLayout.studentListBackBtnHeight : 44,
                  ),
                ),

                // 2. JUDUL HALAMAN
                Positioned(
                  top: screenHeight * (isTablet ? TabletLayout.studentListTitleTopFactor : 0.20),
                  left: screenWidth * (isTablet ? TabletLayout.studentListCenterHFactor : 0.23),
                  right: screenWidth * (isTablet ? TabletLayout.studentListCenterHFactor : 0.23),
                  child: Center(
                    child: Text(
                      'Daftar Siswa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? TabletLayout.studentListTitleFontSize : 24,
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
                ),

                // 3. SEARCH BAR (Posisi presisi di dalam papan)
                Positioned(
                  top: screenHeight * (isTablet ? TabletLayout.studentListSearchTopFactor : 0.26),
                  left: screenWidth * (isTablet ? TabletLayout.studentListCenterHFactor : 0.23),
                  right: screenWidth * (isTablet ? TabletLayout.studentListCenterHFactor : 0.23),
                  child: Container(
                    height: isTablet ? TabletLayout.studentListSearchHeight : 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(
                        isTablet ? TabletLayout.studentListSearchHeight / 2 : 16,
                      ),
                      border: Border.all(
                        color: const Color(0xFF81C784).withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (v) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Cari nama siswa...',
                        hintStyle: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: isTablet ? TabletLayout.studentListSearchFontSize : 13,
                          color: Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF2E7D32),
                          size: isTablet ? TabletLayout.studentListSearchIconSize : 20,
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
                        fontSize: isTablet ? TabletLayout.studentListSearchFontSize : 13,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),

                // 4. LIST SISWA (Scroll area pas di papan sesuai dashboard guru)
                Positioned(
                  top: screenHeight * (isTablet ? TabletLayout.studentListBodyTopFactor : 0.34),
                  bottom: screenHeight * (isTablet ? TabletLayout.studentListBodyBottomFactor : 0.31),
                  left: screenWidth * (isTablet ? TabletLayout.studentListCenterHFactor : 0.21),
                  right: screenWidth * (isTablet ? TabletLayout.studentListCenterHFactor : 0.21),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF5A4FCF)),
                          )
                        : _filteredStudents.isEmpty
                            ? Align(
                                alignment: const Alignment(0, -0.35),
                                child: Text(
                                  'Belum ada siswa terdaftar',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 15,
                                    fontFamily: 'Fredoka',
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                physics: const BouncingScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: isTablet
                                      ? TabletLayout.studentListGridSpacing
                                      : 10,
                                  crossAxisSpacing: isTablet
                                      ? TabletLayout.studentListGridSpacing
                                      : 10,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  final isPerempuan =
                                      student['jenisKelamin'] == 'perempuan';

                                  return GestureDetector(
                                    onTap: () =>
                                        _showDetailSiswaDialog(student),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9)
                                            .withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Avatar L/P
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/template/profile_avatar.png',
                                                width: isTablet
                                                    ? TabletLayout.studentListCardAvatarFrameSize
                                                    : 44,
                                                height: isTablet
                                                    ? TabletLayout.studentListCardAvatarFrameSize
                                                    : 44,
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(isTablet ? 8 : 6),
                                                child: Image.asset(
                                                  isPerempuan
                                                      ? 'assets/images/characters/Eva_char.png'
                                                      : 'assets/images/characters/Eja_char.png',
                                                  width: isTablet
                                                      ? TabletLayout.studentListCardAvatarCharSize
                                                      : 32,
                                                  height: isTablet
                                                      ? TabletLayout.studentListCardAvatarCharSize
                                                      : 32,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isTablet ? 10 : 8),

                                          // Nama siswa
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Text(
                                              student['namaLengkap'] ?? '',
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: isTablet
                                                    ? TabletLayout.studentListCardNameFontSize
                                                    : 13,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Fredoka',
                                                color: const Color(0xFF1B5E20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
                // 5. TOMBOL TAMBAH SISWA
                Positioned(
                  bottom: screenHeight * 0.1,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        bool isPressed = false;
                        return StatefulBuilder(
                          builder: (context, setBtnState) {
                            return GestureDetector(
                              onTapDown: (_) =>
                                  setBtnState(() => isPressed = true),
                              onTapUp: (_) {
                                setBtnState(() => isPressed = false);
                                _showTambahSiswaDialog();
                              },
                              onTapCancel: () =>
                                  setBtnState(() => isPressed = false),
                              child: AnimatedScale(
                                scale: isPressed ? 0.92 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet
                                        ? TabletLayout.studentListAddBtnPaddingH
                                        : 22,
                                    vertical: isTablet
                                        ? TabletLayout.studentListAddBtnPaddingV
                                        : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7B5C7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(isPressed ? 0.1 : 0.2),
                                        blurRadius: isPressed ? 4 : 8,
                                        offset: Offset(0, isPressed ? 2 : 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        AppImages.icAddStudent,
                                        width: isTablet
                                            ? TabletLayout.studentListAddIconSize
                                            : 28,
                                        height: isTablet
                                            ? TabletLayout.studentListAddIconSize
                                            : 28,
                                      ),
                                      SizedBox(width: isTablet ? 12 : 10),
                                      Text(
                                        'Tambah Siswa',
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? TabletLayout.studentListAddBtnFontSize
                                              : 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Fredoka',
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(
                                              blurRadius: 4,
                                              color: Colors.black26,
                                              offset: Offset(0, 2),
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
