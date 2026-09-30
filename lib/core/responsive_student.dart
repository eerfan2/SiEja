// =============================================================================
// 🎒 STUDENT TABLET LAYOUT — Atur semua nilai tablet untuk HALAMAN SISWA di sini.
//    Nilai HP tidak disentuh. Semua screen siswa memilih StudentTabletLayout.xxx
//    hanya jika ResponsiveHelper.isTablet() == true.
// =============================================================================

class StudentTabletLayout {
  // ===========================================================================
  // 📺 SELECT ROLE SCREEN — Halaman Pilih Peran (Siswa / Guru)
  // ===========================================================================
  /// Lebar area tombol Siswa & Guru di tablet (px).
  static const double selectRoleLayoutWidth = 500.0;

  /// Posisi vertikal tombol Siswa (fraksi dari tinggi layar).
  static const double selectRoleStudentTopFactor = 0.35;

  /// Posisi vertikal tombol Guru (fraksi dari tinggi layar).
  static const double selectRoleTeacherTopFactor = 0.65;

  // ===========================================================================
  // 🔐 LOGIN SISWA (Online & Offline)
  // ===========================================================================
  /// Lebar container bingkai login di tablet (px).
  static const double loginFrameWidth = 680.0;

  /// Jarak atas konten dari bingkai (fraksi layoutWidth). HP: 0.23
  static const double loginContentTopFactor = 0.23;

  /// Margin kiri konten dalam bingkai (fraksi layoutWidth). HP: 0.15
  static const double loginContentLeftFactor = 0.15;

  /// Margin kanan konten dalam bingkai (fraksi layoutWidth). HP: 0.15
  static const double loginContentRightFactor = 0.15;

  /// Lebar tombol Login (fraksi layoutWidth). HP: 0.30
  static const double loginButtonWidthFactor = 0.32;

  /// Judul "LOGIN SISWA". HP: 19–20
  static const double loginTitleFontSize = 26.0;

  /// Teks di dalam TextField (username, PIN). HP: 14
  static const double loginFieldFontSize = 18.0;

  /// Hint text di dalam TextField. HP: 14
  static const double loginHintFontSize = 18.0;

  /// Teks pesan error login. HP: 12
  static const double loginErrorFontSize = 15.0;

  /// Tinggi input field (username/PIN). HP: 45
  static const double loginFieldHeight = 56.0;

  /// Radius sudut input field. HP: 10
  static const double loginFieldRadius = 14.0;

  /// Ukuran ikon tombol Back (pojok kiri atas). HP: 48×48
  static const double loginBackBtnSize = 64.0;

  /// Lebar tombol Offline/Tanpa Akun. HP: 90
  static const double loginOfflineBtnWidth = 145.0;

  /// Font label "Tanpa Akun" di bawah tombol offline. HP: 10
  static const double loginOfflineLabelFontSize = 16.0;

  // ===========================================================================
  // 🏠 STUDENT DASHBOARD SCREEN — Dashboard Siswa (Online & Offline)
  // ===========================================================================

  // --- Header Nametag & Avatar Siswa (Atas) ---
  /// Posisi atas header nametag (fraksi dari tinggi layar). HP: 0.04 (Makin besar, makin TURUN)
  static const double dashboardHeaderTopFactor = 0.065;

  /// Posisi kiri header nametag dari tepi layar (px). HP: 12
  static const double dashboardHeaderLeft = 20.0;

  /// Ukuran kotak avatar profil di header (px). HP: 55
  static const double dashboardAvatarSize = 75.0;

  /// Posisi atas avatar relatif terhadap nametag (px). HP: -8
  static const double dashboardAvatarTopOffset = -10.0;

  /// Tinggi nametag background kayu di header (px). HP: 44
  static const double dashboardNametagHeight = 58.0;

  /// Jarak kiri nametag dari avatar (px). HP: 28
  static const double dashboardNametagPaddingLeft = 38.0;

  /// Posisi kiri teks nama siswa di dalam nametag (px). HP: 56
  static const double dashboardNameTextLeft = 75.0;

  /// Ukuran font nama siswa di header nametag. HP: 13
  static const double dashboardNameFontSize = 18.0;

  // --- Grid Menu Belajar 2x2 (Tengah: Belajar Huruf, Mengeja Kata, Permainan, Progress) ---
  /// Posisi atas grid menu 2x2 (fraksi dari tinggi layar). HP: 0.35
  static const double dashboardGridTopFactor = 0.30;

  /// Padding kiri/kanan grid menu di tablet (px). HP: 16
  static const double dashboardGridHorizontalPadding = 60.0;

