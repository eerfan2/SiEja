// =============================================================================
// 🏫 TEACHER TABLET LAYOUT — Atur semua nilai tablet untuk HALAMAN GURU di sini.
// =============================================================================

class TeacherTabletLayout {
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
  // 🏫 TEACHER DASHBOARD SCREEN — Dashboard Guru
  // ===========================================================================

  // --- Posisi & Tata Letak Area ---
  /// Posisi atas header & stats (fraksi screenHeight). HP: 0.20
  static const double teacherDashHeaderTopFactor = 0.20;

  /// Batas kiri/kanan header (fraksi screenWidth). HP: 0.22
  static const double teacherDashHeaderHFactor = 0.22;

  /// Posisi atas area scroll menu (fraksi screenHeight). HP: 0.42
  static const double teacherDashMenuTopFactor = 0.38;

  /// Batas bawah area scroll menu (fraksi screenHeight). HP: 0.28
  static const double teacherDashMenuBottomFactor = 0.30;

  /// Batas kiri/kanan area scroll menu (fraksi screenWidth). HP: 0.20
  static const double teacherDashMenuHFactor = 0.22;

  // --- Header Guru (Foto, Nama, Notifikasi, Pengaturan) ---
  /// Ukuran foto profil guru di header. HP: 32
  static const double teacherDashAvatarSize = 44.0;

  /// Ukuran font greeting "Halo, Bu Guru!". HP: 16
  static const double teacherDashGreetingFontSize = 25.0;

  /// Ukuran font subtitle "Pantau perkembangan...". HP: 11
  static const double teacherDashSubtitleFontSize = 18.0;

  /// Ukuran ikon notifikasi & pengaturan. HP: 25
  static const double teacherDashHeaderIconSize = 50.0;

  // --- Kartu Statistik (Total Siswa, Sudah Belajar, Stage Aktif) ---
  /// Ukuran ikon di dalam kartu statistik. HP: 22
  static const double teacherDashStatIconSize = 30.0;

  /// Ukuran angka statistik (misal: 10, 5, 3). HP: 16
  static const double teacherDashStatValueFontSize = 22.0;

  /// Ukuran font label kartu statistik (misal: "Total Siswa"). HP: 10
  static const double teacherDashStatTitleFontSize = 14.0;

  /// Jarak antar kartu statistik. HP: 6
  static const double teacherDashStatSpacing = 10.0;

  // --- Menu Pilihan (Buka Stage, Progress, Daftar Siswa, Reset) ---
  /// Padding vertikal menu item. HP: 10
  static const double teacherDashMenuPaddingV = 19.0;

  /// Padding horizontal menu item. HP: 12
  static const double teacherDashMenuPaddingH = 16.0;

  /// Ukuran ikon menu di sebelah kiri. HP: 24
  static const double teacherDashMenuIconSize = 32.0;

  /// Ukuran font judul menu. HP: 13
  static const double teacherDashMenuTitleFontSize = 16.0;

  /// Ukuran font subtitle menu. HP: 11
  static const double teacherDashMenuSubtitleFontSize = 13.0;

  /// Ukuran ikon panah chevron kanan. HP: 20
  static const double teacherDashMenuChevronSize = 26.0;

  /// Jarak vertikal antar item menu. HP: 8
  static const double teacherDashMenuItemSpacing = 12.0;

  // --- Tombol Keluar (Logout) di Dashboard Guru ---
  /// Padding vertikal tombol Keluar. HP: 12
  static const double teacherDashLogoutPaddingV = 14.0;

  /// Ukuran ikon logout. HP: 22
  static const double teacherDashLogoutIconSize = 28.0;

  /// Ukuran font teks "Keluar". HP: 15
  static const double teacherDashLogoutFontSize = 18.0;

  // --- Pop-up Konfirmasi Keluar (Logout Dialog) ---
  /// Lebar maksimal pop-up konfirmasi keluar di tablet. HP: 560
  static const double teacherLogoutPopupMaxWidth = 480.0;

