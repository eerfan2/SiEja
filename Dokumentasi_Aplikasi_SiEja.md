# DOKUMENTASI LENGKAP APLIKASI SIEJA
## (Sistem Informasi Edukasi Eja - Aplikasi Pembelajaran Mengeja Anak Berbasis Android)

---

## 1. PENDAHULUAN & DESKRIPSI PROYEK

**SiEja (Sistem Informasi Edukasi Eja)** adalah aplikasi *educational game (edutainment)* interaktif berbasis mobile Android yang dirancang khusus untuk membimbing anak-anak (tingkat PAUD / Sekolah Dasar) dalam belajar mengenal huruf, melafalkan bunyi, dan mengeja kata secara efektif dan menyenangkan.

Aplikasi ini mengintegrasikan teknologi **Flutter** untuk antarmuka pengguna *(client UI)* dan **Firebase Firestore** sebagai basis data *cloud real-time*, serta didukung oleh **SharedPreferences** untuk mode pembelajaran luring *(offline)* dan penyimpanan draf progres bermain.

### Keunggulan & Ciri Khas SiEja:
1. **Multi-Role User System**: Antarmuka terpisah antara **Siswa** (fokus belajar & mini-game) dan **Guru** (fokus manajemen siswa, kontrol stage, dan laporan progres).
2. **Auto-Fill PIN Slot Terkecil Kosong**: Algoritma pembuatan PIN siswa 3-digit yang secara cerdas mengisi slot PIN terkecil yang kosong/dihapus terlebih dahulu (misal jika PIN `001` dihapus, siswa baru otomatis mendapatkan PIN `001`).
3. **Penyimpanan Draf Soal (Anti-Cheat / Progress Saver)**: Jika siswa keluar aplikasi di tengah pengerjaan stage (melalui tombol Home, Back HP, atau keluar aplikasi), posisi soal terakhir dan skor sementara akan disimpan otomatis di memori lokal. Saat siswa kembali, game akan melanjutkan dari soal terakhir tanpa mengulang dari awal.
4. **Proteksi Navigasi Tombol Kembali HP**: Mendukung penuh *Predictive Back Gesture* Android 13/14+ dengan dialog konfirmasi keluar bertema visual visual `frame_login.png`.
5. **7 Tipe Variasi Mini-Game Pembelajaran**: Variasi permainan mengeja kata, mendengarkan audio huruf, menebak gambar objek, mencocokkan huruf, hingga mengurutkan alfabet.

---

## 2. SPESIFIKASI TEKNOLOGI & DEPENDENSI

### 2.1 Technology Stack
- **Framework Mobile**: Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- **Backend / Cloud Database**: Firebase Firestore (`cloud_firestore: ^4.15.5`)
- **Autentikasi**: Firebase Auth (`firebase_auth: ^4.17.6`) & Custom PIN System
- **Local Storage**: Shared Preferences (`shared_preferences: ^2.2.2`)
- **Audio Engine**: Audioplayers (`audioplayers: ^5.2.1`)
- **Routing & Navigation**: GoRouter (`go_router: ^13.2.0`)
- **Network Status**: Connectivity Plus (`connectivity_plus: ^5.0.2`)
- **Typography & Font**: Google Fonts (`google_fonts: ^6.1.0` - *Fredoka Font*)

---

## 3. STRUKTUR ARSITEKTUR KODE (DIRECTORY STRUCTURE)

Berikut adalah struktur direktori proyek SiEja:

