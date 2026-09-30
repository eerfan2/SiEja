# 📖 Penjelasan Lengkap Aplikasi Edukasi "SiEja"
> **Sistem Informasi Edukasi Eja (SiEja)** — Aplikasi Pembelajaran Mengenal Huruf dan Mengeja Kata Berbasis Android & Gamifikasi untuk Anak Usia Dini (PAUD / TK).

---

## 📌 Daftar Isi
1. [Ringkasan Eksekutif & Latar Belakang](#1-ringkasan-eksekutif--latar-belakang)
2. [Tujuan & Pendekatan Pembelajaran](#2-tujuan--pendekatan-pembelajaran)
3. [Teknologi yang Digunakan (Tech Stack)](#3-teknologi-yang-digunakan-tech-stack)
4. [Arsitektur & Alur Sistem](#4-arsitektur--alur-sistem)
5. [Struktur Pengguna (Multi-Role System)](#5-struktur-pengguna-multi-role-system)
   - [5.1 Modul Siswa (Online & Offline)](#51-modul-siswa-online--offline)
   - [5.2 Modul Guru (Teacher Portal)](#52-modul-guru-teacher-portal)
6. [Mekanisme 7 Jenis Mini-Game Pembelajaran](#6-mekanisme-7-jenis-mini-game-pembelajaran)
7. [Desain UI/UX, Gamifikasi, & Responsivitas](#7-desain-uiux-gamifikasi--responsivitas)
8. [Struktur Data & Penyimpanan](#8-struktur-data--penyimpanan)
9. [Struktur Direktori & Penjelasan Kode](#9-struktur-direktori--penjelasan-kode)
10. [Panduan Instalasi & Menjalankan Aplikasi](#10-panduan-instalasi--menjalankan-aplikasi)

---

## 1. Ringkasan Eksekutif & Latar Belakang

**SiEja** merupakan aplikasi pembelajaran interaktif (*educational game/edutainment*) yang dikembangkan untuk anak-anak usia dini (usia 4–7 tahun / tingkat PAUD & TK). Aplikasi ini berfokus pada pengenalan alfabet bahasa Indonesia, fonik (bunyi huruf), pengenalan nama-nama objek/hewan, serta keterampilan menyusun dan mengeja kata secara terstruktur.

Dengan menggabungkan **pendekatan gamifikasi** (peta petualangan *stage*, bintang *reward*, suara penyemangat, dan visual animasi warna-warni) serta **sistem pemantauan guru** (*teacher monitoring system*), SiEja menjembatani proses belajar mandiri anak dengan evaluasi terukur oleh tenaga pengajar di sekolah.

---

## 2. Tujuan & Pendekatan Pembelajaran

### 🎯 Tujuan Utama:
1. **Meningkatkan Minat Literasi Dini**: Mengubah proses belajar mengeja yang kaku menjadi aktivitas bermain yang menyenangkan (*playful learning*).
2. **Mengenalkan Fonik & Simbol Huruf**: Mengaitkan bentuk huruf (visual), pelafalan bunyi huruf (auditori), dan contoh kata nyata sehari-hari (asosiasi kognitif).
3. **Melatih Kemampuan Motorik & Logika Urutan**: Melalui aktivitas drag-and-drop, menyusun kepingan abjad, melengkapi huruf hilang, dan mengurutkan alfabet.
4. **Memberikan Fasilitas Monitoring bagi Guru**: Guru dapat memantau progres belajar setiap anak secara *real-time*, melihat nilai capaian, mengidentifikasi anak yang mengalami kendala (*stuck*), serta mengatur pembukaan level stage.

### 🧠 Pendekatan Pembelajaran (*Pedagogical Framework*):
- **Metode Fonik (Phonics)**: Pelafalan bunyi huruf (A-Z) dan kata berulang melalui sulih suara (*voice-over*) interaktif.
- **Scaffolding / Bertingkat**: Dimulai dari pengenalan 1 huruf, tebak gambar, melengkapi huruf hilang, hingga menyusun kata utuh 4–7 huruf.
- **Immediate Feedback**: Umpan balik langsung berupa efek suara pujian (*"Hebat!", "Pintar!"*) saat benar dan dorongan semangat (*"Ayo coba lagi!"*) saat keliru tanpa membuat anak putus asa.

---

## 3. Teknologi yang Digunakan (Tech Stack)

| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Framework** | **Flutter SDK** (Dart) | Mendukung performa grafis 60 FPS yang responsif dan mulus |
| **State Management** | **Provider** | Pengelolaan state terpusat untuk servis progres, audio, dan konektivitas |
| **Routing & Navigasi** | **GoRouter** | Manajemen rute deklaratif dengan dukungan *deep-linking* dan *PopScope* pelindung |
| **Backend & Cloud DB** | **Firebase Cloud Firestore** | Penyimpanan basis data *real-time* untuk akun siswa, progres nilai, dan soal |
| **Autentikasi** | **Firebase Auth & Custom PIN** | Login Guru via Email/Password & Login Siswa via Username + 3-Digit PIN |
| **Local Storage & Cache**| **SharedPreferences** & **Sqflite** | Menyimpan draf permainan yang belum selesai (*anti-cheat / progress saver*) dan data offline |
| **Audio Engine** | **Audioplayers** | Pemutaran *Background Music (BGM)* latar dan *Sound Effect (SFX)* interaktif |
| **Network Monitor** | **Connectivity Plus** | Deteksi koneksi internet dinamis untuk beralih antara Mode Online dan Offline |
| **Tipografi** | **Fredoka Font** | Font bulat (*rounded sans-serif*) yang ramah dan mudah dibaca oleh anak-anak |

---

## 4. Arsitektur & Alur Sistem

Aplikasi SiEja dibangun menggunakan pola **Layered Architecture** (Presentation, Domain/Model, Service Layer) yang memisahkan logika bisnis dari tampilan antarmuka:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│    (Screens Siswa, Screens Guru, Reusable Custom Widgets)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────┐
│                       SERVICE LAYER                        │
│   • FirebaseService     (CRUD Firestore & Autentikasi)     │
│   • ProgressService     (Cache Lokal & Sinkronisasi Draf)  │
│   • AudioService        (BGM & SFX Engine)                 │
│   • ConnectivityService (Status Jaringan Online/Offline)   │
│   • StageComposer       (Pembangkit Soal Mini-Game)        │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────┐
│                      DATA & PERSISTENCE                     │
│    Cloud Firestore   │   SharedPreferences   │   SQLite    │
└─────────────────────────────────────────────────────────────┘
```

### 🔄 Alur Navigasi Utama:
1. **Splash Screen**: Memuat inisialisasi Firebase, mendeteksi koneksi jaringan, memeriksa status login terakhir.
2. **Halaman Pilih Peran (`SelectRoleScreen`)**: Memilih peran antara **Siswa** atau **Guru**.
3. **Pintu Masuk Siswa**:
   - **Mode Online**: Input *Username* dan *PIN 3-Digit* -> Masuk ke `StudentDashboardScreen`.
   - **Mode Offline**: Menekan tombol *"Belajar Offline"* -> Masuk ke `OfflineDashboardScreen` (tanpa perlu internet).
4. **Pintu Masuk Guru**:
   - Login dengan *Email* dan *Password* resmi -> Masuk ke `TeacherDashboardScreen`.

---

## 5. Struktur Pengguna (Multi-Role System)

### 5.1 Modul Siswa (Student Module)
Modul siswa dirancang dengan antarmuka visual penuh warna, teks besar, tombol interaktif bergambar, dan instruksi suara.

#### 🎮 Fitur-Fitur Siswa:
1. **Belajar Huruf (`LearnLetterScreen`)**:
   - Menampilkan papan huruf A sampai Z.
   - Setiap huruf dapat ditekan untuk mendengarkan pelafalan audionya, melihat kartu asosiasi kata bergambar (misal: **A** = Ayam, **B** = Bebek, **K** = Kucing).
2. **Mengeja Terbimbing (`SelectObjekScreen` & `SpellGuidedScreen`)**:
   - Siswa memilih objek bergambar yang diminati.
   - Aplikasi memandu siswa mengeja suku kata per huruf dengan bantuan visual dan audio panduan.
3. **Peta Petualangan Stage (`StageMapScreen`)**:
   - Terdiri dari **6 Level/Stage** petualangan bertahap.
   - Stage 1 terbuka secara bawaan (*default*). Stage berikutnya akan terbuka setelah siswa menuntaskan stage sebelumnya atau jika dibuka oleh guru.
4. **Stage Mini-Game (`StageScreen`)**:
   - Setiap stage menyajikan paket 10 soal interaktif dari kombinasi 7 jenis mini-game.
   - **Progress Draft Saver**: Jika anak keluar aplikasi secara tidak sengaja di tengah permainan, posisi nomor soal dan skor sementara tersimpan otomatis di perangkat. Saat kembali, anak melanjutkan langsung dari soal terakhir.
5. **Halaman Reward (`RewardScreen`)**:
   - Menampilkan skor akhir, jumlah perolehan bintang (⭐ 1–3), trofi perayaan, serta musik kemenangan gembira.
6. **Progres Belajar Siswa (`ProgressScreen`)**:
   - Melihat rekam jejak capaian bintang dan nilai per stage yang telah dituntaskan.
7. **Profil & Pengaturan Siswa (`ProfileScreen` & `SettingsScreen`)**:
   - Pengaturan volume musik latar (*BGM*) dan efek suara (*SFX*).
   - Memilih avatar karakter (Laki-laki / Perempuan).

---

### 5.2 Modul Guru (Teacher Portal)
Portal guru dirancang profesional untuk membantu tenaga pendidik mengelola kelas dan memantau kemajuan belajar murid.

#### 📊 Fitur-Fitur Guru:
1. **Dashboard Statistik Guru (`TeacherDashboardScreen`)**:
   - **Total Siswa Terdaftar**: Menghitung jumlah riil murid di kelas.
   - **Siswa Aktif / Sudah Belajar**: Menghitung siswa yang telah menyelesaikan stage terbuka tertinggi.
   - **Jumlah Stage Aktif**: Status keterbukaan stage yang sinkron dengan sistem.
   - **Siswa Perlu Perhatian / *Stuck***: Mendeteksi siswa yang belum menyelesaikan stage tertentu.
   - **Feed Notifikasi Aktivitas**: Log otomatis saat seorang siswa baru saja menyelesaikan suatu stage.
2. **Manajemen Data Siswa (`StudentListScreen`)**:
   - **Tambah Siswa dengan Algoritma Auto-PIN**: Guru hanya perlu mengisi nama, username, usia, dan gender. PIN 3 digit (misal: `001`, `002`) dibuat otomatis oleh sistem dengan mencari *slot angka terkecil yang kosong*.
   - **Edit & Hapus Siswa**: Menghapus data di cloud sekaligus membersihkan data cache lokal.
   - **Reset PIN & Progres Siswa**: Memudahkan guru mereset kata sandi atau mengulang nilai siswa.
3. **Kontrol Buka / Kunci Stage (`UnlockLevelScreen`)**:
   - Guru dapat membuka (*unlock*) atau mengunci (*lock*) Stage 1 s.d. Stage 6 untuk seluruh siswa secara massal maupun personal.
4. **Laporan Progres & Nilai Komprehensif (`ProgressReportScreen`)**:
   - Rekap nilai seluruh stage, skor rata-rata, persentase keberhasilan per stage, dilengkapi fitur pencarian siswa secara instan (*real-time search filter*).
5. **Pengaturan Akun Guru (`TeacherSettingsScreen`)**:
   - Informasi profil guru, ganti kata sandi, panduan bantuan, dan opsi *logout*.

---

## 6. Mekanisme 7 Jenis Mini-Game Pembelajaran

Aplikasi SiEja mengimplementasikan 7 tipe permainan pada modul `StageScreen` (`GameType`):

| No | Tipe Mini-Game (`enum GameType`) | Mekanisme & Cara Bermain | Aspek Kognitif yang Dilatih |
| :---: | :--- | :--- | :--- |
| **1** | `dengarSuaraHuruf` | Aplikasi memutar bunyi audio huruf tertentu (misal: *"Dengarkan suara huruf M"*). Siswa memilih salah satu dari pilihan kartu huruf yang tersedia. | Kepekaan auditori, pengenalan simbol fonik abjad. |
| **2** | `tebakGambarObjek` | Menampilkan kata atau suara nama objek, siswa diminta memilih gambar objek/hewan yang tepat di antara beberapa opsi gambar. | Asosiasi kata dengan representasi visual objek. |
| **3** | `susunKata` | Menampilkan gambar objek dan kepingan huruf acak. Siswa menyusun kepingan huruf tersebut ke kotak susunan kata hingga membentuk ejaan yang benar. | Keterampilan mengeja, sintesis kata, motorik halus. |
| **4** | `hurufYangHilang` | Menampilkan kata dengan 1 huruf yang dikosongkan (misal: `B _ B E K`). Siswa memilih huruf yang tepat untuk melengkapi kata tersebut. | Analisis struktur kata dan pemahaman suku kata. |
| **5** | `hurufAwalApa` | Menampilkan gambar objek (misal: gambar *Gajah*). Siswa menjawab pertanyaan huruf pertama dari nama benda tersebut (pilihan: `G`). | Pengenalan inisial huruf dan klasifikasi awal kata. |
| **6** | `cocokkanHuruf` | Siswa mencocokkan pasangan huruf besar (*Uppercase*) dengan huruf kecil (*Lowercase*), misal `A` dipasangkan dengan `a`. | Pengenalan bentuk huruf kapital dan huruf non-kapital. |
| **7** | `urutkanHuruf` | Menampilkan rangkaian huruf dalam rentang tertentu secara acak (misal: `C - A - B` atau rentang A-Z). Siswa mengurutkannya menjadi susunan alfabetik yang runut (`A - B - C`). | Pemahaman sekuensial dan urutan alfabetis. |

---

## 7. Desain UI/UX, Gamifikasi, & Responsivitas

### 🎨 Estetika Visual & Audio
- **Palet Warna Ceria**: Menggunakan gradasi warna pastel dan primer cerah (biru langit, hijau mint, kuning cerah, jingga) yang menstimulasi visual anak usia dini tanpa membuat mata lelah.
- **Tipografi Fredoka**: Font sans-serif yang membulat pada setiap ujungnya, memberikan kesan ramah anak (*child-friendly*) dan keterbacaan tinggi.
- **Efek Sentuhan & Animasi Tombol**: Seluruh tombol interaktif menggunakan `AssetButton` yang memiliki efek penekanan (*pressed state visual & tactile feel*).
- **Soundscape Interaktif**:
  - `bgm_home.mp3`: Musik beranda yang riang dan tenang.
  - `bgm_stage.mp3`: Musik pengerjaan kuis yang penuh semangat.
  - `feedback_benar.mp3` & `feedback_salah.mp3`: Umpan balik audio instan dari pengisi suara ramah.

### 📱 Optimasi Responsif (Smartphone & Tablet)
SiEja dilengkapi kelas arsitektur responsif terpisah:
- [responsive_student.dart](file:///e:/Skripsi/projectskripsi/SiEja/lib/core/responsive_student.dart): Mengatur tata letak kartu, jarak tombol, ukuran font, dan ukuran grid khusus tablet untuk halaman siswa.
- [responsive_teacher.dart](file:///e:/Skripsi/projectskripsi/SiEja/lib/core/responsive_teacher.dart): Mengatur tampilan dashboard guru, tabel laporan, dan dialog di smartphone maupun layar tablet lebar.
- **Lock Portrait**: Aplikasi dikunci pada orientasi tegak (*portrait*) demi konsistensi ergonomi genggaman anak-anak.

---

## 8. Struktur Data & Penyimpanan

### 8.1 Koleksi Cloud Firestore
1. **`siswa`**: Menyimpan data profil murid (`namaLengkap`, `username`, `pin`, `usia`, `jenisKelamin`, `progress`).
   ```json
   {
     "namaLengkap": "Ahmad Fauzi",
     "username": "ahmad",
     "pin": "001",
     "usia": 6,
     "jenisKelamin": "L",
     "progress": {
       "stage1": { "status": "completed", "score": 100, "stars": 3 },
       "stage2": { "status": "unlocked", "score": 0, "stars": 0 }
     }
   }
   ```
2. **`login_siswa`**: Indeks pemetaan login cepat berbasis hash kombinasi `username + pin` untuk autentikasi efisien tanpa perlu scan seluruh database.
3. **`soal`**: Bank data soal mini-game yang berisi `stageId`, `gameType`, `kata`, `huruf`, `isActive`, dan `letterSequenceConfig`.
4. **`notifikasi`**: Log penyelesaian stage siswa untuk feed notifikasi di dashboard guru.

### 8.2 Local Storage (SharedPreferences & SQLite)
- **Draft Session**: Menyimpan `currentQuestionIndex`, urutan soal acak, dan skor sementara saat bermain stage.
- **Offline Cache**: Menyimpan progres belajar siswa mode offline sehingga dapat diakses kembali kapan pun tanpa koneksi internet.

---

## 9. Struktur Direktori & Penjelasan Kode

```
lib/
├── app/
│   └── router.dart                 # Konfigurasi rute GoRouter dan proteksi navigasi
├── core/
│   ├── app_constants.dart          # Konstanta path gambar, ikon, audio, dan mapping huruf-kata
│   ├── responsive_helper.dart      # Deteksi ukuran layar (Phone vs Tablet)
│   ├── responsive_student.dart     # Dimensi dan layout khusus siswa di tablet
│   └── responsive_teacher.dart     # Dimensi dan layout khusus guru di tablet
├── models/
│   ├── game_type.dart              # Enum 7 jenis mini-game SiEja
│   └── question_model.dart         # Model data soal Firestore & konfigurasi urutan huruf
├── screens/
│   ├── select_role_screen.dart     # Halaman pilih peran (Siswa / Guru)
│   ├── splash_screen.dart          # Halaman pembuka aplikasi & inisialisasi sistem
│   ├── student/                    # Kumpulan layar modul siswa
│   │   ├── login_student_screen.dart       # Form login siswa via username & PIN
│   │   ├── student_dashboard_screen.dart   # Beranda utama siswa online
│   │   ├── offline_dashboard_screen.dart   # Beranda siswa mode offline
│   │   ├── learn_letter_screen.dart        # Modul belajar huruf A-Z interaktif
│   │   ├── select_objek_screen.dart        # Pemilihan objek untuk mengeja terbimbing
│   │   ├── spell_guided_screen.dart        # Modul mengeja suku kata & huruf
│   │   ├── spell_word_screen.dart          # Papan latihan mengeja kata bebas
│   │   ├── stage_map_screen.dart           # Peta pemilihan level Stage 1-6
│   │   ├── stage_screen.dart               # Engine utama eksekusi 7 mini-game
│   │   ├── progress_screen.dart            # Rapor pencapaian bintang siswa
│   │   ├── reward_screen.dart              # Layar perayaan skor & bintang stage
│   │   ├── profile_screen.dart             # Profil siswa & avatar
│   │   └── settings_screen.dart            # Pengaturan audio BGM & SFX
│   └── teacher/                    # Kumpulan layar modul guru
│       ├── login_teacher_screen.dart       # Form login guru via Email/Password
│       ├── teacher_dashboard_screen.dart   # Dashboard statistik & monitoring kelas
│       ├── student_list_screen.dart        # Manajemen tambah/edit/hapus siswa & Auto-PIN
│       ├── unlock_level_screen.dart        # Kontrol buka/kunci stage massal & perorangan
│       ├── progress_report_screen.dart     # Laporan nilai & analisis progres siswa
│       └── teacher_settings_screen.dart    # Pengaturan akun guru & reset data
├── services/
│   ├── audio_service.dart          # Pengelola pemutaran musik (BGM) & efek suara (SFX)
│   ├── connectivity_service.dart   # Pemantau status koneksi internet perangkat
│   ├── firebase_service.dart       # Layanan interaksi Cloud Firestore & Firebase Auth
│   ├── progress_service.dart       # Layanan cache lokal, draf soal, & data siswa offline
│   ├── question_service.dart       # Penyedia data soal dari Firestore & fallback lokal
│   └── stage_question_composer.dart# Logika komposisi & pengacakan soal per stage
├── utils/
│   └── credential_helper.dart      # Utilitas pembuatan kunci kredensial & hashing
├── widgets/
│   ├── asset_button.dart           # Tombol kustom berbasis aset dengan feedback animasi
│   ├── bg_scaffold.dart            # Scaffold berlatar belakang gambar responsif
│   └── inner_shadow_container.dart # Container dengan efek bayangan dalam estetis
└── main.dart                       # Entry point aplikasi Flutter
```

---

## 10. Panduan Instalasi & Menjalankan Aplikasi

### Prasyarat:
- **Flutter SDK**: Versi `>= 3.16.0` (Dart SDK `>= 3.0.0 < 4.0.0`)
- **Android SDK**: Target API 34+ (Android 14) / Min API 21 (Android 5.0 Lollipop)
- **Java Development Kit (JDK)**: Versi 17

### Langkah-Langkah:
1. **Buka Terminal di Direktori Proyek**:
   ```bash
   cd e:\Skripsi\projectskripsi\SiEja
   ```
2. **Unduh Dependensi Proyek**:
   ```bash
   flutter pub get
   ```
3. **Verifikasi Sintaks & Kode**:
   ```bash
   flutter analyze
   ```
4. **Jalankan Aplikasi di Perangkat / Emulator Android**:
   ```bash
   flutter run
   ```
5. **Kompilasi Menjadi APK Rilis**:
   ```bash
   flutter build apk --release
   ```
   *File APK rilis akan tersedia di `build/app/outputs/flutter-apk/app-release.apk`.*

---
*Dokumen ini disusun untuk keperluan dokumentasi teknis, laporan tugas akhir / skripsi, serta panduan pengembang aplikasi **SiEja**.*