  /// Padding atas pop-up keluar agar pas di bingkai. HP: 55
  static const double teacherLogoutPopupPaddingTop = 60.0;

  /// Padding horizontal pop-up keluar. HP: 40
  static const double teacherLogoutPopupPaddingH = 48.0;

  /// Padding bawah pop-up keluar. HP: 36
  static const double teacherLogoutPopupPaddingBottom = 40.0;

  /// Ukuran font judul "Keluar? 🚪". HP: 20
  static const double teacherLogoutPopupTitleFontSize = 28.0;

  /// Ukuran font pertanyaan/penjelasan keluar. HP: 14
  static const double teacherLogoutPopupSubtitleFontSize = 18.0;

  /// Padding horizontal tombol aksi (Batal & Keluar). HP: 18
  static const double teacherLogoutPopupBtnPaddingH = 34.0;

  /// Padding vertikal tombol aksi (Batal & Keluar). HP: 7
  static const double teacherLogoutPopupBtnPaddingV = 13.0;

  /// Ukuran font teks tombol (Batal & Keluar). HP: 13
  static const double teacherLogoutPopupBtnFontSize = 18.0;

  // ===========================================================================
  // 🔓 UNLOCK LEVEL / KELOLA STAGE SCREEN — Atur ukuran & posisi khusus Tablet
  // ===========================================================================

  // --- Posisi & Tata Letak Area ---
  /// Posisi atas judul banner "Kelola Stage Siswa" (fraksi screenHeight). HP: 0.16
  static const double unlockStageTitleTopFactor = 0.16;

  /// Batas kiri/kanan judul banner (fraksi screenWidth). HP: 0.21
  static const double unlockStageTitleHFactor = 0.22;

  /// Posisi atas area scroll list stage (fraksi screenHeight). HP: 0.25
  static const double unlockStageListTopFactor = 0.26;

  /// Batas bawah area scroll list stage (fraksi screenHeight). HP: 0.31
  static const double unlockStageListBottomFactor = 0.28;

  /// Batas kiri/kanan area scroll list stage (fraksi screenWidth). HP: 0.21
  static const double unlockStageListHFactor = 0.22;

  // --- Banner Judul "Kelola Stage Siswa" ---
  /// Ukuran ikon badge di banner judul. HP: 24
  static const double unlockStageTitleIconSize = 32.0;

  /// Ukuran font teks judul "Kelola Stage Siswa". HP: 16
  static const double unlockStageTitleFontSize = 22.0;

  /// Padding horizontal banner judul. HP: 16
  static const double unlockStageTitlePaddingH = 22.0;

  /// Padding vertikal banner judul. HP: 8
  static const double unlockStageTitlePaddingV = 12.0;

  // --- Kotak / Kartu Stage ---
  /// Padding di dalam kotak stage. HP: 14
  static const double unlockStageCardPadding = 20.0;

  /// Jarak vertikal antar kotak stage. HP: 12
  static const double unlockStageCardMarginBottom = 16.0;

  /// Ukuran ikon stage (nomor/gembok/bintang). HP: 50
  static const double unlockStageIconSize = 68.0;

  /// Ukuran font nama stage & materi (misal: "Stage 1 — Materi..."). HP: 13
  static const double unlockStageNameFontSize = 18.0;

  /// Ukuran font info progress siswa (misal: "Selesai 0 / 5 anak"). HP: 11
  static const double unlockStageProgressFontSize = 15.0;

  /// Skala tombol switch toggle (1.0 = normal). HP: 1.0
  static const double unlockStageSwitchScale = 1.25;

  /// Ukuran font label status di bawah switch ("🔓 Terbuka" / "🔒 Terkunci"). HP: 11
  static const double unlockStageStatusFontSize = 14.0;

  // --- Tombol Back (Pojok Kiri Atas) ---
  /// Lebar tombol Back. HP: 80
  static const double unlockStageBackBtnWidth = 90.0;

  /// Tinggi tombol Back. HP: 44
  static const double unlockStageBackBtnHeight = 50.0;