```
SiEja/
├── android/                   # Konfigurasi Native Android (AndroidManifest.xml, MainActivity.kt)
├── assets/                    # Asset gambar, latar belakang, ikon, dan audio BGM/SFX
│   ├── audio/                 # BGM (bgm_home, bgm_game) & SFX (win, wrong, click, dll)
│   └── images/                # Framework UI, stage map, avatar, ikon guru/siswa
├── lib/
│   ├── main.dart              # Entry point aplikasi (Inisialisasi Firebase & ProgressService)
│   ├── app/
│   │   └── router.dart        # Konfigurasi GoRouter (Routing seluruh screen & PopScope)
│   ├── core/
│   │   └── app_constants.dart # Kostanta asset, gambar, audio, dan pemetaan huruf ke kata/objek
│   ├── services/
│   │   ├── firebase_service.dart      # Layanan CRUD Firestore & Autentikasi Guru/Siswa
│   │   ├── progress_service.dart      # Singleton cache local storage & Draf Progress
│   │   ├── audio_service.dart         # Singleton pengelola BGM & SFX audio
│   │   └── connectivity_service.dart  # Deteksi status koneksi internet (Online/Offline)
│   ├── widgets/
│   │   ├── asset_button.dart          # Custom Widget Button bermotif asset gambar dengan animasi press
│   │   ├── bg_scaffold.dart           # Custom Scaffold dengan gambar latar belakang dinamis
│   │   └── inner_shadow_container.dart# Custom Container dengan efek bayangan dalam (Inner Shadow)
│   └── screens/
│       ├── select_role_screen.dart    # Screen Pemilihan Peran (Siswa / Guru)
│       ├── student/                   # Rangkaian Screen Pembelajaran Siswa
│       │   ├── login_student_screen.dart
│       │   ├── student_dashboard_screen.dart
│       │   ├── offline_dashboard_screen.dart
│       │   ├── stage_map_screen.dart
│       │   ├── stage_screen.dart      # Engine Mini-Game (7 Tipe Permainan)
│       │   ├── learn_letter_screen.dart
│       │   ├── select_objek_screen.dart
│       │   ├── spell_guided_screen.dart
│       │   ├── spell_word_screen.dart
│       │   ├── profile_screen.dart / offline_profile_screen.dart
│       │   ├── settings_screen.dart / offline_settings_screen.dart
│       │   ├── progress_screen.dart
│       │   └── reward_screen.dart
│       └── teacher/                   # Rangkaian Screen Manajemen Guru
│           ├── login_teacher_screen.dart
│           ├── teacher_dashboard_screen.dart
│           ├── student_list_screen.dart # Manajemen Tambah/Hapus Siswa & PIN
│           ├── unlock_level_screen.dart # Kontrol Buka/Kunci Stage 1-6
│           ├── progress_report_screen.dart # Laporan Hasil Progres Seluruh Siswa
│           └── teacher_settings_screen.dart
├── erd_diagram.xml            # Diagram ERD format Draw.io XML
├── class_diagram.xml          # Diagram Kelas format Draw.io XML
├── activity_diagram_siswa.xml # Activity Diagram Siswa (3 Swimlanes Draw.io XML)
├── activity_diagram_guru.xml  # Activity Diagram Guru (3 Swimlanes Draw.io XML)
└── pubspec.yaml               # Manifest dependensi Flutter
```

---

## 4. FITUR UTAMA APLIKASI & LOGIKA SISTEM

### 4.1 Modul Siswa (Student Module)
1. **Autentikasi Siswa via PIN**: Siswa masuk menggunakan `Username` dan `PIN Otomatis` (3 digit, misal `001`).
2. **Peta Stage (Stage Map)**: Menampilkan 6 Stage secara berurutan. Stage 1 terbuka secara default, sedangkan Stage 2 sampai 6 akan terbuka jika siswa telah menyelesaikan stage sebelumnya ATAU dibuka langsung oleh Guru.
3. **Engine 7 Mini-Game Pembelajaran (`stage_screen.dart`)**:
   - `dengarSuaraHuruf`: Mendengarkan pengucapan audio huruf, lalu memilih huruf yang sesuai.
   - `tebakGambarObjek`: Mendengarkan nama kata/objek, lalu memilih gambar objek yang tepat.
   - `susunKata`: Menyusun abjad acak menjadi kata mengeja yang utuh.
   - `hurufYangHilang`: Mengisi huruf kosong yang hilang pada sebuah kata.
   - `hurufAwalApa`: Menebak huruf depan/awal dari sebuah gambar objek.
   - `cocokkanHuruf`: Mencocokkan huruf besar dan huruf kecil.
   - `urutkanHuruf`: Mengurutkan alfabet sesuai urutan abjad yang benar.
4. **Penyimpanan Draf Soal (Draft Progress)**:
   - Setiap kali siswa menjawab satu soal, draf posisi soal (`currentQuestionIndex`), skor sementara, dan urutan soal disimpan ke `SharedPreferences` via `saveDraftStageProgress()`.
   - Ketika siswa keluar dan masuk kembali ke stage tersebut, sistem membaca draf dan melanjutkan permainan dari soal terakhir yang ditinggalkan.
   - Setelah 10 soal selesai, draf otomatis dihapus (`clearDraftStageProgress()`) dan status stage diubah menjadi `completed` di Firestore.