  /// Jarak horizontal antar kartu menu di grid (px). HP: 16
  static const double dashboardGridSpacingH = 24.0;

  /// Jarak vertikal antar kartu menu di grid (px). HP: 16
  static const double dashboardGridSpacingV = 24.0;

  /// Ukuran ikon menu di grid (Belajar Huruf, dll). HP: 110
  static const double dashboardMenuIconSize = 165.0;

  /// Ukuran font label menu di bawah ikon (Belajar Huruf, dll). HP: 16
  static const double dashboardMenuLabelFontSize = 25.0;

  // --- Navbar Bawah (Maskot, Profil, Pengaturan) ---
  /// Tinggi total area navbar di tablet. HP: 70
  static const double navbarTotalHeight = 110.0;

  /// Tinggi background gambar navbar di tablet. HP: 65
  static const double navbarBgHeight = 96.0;

  /// Jarak bawah ikon profil & pengaturan dari dasar layar. HP: 18
  static const double navbarIconBottom = 18.0;

  /// Ukuran tombol ikon Profil & Settings di navbar. HP: 38
  static const double navbarIconSize = 68.0;

  /// Ukuran maskot tengah di navbar. HP: 75
  static const double navbarMascotSize = 115.0;

  /// Jarak bawah maskot dari dasar layar. HP: 8
  static const double navbarMascotBottom = 10.0;

  /// Posisi ikon Profil di navbar: jarak dari kiri layar (fraksi screenWidth). HP: 0.15
  static const double navbarProfileLeftFactor = 0.15;

  /// Posisi ikon Settings di navbar: jarak dari kanan layar (fraksi screenWidth). HP: 0.15
  static const double navbarSettingsRightFactor = 0.15;

  // ===========================================================================
  // 🗺️ STAGE MAP / MATERI / GAME SISWA (Belajar Huruf, Suku Kata, Kata)
  // ===========================================================================
  // (Dapat ditambahkan saat kita mengatur tampilan map & game siswa)

  // ===========================================================================
  // ⚙️ STUDENT SETTINGS & EXIT POP-UP — Pengaturan & Pop-up Keluar Siswa
  // ===========================================================================
  /// Ukuran font judul "Pengaturan". HP: 24
  static const double settingsTitleFontSize = 32.0;

  /// Lebar tombol Back di pengaturan siswa. HP: 80
  static const double settingsBackBtnWidth = 120.0;

  /// Tinggi tombol Back di pengaturan siswa. HP: 44
  static const double settingsBackBtnHeight = 66.0;

  /// Padding horizontal kartu menu setting siswa. HP: 16
  static const double settingsCardPaddingH = 22.0;

  /// Padding vertikal kartu menu setting siswa. HP: 12
  static const double settingsCardPaddingV = 16.0;

  /// Ukuran font judul kartu ("Musik Latar", "Tentang Aplikasi"). HP: 15
  static const double settingsCardTitleFontSize = 20.0;

  /// Ukuran font subtitle kartu. HP: 11
  static const double settingsCardSubtitleFontSize = 15.0;

  /// Skala tombol Switch musik di tablet. HP: 1.0
  static const double settingsSwitchScale = 1.25;

  /// Tinggi tombol Keluar Akun / Ganti Role di setting murid. HP: 48
  static const double settingsExitBtnHeight = 60.0;

  // --- Pop-up Dialog Keluar / Ganti Role Siswa ---
  /// Lebar maksimal pop-up keluar di tablet. HP: 560
  static const double studentLogoutPopupMaxWidth = 480.0;

  /// Padding atas pop-up keluar siswa. HP: 55
  static const double studentLogoutPopupPaddingTop = 60.0;

  /// Padding horizontal pop-up keluar siswa. HP: 40
  static const double studentLogoutPopupPaddingH = 48.0;

  /// Padding bawah pop-up keluar siswa. HP: 36
  static const double studentLogoutPopupPaddingBottom = 40.0;

  /// Ukuran font judul "Keluar? 🚪". HP: 20
  static const double studentLogoutPopupTitleFontSize = 36.0;

  /// Ukuran font subtitle keluar siswa. HP: 14
  static const double studentLogoutPopupSubtitleFontSize = 22.0;

  /// Padding horizontal tombol aksi (Batal & Keluar). HP: 18
  static const double studentLogoutPopupBtnPaddingH = 34.0;

  /// Padding vertikal tombol aksi (Batal & Keluar). HP: 7
  static const double studentLogoutPopupBtnPaddingV = 13.0;

  /// Ukuran font teks tombol (Batal & Keluar). HP: 13
  static const double studentLogoutPopupBtnFontSize = 22.0;
}