  // ===========================================================================
  // 📊 PROGRESS REPORT SCREEN — Laporan Progress Siswa
  // ===========================================================================

  // --- Posisi & Tata Letak Area ---
  /// Posisi atas judul "Progress Siswa" (fraksi screenHeight). HP: 0.20
  static const double progressTitleTopFactor = 0.20;

  /// Batas kiri/kanan judul (fraksi screenWidth). HP: 0.23
  static const double progressTitleHFactor = 0.22;

  /// Posisi atas Search Bar (fraksi screenHeight). HP: 0.26
  static const double progressSearchTopFactor = 0.26;

  /// Batas kiri/kanan Search Bar (fraksi screenWidth). HP: 0.23
  static const double progressSearchHFactor = 0.22;

  /// Posisi atas area scroll list siswa (fraksi screenHeight). HP: 0.34
  static const double progressListTopFactor = 0.34;

  /// Batas bawah area scroll list siswa (fraksi screenHeight). HP: 0.31
  static const double progressListBottomFactor = 0.28;

  /// Batas kiri/kanan area scroll list siswa (fraksi screenWidth). HP: 0.21
  static const double progressListHFactor = 0.22;

  // --- Judul & Search Bar ---
  /// Ukuran font teks judul "Progress Siswa". HP: 20
  static const double progressTitleFontSize = 26.0;

  /// Tinggi kotak Search Bar. HP: 42
  static const double progressSearchHeight = 50.0;

  /// Ukuran font teks di Search Bar. HP: 13
  static const double progressSearchFontSize = 16.0;

  /// Ukuran ikon search di Search Bar. HP: 20
  static const double progressSearchIconSize = 24.0;

  // --- Kartu Progress Siswa (List di Papan) ---
  /// Padding vertikal kartu siswa. HP: 12
  static const double progressCardPaddingV = 16.0;

  /// Padding horizontal kartu siswa. HP: 16
  static const double progressCardPaddingH = 20.0;

  /// Jarak vertikal antar kartu siswa. HP: 10
  static const double progressCardMarginBottom = 14.0;

  /// Ukuran font nama siswa di kartu. HP: 15
  static const double progressCardNameFontSize = 19.0;

  /// Ukuran font info progress siswa (Stage aktif / remedial). HP: 11
  static const double progressCardInfoFontSize = 14.0;

  /// Ukuran font teks tombol "Detail". HP: 11
  static const double progressCardDetailFontSize = 14.0;

  /// Ukuran ikon chevron di tombol "Detail". HP: 16
  static const double progressCardDetailChevronSize = 22.0;

  /// Padding vertikal tombol "Detail". HP: 6
  static const double progressCardDetailPaddingV = 8.0;

  /// Padding horizontal tombol "Detail". HP: 10
  static const double progressCardDetailPaddingH = 14.0;

  // --- Pop-up Detail Progress Siswa (Dialog) ---
  /// Lebar maksimal pop-up di tablet. HP: 560
  static const double progressPopupMaxWidth = 620.0;

  /// Padding atas pop-up agar pas di dalam bingkai template. HP: 80
  static const double progressPopupPaddingTop = 150.0;

  /// Padding horizontal pop-up. HP: 36
  static const double progressPopupPaddingH = 65.0;

  /// Padding bawah pop-up. HP: 36
  static const double progressPopupPaddingBottom = 50.0;

  /// Ukuran font judul nama siswa di pop-up. HP: 18
  static const double progressPopupTitleFontSize = 24.0;

  /// Ukuran font subtitle/remedial di pop-up. HP: 11
  static const double progressPopupSubtitleFontSize = 15.0;

  /// Padding vertikal kotak item stage di pop-up. HP: 8
  static const double progressPopupStagePaddingV = 12.0;

  /// Padding horizontal kotak item stage di pop-up. HP: 12
  static const double progressPopupStagePaddingH = 16.0;

  /// Jarak vertikal antar kotak stage di pop-up. HP: 8
  static const double progressPopupStageMarginBottom = 10.0;