### 4.2 Modul Guru (Teacher Module)
1. **Autentikasi Guru**: Guru masuk menggunakan akun terdaftar (`Username` & `Password`).
2. **Dashboard Guru & Ringkasan Statistik**:
   - **Total Siswa**: Jumlah siswa terdaftar di Firestore (menampilkan `0` jika seluruh siswa terhapus).
   - **Sudah Belajar**: Jumlah siswa yang telah menyelesaikan stage terbuka tertinggi.
   - **Stage Aktif**: Jumlah stage yang sedang terbuka (sinkron 100% dengan Halaman Kelola Stage).
   - **Notifikasi**: Menampilkan daftar notifikasi saat ada siswa yang menyelesaikan stage baru (dibagi kategori *Belum Dibaca* di atas dan *Sudah Dibaca* di bawah).
3. **Manajemen Daftar Siswa (`student_list_screen.dart`)**:
   - **Tambah Siswa**: Guru menginput Nama Lengkap, Username, Usia, dan Jenis Kelamin. PIN dibuat otomatis oleh fungsi `generatePin()` yang mencari angka PIN terkecil yang belum terpakai (mengisi slot kosong terlebih dahulu).
   - **Hapus Siswa**: Menghapus dokumen siswa di Firestore sekaligus memanggil `ProgressService().clearStudentData(siswaId)` untuk membersihkan seluruh cache nama, PIN, status stage, dan draf progres di memori HP.
4. **Kelola Stage / Buka Level (`unlock_level_screen.dart`)**:
   - Guru dapat mengunci atau membuka Stage 1 sampai 6 secara fleksibel.
   - Perubahan status stage akan langsung diperbarui ke seluruh dokumen siswa di Firestore (`unlockStageAllSiswa` / `lockStageAllSiswa`).
5. **Laporan Progres Siswa (`progress_report_screen.dart`)**:
   - Menampilkan daftar riil siswa terdaftar dari Firebase beserta total skor, stage aktif, dan status penyelesaian di tiap stage.
   - Dilengkapi fitur pencarian nama siswa (*real-time filter search*).

---

## 5. ALGORITMA UTAMA

### 5.1 Algoritma Auto-Fill PIN Slot Terkecil (`FirebaseService.generatePin`)
```dart
  Future<String> generatePin() async {
    try {
      final snapshot = await _firestore.collection('siswa').get();
      final existingPins = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pinStr = data['pin'] as String?;
        if (pinStr != null) {
          final pinInt = int.tryParse(pinStr);
          if (pinInt != null) {
            existingPins.add(pinInt);
          }
        }
      }

      int candidate = 1;
      while (existingPins.contains(candidate)) {
        candidate++;
      }

      return candidate.toString().padLeft(3, '0');
    } catch (e) {
      return '001';
    }
  }
```

### 5.2 Algoritma Pembersihan Cache Siswa Terhapus (`ProgressService.clearStudentData`)
```dart
  Future<void> clearStudentData(String siswaId) async {
    final curId = _prefs.getString('currentSiswaId') ?? '';
    if (_currentSiswaId == siswaId || curId == siswaId) {
      _currentSiswaId = '';
      _currentJenisKelamin = '';
      await _prefs.remove('currentSiswaId');
      await _prefs.remove('currentJenisKelamin');
      await _prefs.remove('student_name');
      await _prefs.remove('student_pin');
    }
    for (int i = 1; i <= 6; i++) {
      await _prefs.remove('score_${siswaId}_stage_$i');
      await _prefs.remove('status_${siswaId}_stage_$i');
      await _prefs.remove('draft_${siswaId}_stage_$i');
    }
  }
```

---

## 6. PANDUAN RUNNING & INSTALASI APLIKASI

### Prasyarat System Requirements:
- **Flutter SDK**: `>= 3.16.0`
- **Dart SDK**: `>= 3.2.0`
- **Android SDK**: API Level 34 (Android 14) atau lebih baru
- **Java JDK**: Version 17

### Langkah Menjalankan Aplikasi:

1. **Clone / Buka Repositori Project**:
   ```bash
   cd e:\Skripsi\projectskripsi\SiEja
   ```

2. **Instalasi Dependensi Pubspec**:
   ```bash
   flutter pub get
   ```

3. **Jalankan Pengecekan Sintaks & Analisis Kode**:
   ```bash
   flutter analyze
   ```

4. **Jalankan Aplikasi pada Emulator / HP Android**:
   ```bash
   flutter run
   ```

5. **Build APK Rilis (Production Bundle)**:
   ```bash
   flutter build apk --release
   ```

---

## 7. PENUTUP

Dokumentasi ini mencakup seluruh aspek arsitektur, algoritma, dependensi, dan panduan penggunaan aplikasi **SiEja**. Jika terdapat pembaruan fitur atau kebutuhan pengembangan lebih lanjut, silakan mengacu pada dokumen ini.