  /// Ukuran ikon stage di pop-up. HP: 32
  static const double progressPopupStageIconSize = 44.0;

  /// Ukuran font nama stage di pop-up ("Stage 1", dst). HP: 13
  static const double progressPopupStageTitleFontSize = 17.0;

  /// Ukuran font tag "⚠️ Perlu Remedial" di pop-up. HP: 10
  static const double progressPopupStageRemedialFontSize = 13.0;

  /// Tinggi progress indicator bar di pop-up. HP: 6
  static const double progressPopupProgressHeight = 9.0;

  /// Ukuran font skor stage ("100 pts" / "🔒") di pop-up. HP: 13
  static const double progressPopupStageScoreFontSize = 17.0;

  // --- Tombol Tutup & Tombol Silang Pop-up Detail Progress ---
  /// Jarak bawah tombol "Tutup" (Makin besar nilainya, tombol makin NAIK ke atas). HP: 0
  static const double progressPopupCloseBtnBottomMargin = 28.0;

  /// Padding tombol "Tutup"
  static const double progressPopupCloseBtnPaddingV = 10.0;
  static const double progressPopupCloseBtnPaddingH = 44.0;
  static const double progressPopupCloseBtnFontSize = 18.0;

  /// Posisi & Ukuran Tombol Silang Pojok Kanan Atas
  static const double progressPopupCloseIconSize = 50.0;
  static const double progressPopupCloseIconTop = 40.0;
  static const double progressPopupCloseIconRight = 40.0;

  // --- Tombol Back ---
  /// Lebar tombol Back. HP: 80
  static const double progressBackBtnWidth = 90.0;

  /// Tinggi tombol Back. HP: 44
  static const double progressBackBtnHeight = 50.0;

  // ===========================================================================
  // 👥 STUDENT LIST SCREEN — Daftar Siswa (Kelola Siswa Guru)
  // ===========================================================================

  // --- Posisi & Tata Letak Area ---
  /// Posisi vertikal judul halaman (fraksi dari tinggi layar). HP: 0.20
  static const double studentListTitleTopFactor = 0.20;

  /// Batas kiri/kanan judul & search bar (fraksi screenWidth). HP: 0.23
  static const double studentListCenterHFactor = 0.23;

  /// Posisi vertikal search bar (fraksi dari tinggi layar). HP: 0.26
  static const double studentListSearchTopFactor = 0.26;

  /// Posisi atas list siswa (fraksi dari tinggi layar). HP: 0.33
  static const double studentListBodyTopFactor = 0.33;

  /// Batas bawah area scroll list siswa (fraksi screenHeight). HP: 0.31
  static const double studentListBodyBottomFactor = 0.28;

  /// Tinggi kotak Search Bar. HP: 42
  static const double studentListSearchHeight = 50.0;

  /// Ukuran ikon search di Search Bar. HP: 20
  static const double studentListSearchIconSize = 24.0;

  /// Judul halaman "Daftar Siswa". HP: 24
  static const double studentListTitleFontSize = 24.0;

  /// Teks hint search bar. HP: 13
  static const double studentListSearchFontSize = 13.0;

  // --- Kartu Siswa di Grid (Avatar & Nama) ---
  /// Ukuran bingkai lingkaran avatar di kartu grid. HP: 44
  static const double studentListCardAvatarFrameSize = 74.0;

  /// Ukuran karakter avatar di dalam bingkai. HP: 32
  static const double studentListCardAvatarCharSize = 50.0;

  /// Nama siswa di kartu grid. HP: 13
  static const double studentListCardNameFontSize = 13.0;

  /// Username siswa di kartu grid. HP: 11
  static const double studentListCardUsernameFontSize = 11.0;

  /// Jarak antar kartu grid. HP: 10
  static const double studentListGridSpacing = 14.0;

  // --- Tombol "Tambah Siswa" (Bawah Tengah) ---
  /// Ukuran ikon "+" di tombol Tambah Siswa. HP: 28
  static const double studentListAddIconSize = 28.0;

  /// Font size teks "Tambah Siswa". HP: 15
  static const double studentListAddBtnFontSize = 15.0;

  /// Padding horizontal tombol "Tambah Siswa". HP: 22
  static const double studentListAddBtnPaddingH = 52.0;

  /// Padding vertikal tombol "Tambah Siswa". HP: 12
  static const double studentListAddBtnPaddingV = 20.0;

  // --- Tombol Back ---
  /// Lebar tombol Back. HP: 80
  static const double studentListBackBtnWidth = 80.0;

  /// Tinggi tombol Back. HP: 44
  static const double studentListBackBtnHeight = 44.0;

  // --- Pop-up Dialog Siswa (Tambah Siswa & Detail Siswa) ---
  /// Lebar maksimal pop-up di tablet. HP: 560
  static const double studentListPopupMaxWidth = 620.0;

  /// Padding atas pop-up agar pas di dalam bingkai template. HP: 80
  static const double studentListPopupPaddingTop = 150.0;

  /// Padding horizontal pop-up. HP: 36
  static const double studentListPopupPaddingH = 65.0;

  /// Padding bawah pop-up. HP: 36
  static const double studentListPopupPaddingBottom = 50.0;

  /// Ukuran font judul di pop-up ("Tambah Siswa Baru" / Nama Siswa). HP: 20/18
  static const double studentListPopupTitleFontSize = 24.0;

  /// Tinggi input field / dropdown / PIN box di pop-up. HP: 45
  static const double studentListPopupInputHeight = 52.0;

  /// Font size teks input field / dropdown di pop-up. HP: 14
  static const double studentListPopupInputFontSize = 16.0;

  /// Ukuran bingkai avatar di pop-up detail siswa. HP: 60
  static const double studentListPopupAvatarFrameSize = 95.0;

  /// Ukuran karakter avatar di pop-up detail siswa. HP: 44
  static const double studentListPopupAvatarCharSize = 65.0;

  /// Font size label baris detail (Username, PIN, dll). HP: 12
  static const double studentListPopupDetailLabelFontSize = 15.0;

  /// Font size nilai baris detail. HP: 13
  static const double studentListPopupDetailValueFontSize = 16.0;

  /// Font size tombol aksi di pop-up (Batal / Simpan / Hapus). HP: 14/12
  static const double studentListPopupBtnFontSize = 16.0;

  /// Padding vertikal tombol aksi di pop-up. HP: 12/8
  static const double studentListPopupBtnPaddingV = 14.0;

  /// Ukuran tombol close silang pop-up daftar siswa. HP: 32
  static const double studentListCloseBtnSize = 42.0;

  // ===========================================================================
  // 🔄 RESET PROGRESS POPUP (Dashboard Guru)
  // ===========================================================================
  /// Lebar maksimal pop-up reset di tablet. HP: 560
  static const double teacherResetPopupMaxWidth = 620.0;

  /// Padding atas pop-up reset. HP: 80
  static const double teacherResetPopupPaddingTop = 170.0;

  /// Padding horizontal pop-up reset. HP: 36
  static const double teacherResetPopupPaddingH = 65.0;

  /// Padding bawah pop-up reset. HP: 36
  static const double teacherResetPopupPaddingBottom = 50.0;

  /// Ukuran font judul "Reset Progress Siswa". HP: 18
  static const double teacherResetPopupTitleFontSize = 24.0;

  /// Ukuran font subtitle pop-up reset. HP: 12
  static const double teacherResetPopupSubtitleFontSize = 15.0;

  /// Ukuran font tombol mode ("Semua Siswa" / "Siswa Tertentu"). HP: 12
  static const double teacherResetPopupModeBtnFontSize = 15.0;

  /// Padding vertikal tombol mode. HP: 8
  static const double teacherResetPopupModeBtnPaddingV = 12.0;

  /// Tinggi dropdown pilih siswa di pop-up reset. HP: 45
  static const double teacherResetPopupDropdownHeight = 52.0;

  /// Font size dropdown siswa di pop-up reset. HP: 13
  static const double teacherResetPopupDropdownFontSize = 16.0;

  /// Ukuran ikon stage di grid reset per-stage. HP: 32
  static const double teacherResetPopupStageIconSize = 44.0;

  /// Font size judul stage di grid reset ("Stage 1", dst). HP: 11
  static const double teacherResetPopupStageTitleFontSize = 14.0;

  /// Font size skor/status di grid reset. HP: 9
  static const double teacherResetPopupStageScoreFontSize = 12.0;

  /// Font size tombol eksekusi reset ("Reset Semua Siswa", dll). HP: 13
  static const double teacherResetPopupActionBtnFontSize = 17.0;

  /// Padding vertikal tombol eksekusi reset. HP: 10
  static const double teacherResetPopupActionBtnPaddingV = 14.0;

  /// Padding horizontal tombol eksekusi reset. HP: 24
  static const double teacherResetPopupActionBtnPaddingH = 32.0;

  /// Ukuran ikon di tombol eksekusi reset. HP: 18
  static const double teacherResetPopupActionIconSize = 24.0;

  /// Ukuran tombol close silang pop-up reset. HP: 32
  static const double teacherResetPopupCloseBtnSize = 42.0;

  // ===========================================================================
  // 🔔 NOTIFICATION POPUP (Dashboard Guru)
  // ===========================================================================
  /// Lebar maksimal pop-up notifikasi di tablet. HP: 560
  static const double teacherNotifPopupMaxWidth = 620.0;

  /// Padding atas pop-up notifikasi agar pas di dalam bingkai template. HP: 80
  static const double teacherNotifPopupPaddingTop = 170.0;

  /// Padding horizontal pop-up notifikasi. HP: 36
  static const double teacherNotifPopupPaddingH = 65.0;

  /// Padding bawah pop-up notifikasi. HP: 36
  static const double teacherNotifPopupPaddingBottom = 50.0;

  /// Ukuran font judul "Pemberitahuan". HP: 18
  static const double teacherNotifPopupTitleFontSize = 24.0;

  /// Ukuran ikon notifikasi di header judul popup. HP: 24
  static const double teacherNotifPopupHeaderIconSize = 30.0;

  /// Ukuran ikon stage di item notifikasi. HP: 32
  static const double teacherNotifPopupStageIconSize = 42.0;

  /// Ukuran font teks pesan notifikasi. HP: 12
  static const double teacherNotifPopupItemFontSize = 15.0;

  /// Padding horizontal kartu item notifikasi. HP: 12
  static const double teacherNotifPopupItemPaddingH = 16.0;

  /// Padding vertikal kartu item notifikasi. HP: 10
  static const double teacherNotifPopupItemPaddingV = 14.0;

  /// Ukuran tombol tutup silang pop-up notifikasi. HP: 32
  static const double teacherNotifPopupCloseBtnSize = 42.0;

  // ===========================================================================
  // ⚙️ SETTINGS SCREEN & TENTANG APLIKASI (Guru & Umum)
  // ===========================================================================
  /// Ukuran font judul "Pengaturan". HP: 24
  static const double settingsTitleFontSize = 32.0;

  /// Ukuran tombol back di halaman pengaturan (Lebar). HP: 80
  static const double settingsBackBtnWidth = 100.0;

  /// Ukuran tombol back di halaman pengaturan (Tinggi). HP: 44
  static const double settingsBackBtnHeight = 55.0;

  /// Padding horizontal kartu menu (Musik Latar, Tentang Aplikasi). HP: 16
  static const double settingsCardPaddingH = 22.0;

  /// Padding vertikal kartu menu. HP: 12
  static const double settingsCardPaddingV = 16.0;

  /// Jarak bawah antar kartu menu. HP: 12
  static const double settingsCardMarginBottom = 16.0;

  /// Ukuran ikon pada kartu menu (Musik & Info). HP: 36
  static const double settingsCardIconSize = 48.0;

  /// Ukuran font judul kartu ("Musik Latar", "Tentang Aplikasi"). HP: 15
  static const double settingsCardTitleFontSize = 20.0;

  /// Ukuran font subtitle kartu ("Musik menyala / dimatikan"). HP: 11
  static const double settingsCardSubtitleFontSize = 15.0;

  /// Skala ukuran tombol Switch Musik Latar di tablet. HP: 1.0
  static const double settingsSwitchScale = 1.25;

  /// Tinggi tombol Keluar Akun / Ganti Role di setting murid. HP: 48
  static const double settingsExitBtnHeight = 60.0;

  // --- Pop-up Dialog "Tentang Aplikasi" ---
  /// Lebar maksimal pop-up Tentang Aplikasi di tablet. HP: 560
  static const double settingsAboutPopupMaxWidth = 620.0;

  /// Padding atas pop-up Tentang Aplikasi agar pas di bingkai template. HP: 80
  static const double settingsAboutPopupPaddingTop = 150.0;

  /// Padding horizontal pop-up Tentang Aplikasi. HP: 36
  static const double settingsAboutPopupPaddingH = 65.0;

  /// Padding bawah pop-up Tentang Aplikasi. HP: 36
  static const double settingsAboutPopupPaddingBottom = 50.0;

  /// Ukuran logo aplikasi di pop-up info. HP: 60
  static const double settingsAboutLogoSize = 80.0;

  /// Ukuran font judul "SiEja" di pop-up info. HP: 22
  static const double settingsAboutTitleFontSize = 28.0;

  /// Ukuran font versi "Versi 1.0" di pop-up info. HP: 12
  static const double settingsAboutVersionFontSize = 15.0;

  /// Ukuran font label info (Pengembang, Universitas, Tahun). HP: 12
  static const double settingsAboutLabelFontSize = 15.0;

  /// Ukuran font nilai info. HP: 12
  static const double settingsAboutValueFontSize = 16.0;

  /// Ukuran font deskripsi aplikasi di pop-up info. HP: 11
  static const double settingsAboutDescFontSize = 14.0;

  /// Ukuran tombol tutup silang pop-up Tentang Aplikasi. HP: 36
  static const double settingsAboutCloseBtnSize = 42.0;

  // ===========================================================================
  // 🔐 LOGIN GURU / UMUM
  // ===========================================================================
  /// Lebar container bingkai login di tablet (px).
  static const double loginFrameWidth = 500.0;

  /// Jarak atas konten dari bingkai (fraksi layoutWidth). HP: 0.23
  static const double loginContentTopFactor = 0.23;

  /// Margin kiri konten dalam bingkai (fraksi layoutWidth). HP: 0.15
  static const double loginContentLeftFactor = 0.15;

  /// Margin kanan konten dalam bingkai (fraksi layoutWidth). HP: 0.15
  static const double loginContentRightFactor = 0.15;

  /// Lebar tombol Login (fraksi layoutWidth). HP: 0.30
  static const double loginButtonWidthFactor = 0.30;

  /// Judul "LOGIN GURU". HP: 19–20
  static const double loginTitleFontSize = 19.0;

  /// Teks di dalam TextField. HP: 14
  static const double loginFieldFontSize = 14.0;

  /// Hint text di dalam TextField. HP: 14
  static const double loginHintFontSize = 14.0;

  /// Teks pesan error login. HP: 12
  static const double loginErrorFontSize = 12.0;

  /// Tinggi input field. HP: 45
  static const double loginFieldHeight = 45.0;

  /// Radius sudut input field. HP: 10
  static const double loginFieldRadius = 10.0;

  /// Ukuran ikon tombol Back (pojok kiri atas). HP: 48×48
  static const double loginBackBtnSize = 48.0;

  /// Lebar tombol Offline/Tanpa Akun. HP: 90
  static const double loginOfflineBtnWidth = 145.0;

  /// Font label "Tanpa Akun" di bawah tombol offline. HP: 10
  static const double loginOfflineLabelFontSize = 16.0;
}

/// Alias TabletLayout untuk kompatibilitas penuh kode yang sudah ada
typedef TabletLayout = TeacherTabletLayout;
