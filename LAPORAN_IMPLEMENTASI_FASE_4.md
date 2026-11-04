# LAPORAN RESMI IMPLEMENTASI FASE 4
## Proyek Aplikasi Pembelajaran Membaca dan Mengeja SiEja

---

**Tanggal Implementasi**: 14 Oktober 2026  
**Status**: Selesai Diimplementasikan dan Tervalidasi Penuh  
**Cakupan**: Fase 4 (Katalog Materi Dinamis, Integrasi Firebase Storage, Resolusi Media Cloud & Fallback Lokal, Pemetaan Audio Huruf A–Z)  
**Dokumen Referensi**: `AUDIT_REVISI_SIEJA.md`, `LAPORAN_IMPLEMENTASI_FASE_1.md`, `LAPORAN_IMPLEMENTASI_FASE_2.md`, `LAPORAN_IMPLEMENTASI_FASE_3.md`  
**File Repositori**: [`LAPORAN_IMPLEMENTASI_FASE_4.md`](file:///e:/Skripsi/projectskripsi/SiEja/LAPORAN_IMPLEMENTASI_FASE_4.md)

---

## 1. Ringkasan Eksekutif

Implementasi **Fase 4** mentransformasikan sistem materi kata dan media SiEja dari pemetaan statis aset lokal (terbatas pada 26 kata bawaan A–Z) menjadi arsitektur materi dinamis berbasis cloud yang fleksibel dengan mempertahankan ketersediaan materi luring (*offline resilience*):

1. **Katalog Materi Dinamis melalui Website Guru**: Guru dapat mengunggah kata baru lengkap dengan gambar objek dan rekaman audio kata utuh langsung dari perangkat, serta memetakan pilihan audio huruf awal dari aset audio bawaan A–Z yang sudah tersedia di aplikasi.
2. **Pemisahan Konsep Audio Kata dan Audio Huruf**:
   - `wordAudioPath` menunjuk ke berkas audio pengucapan kata utuh yang diunggah guru (contoh: "BOLA").
   - `letterAudioId` adalah ID huruf A–Z yang memetakan ke audio pelafalan huruf lokal bawaan (`AppAudio.huruf()`). Tidak ada unggah ulang atau penggandaan audio huruf.
   - `initialLetter` adalah huruf pertama riil dari kata (contoh: 'B' untuk "BOLA"). Guru dapat secara fleksibel memilih `letterAudioId` yang berbeda jika diinginkan secara pedagogis.
3. **Integrasi Firebase Storage yang Aman & Terkelola**:
   - Pada Website, Firebase Storage diinisialisasi melalui app yang sama (`lib/firebase/client.ts`).
   - Layanan `services/catalog-service.ts` mengelola siklus hidup berkas: validasi ukuran & ekstensi, unggah berkas, pencegahan duplikasi kata, dan pembersihan berkas usang (*cleanup*) secara aman setelah pembaruan metadata Firestore berhasil.
4. **Konsumsi Media Dinamis pada Android**:
   - Ditambahkan dependensi resmi `firebase_storage: ^13.6.0` yang kompatibel dengan dependensi FlutterFire proyek.
   - Dibuat `MaterialModel` dan layanan sentral `MaterialService` dengan caching in-memory untuk meminimalkan beban jaringan.
   - `AudioService.playSFX()` ditingkatkan agar mendukung pemutaran URL audio jaringan (`UrlSource`) tanpa merusak pemutaran aset audio lokal (`AssetSource`).
   - Dibuat widget `MaterialImageWidget` yang menangani pemuatan gambar cloud secara mulus dengan loading indicator, error handling yang aman, dan fallback lokal.
5. **Dukungan Soal Firestore Dinamis**:
   - `QuestionService.hasValidAsset()` diperbarui agar kata yang terdaftar dalam `material_catalog` aktif tidak lagi ditolak oleh aplikasi, memungkinkan pembuatan soal baru dengan variasi kata tanpa batas.
6. **Preservasi 100% Fitur Lokal & Offline**:
   - Materi lokal 26 kata A–Z dan fitur "Belajar Huruf" tetap berfungsi penuh saat luring tanpa internet.
   - Jika jaringan terputus atau berkas cloud belum selesai diunduh, aplikasi secara elegan beralih ke aset lokal atau menampilkan fallback visual tanpa mengalami *crash*.

---

## 2. Daftar File yang Ditambah dan Diubah

### A. Repositori Website Guru (`Web/SiEja_Web_2.0/`)

| No | Path File | Status | Alasan & Ringkasan Modifikasi |
|:--:|:---|:---:|:---|
| 1 | `lib/firebase/client.ts` | **Modified** | Menambahkan impor dan inisialisasi `getStorage`, mengekspos objek `storage: FirebaseStorage` dari `getFirebaseClient()`. |
| 2 | `types/sieja.ts` | **Modified** | Menambahkan antarmuka kontrak `MaterialCatalogItem`, `CreateCatalogInput`, dan `UpdateCatalogInput`. |
| 3 | `lib/domain/business-rules.ts` | **Modified** | Menambahkan fungsi normalisasi (`normalizeWord`, `formatCatalogWord`, `calculateInitialLetter`), validasi `letterAudioId`, validasi berkas gambar (`validateImageFile`, maks 5MB), validasi berkas audio (`validateAudioFile`, maks 10MB), serta pencegahan kata duplikat pada `validateCatalogInput`. Memperluas `materialExistsInCatalog` agar mendukung kata dinamis. |
| 4 | `services/catalog-service.ts` | **Added** | Layanan CRUD Firestore `material_catalog` dan operasi Firebase Storage: `uploadCatalogMedia`, `deleteCatalogMedia`, `getMediaDownloadUrl`, `getCatalogItems`, `createCatalogItem`, `updateCatalogItem`, `toggleCatalogStatus`, dan `deleteCatalogItem`. Menyertakan pure functions `buildCreateCatalogPayload` dan `buildUpdateCatalogPayload` untuk testing terisolasi. |
| 5 | `components/catalog/catalog-page.tsx` | **Added** | Antarmuka manajemen katalog materi: kartu ringkasan statistik (Total, Aktif, Nonaktif), pencarian kata, filter status & huruf A–Z, tabel materi dengan pratinjau thumbnail, pemutar audio kata, tombol uji suara huruf bawaan, tombol toggle aktif, dialog form tambah/edit dengan file picker & preview, serta dialog konfirmasi hapus. |
| 6 | `app/dashboard/katalog/page.tsx` | **Added** | Rute halaman baru `/dashboard/katalog` di bawah layout dashboard guru. |
| 7 | `components/dashboard/dashboard-shell.tsx` | **Modified** | Menambahkan menu "Katalog Materi" (`/dashboard/katalog`, ikon `FolderArchive`) pada sidebar navigasi guru. |
| 8 | `firestore.rules.proposed` | **Modified** | Menambahkan usulan aturan keamanan Firestore untuk koleksi `material_catalog` (baca publik untuk materi aktif, tulis/ubah/hapus hanya untuk guru). |
| 9 | `storage.rules.proposed` | **Added** | Menambahkan berkas usulan aturan Firebase Storage untuk path `material_catalog/{materialId}/{fileName}` (baca publik untuk kebutuhan game siswa, tulis/hapus hanya untuk guru terautentikasi). |
| 10 | `tests/dynamic-catalog.test.ts` | **Added** | Rangkaian 10 pengujian unit otomatis mencakup normalisasi kata, ekstraksi huruf awal, validasi audio huruf A–Z, validasi MIME/ekstensi/ukuran gambar & audio, penolakan kata duplikat, dan schema payload Firestore. |

### B. Repositori Aplikasi Android Siswa & Guru (`SiEja/`)

| No | Path File | Status | Alasan & Ringkasan Modifikasi |
|:--:|:---|:---:|:---|
| 1 | `pubspec.yaml` & `pubspec.lock` | **Modified** | Menambahkan dependensi resmi `firebase_storage: ^13.6.0` yang kompatibel dengan dependensi Firebase proyek. |
| 2 | `lib/models/material_model.dart` | **Added** | Model data `MaterialModel` yang merepresentasikan dokumen `material_catalog` Firestore, dilengkapi parser toleran null `fromFirestore` dan `fromMap`, serta getter `letterAudioKey`. |
| 3 | `lib/services/material_service.dart` | **Added** | Layanan tunggal (*singleton*) manajemen katalog materi: memuat koleksi `material_catalog` aktif dengan fallback luring, caching in-memory URL unduh Storage, resolusi URL gambar cloud dengan fallback aset lokal `AppImages`, resolusi audio kata dengan fallback `AppAudio.kata`, dan pemetaan audio huruf ke `AppAudio.huruf`. |
| 4 | `lib/services/audio_service.dart` | **Modified** | Memperbarui method `playSFX(String path)` agar otomatis menggunakan `UrlSource(path)` jika berupa URL jaringan (`http://` atau `https://`) dan `AssetSource` jika berupa path aset lokal. |
| 5 | `lib/widgets/material_image_widget.dart` | **Added** | Komponen UI reaktif untuk menampilkan gambar materi: mendukung gambar cloud via `Image.network` dengan progress indicator, gambar lokal via `Image.asset`, serta fallback visual `Icon(Icons.pets)` jika aset tidak tersedia atau terjadi gangguan jaringan. |
| 6 | `lib/services/question_service.dart` | **Modified** | Memperbarui `hasValidAsset(huruf, kata)` agar tidak hanya memeriksa pemetaan lokal `AppImages.hurufKeKata`, melainkan juga mengakui kata yang terdaftar dalam `MaterialService().hasMaterial(kata)`. |
| 7 | `lib/screens/student/stage_screen.dart` | **Modified** | Mengintegrasikan `MaterialService` dan `MaterialImageWidget` pada mini-game `tebakGambarObjek`, `hurufAwalApa`, `hurufYangHilang`, dan `susunKata`. Audio kata diputar dari URL cloud atau lokal secara dinamis; audio huruf selalu memetakan ke `AppAudio.huruf()`; pembersihan variabel lokal yang tidak terpakai. |
| 8 | `test/phase4_dynamic_catalog_test.dart` | **Added** | Rangkaian 16 pengujian unit dan widget otomatis memverifikasi parsing `MaterialModel`, independensi `letterAudioId`, pemetaan audio huruf, resolusi media cloud & fallback lokal, validasi `QuestionService`, dan rendering `MaterialImageWidget`. |

---

## 3. Skema Data Firestore dan Path Storage Final

### A. Koleksi Firestore: `material_catalog`
- **Nama Koleksi**: `material_catalog`
- **Format Document ID**: Firestore Auto-ID acak unik (misal: `7GzQ8yNk1xR4wPvT2mLq`) guna mencegah bentrokan ID.
- **Skema Dokumen**:

```json
{
  "word": "BOLA",
  "normalizedWord": "bola",
  "initialLetter": "B",
  "letterAudioId": "B",
  "imagePath": "material_catalog/7GzQ8yNk1xR4wPvT2mLq/image_1728950400000.png",
  "wordAudioPath": "material_catalog/7GzQ8yNk1xR4wPvT2mLq/word_1728950400000.mp3",
  "isActive": true,
  "createdAt": "2026-10-14T16:30:00.000Z",
  "updatedAt": "2026-10-14T16:30:00.000Z",
  "createdBy": "teacher_auth_uid"
}
```

### B. Struktur Path Objek Firebase Storage
Semua berkas media dikelompokkan secara terisolasi per ID materi katalog:
- **Gambar Objek**: `material_catalog/{materialId}/image_{timestamp}.{ext}`  
  Format yang didukung: `.png`, `.jpg`, `.jpeg`, `.webp` (Maksimal 5 MB).
- **Audio Kata Utuh**: `material_catalog/{materialId}/word_{timestamp}.{ext}`  
  Format yang didukung: `.mp3`, `.wav`, `.m4a`, `.ogg`, `.aac`, `.webm` (Maksimal 10 MB).
- **Pembersihan Berkas (*Garbage Collection*)**:
  Saat guru memperbarui gambar atau audio suatu materi, berkas baru diunggah terlebih dahulu. Setelah dokumen Firestore berhasil diperbarui, berkas lama otomatis dihapus dari Storage sehingga tidak meninggalkan berkas sampah tak terpakai (*orphaned assets*). Jika materi dihapus, seluruh berkas di path tersebut dihapus dari Storage.

---

## 4. Alur Kerja Media Website dan Android

### A. Alur Unggah pada Website Guru

```mermaid
flowchart TD
    A[Guru Mengisi Form di Website] --> B[Validasi Client-Side:<br>Ukuran Berkas, Format MIME, & Keunikan Kata]
    B -- Tidak Valid --> C[Tampilkan Pesan Error di Form]
    B -- Valid --> D[Kunci Tombol Simpan: isSubmitting = true]
    D --> E[Buat Document Reference Baru: material_catalog/{id}]
    E --> F[Unggah Gambar ke Storage: image_{ts}.png]
    F --> G[Unggah Audio Kata ke Storage: word_{ts}.mp3]
    G --> H{Apakah Upload Sukses?}
    H -- Gagal --> I[Hapus Berkas Parsial & Lempar Error]
    H -- Sukses --> J[Tulis Metadata Dokumen ke Firestore]
    J --> K[Notifikasi Sukses & Muat Ulang Daftar Materi]
```

### B. Alur Konsumsi Media pada Aplikasi Android

```mermaid
flowchart TD
    Start([Soal/Layar Membutuhkan Media Kata]) --> CheckCache{Apakah URL Download<br>Tersimpan di Cache?}
    
    CheckCache -- Ya --> ReturnCached[Gunakan URL dari Cache In-Memory]
    
    CheckCache -- Belum --> CheckDynamic{Apakah Kata Ada di<br>material_catalog?}
    
    CheckDynamic -- Ada (Materi Cloud) --> FetchStorage[Minta Download URL dari Firebase Storage SDK]
    FetchStorage --> CacheUrl[Simpan URL di Cache In-Memory]
    CacheUrl --> PlayOrShow[Putar via UrlSource / Tampilkan via Image.network]
    
    CheckDynamic -- Tidak Ada / Storage Gagal --> FallbackLocal{Cek Fallback Lokal:<br>AppImages & AppAudio}
    FallbackLocal -- Ditemukan --> PlayLocal[Putar via AssetSource / Tampilkan via Image.asset]
    FallbackLocal -- Tidak Ada --> ShowDefault[Tampilkan Icon Placeholder Tanpa Crash]
    
    %% Alur Audio Huruf
    LetterAudio([Soal Membutuhkan Audio Huruf]) --> MapLetter[Ambil letterAudioId dari Model]
    MapLetter --> PlayLocalLetter[Putar Langsung AppAudio.huruf: assets/audio/huruf/{letter}.mp3]
```

---

## 5. Aturan Fallback dan Ketahanan Luring (*Offline Resilience*)

1. **Materi Lokal Bawaan Tetap Utuh**:
   Aset 26 huruf dan kata lokal (`assets/images/kata/` dan `assets/audio/kata/`) tidak dihapus maupun dimodifikasi. Jika aplikasi dijalankan saat luring atau perangkat tidak memiliki koneksi internet, mini-game yang menggunakan materi bawaan tetap berfungsi normal 100%.
2. **Fitur "Belajar Huruf" Terisolasi Aman**:
   Fitur Belajar Huruf tetap menggunakan `AppAudio.huruf()` dan `AppImages.hurufKeGambar` bawaan A–Z, sehingga pengalaman belajar mandiri siswa kelas 1 SD tidak terganggu oleh keberadaan materi cloud baru.
3. **Pemuatan Cloud Tanpa Crash (*Defensive Fetching*)**:
   Jika jaringan internet gagal saat memuat `material_catalog` dari Firestore atau saat meminta *download URL* dari Storage SDK, `MaterialService` menangkap eksepsi secara senyap (*graceful catch*) dan mengembalikan data lokal/cache.
4. **Widget Gambar Tahan Gangguan**:
   `MaterialImageWidget` dilengkapi `errorBuilder` yang menampilkan ikon fallback netral jika pengunduhan gambar gagal di tengah jalan, mencegah munculnya layar merah (*red screen crash*).

---

## 6. Audit Keamanan dan Status Firebase Rules

### A. Temuan Audit Keamanan
1. **Aturan Firestore**:
   - Berkas usulan [`firestore.rules.proposed`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/firestore.rules.proposed) telah diperbarui dengan skema validasi `validMaterialCatalogItem`.
   - Siswa diperbolehkan membaca materi dengan kondisi `resource.data.isActive == true`.
   - Hak cipta, ubah, dan hapus dibatasi hanya untuk guru (`isAuthenticatedTeacher()`).
2. **Aturan Storage**:
   - Berkas usulan [`storage.rules.proposed`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/storage.rules.proposed) telah dibuat.
   - Siswa diberikan hak baca publik (`allow read: if true`) untuk aset media `material_catalog/{materialId}/*` agar siswa yang login tanpa akun Firebase Auth individu tetap dapat mengunduh dan memutar media permainan.
   - Hak tulis dan hapus dibatasi hanya untuk akun guru terautentikasi (`request.auth != null`).
3. **Catatan Batasan & Kepatuhan**:
   - Sesuai instruksi mutlak, **aturan keamanan di server produksi Firebase TIDAK diubah atau di-deploy pada fase ini**.
   - Risiko warisan dari Fase 2 (akses baca publik dokumen profil siswa pada `siswa` karena mekanisme login kustom) tetap dicatat sebagai *blocker* arsitektural yang perlu diselesaikan secara terpisah melalui autentikasi Firebase kustom (*custom auth token*) sebelum sistem dipublikasikan ke lingkungan produksi massal.

---

## 7. Hasil Pengujian Aktual

Seluruh pengujian otomatis dijalankan secara nyata pada terminal lokal tanpa manipulasi angka hasil.

### A. Hasil Pengujian Unit Website (`Web/SiEja_Web_2.0/`)

Perintah yang dijalankan:
```bash
node scripts/run-tests.mjs
```

**Hasil Aktual**: **85 tests passed, 0 failed** (12 suite pengujian).

```text
Summary:
  Total test suites: 12
  Total tests:       85
  Passed:            85
  Failed:            0
  Duration:          22.68s

Status: ALL TESTS PASSED
```

Daftar suite yang diuji:
- `tests/dynamic-catalog.test.ts` (**10 tes baru**) — Normalisasi kata, huruf awal, validasi audio huruf, validasi ukuran & format berkas, pencegahan duplikasi, payload create/update, dan resolusi materi dinamis.
- `tests/dynamic-stages.test.ts` (8 tes) — Pengelolaan stage dinamis Fase 3.
- `tests/student-edit.test.ts` (9 tes) — Edit profil & sinkronisasi kredensial Fase 2.
- `tests/business-rules.test.ts` (14 tes) — Aturan bisnis inti.
- `tests/letter-sequence.test.ts` (8 tes) — Validasi urutkanHuruf.
- `tests/question-write.test.ts` (8 tes) — Penulisan soal Firestore.
- `tests/ui-rules.test.ts` (14 tes) — Logika UI dan kalkulasi status stage.
- `tests/ui-components.test.mjs` & `rendered-html.test.mjs` (5 tes) — Rendering UI.
- Suite lainnya (9 tes).

### B. Hasil Kompilasi Produksi Website

Perintah yang dijalankan:
```bash
npm run build
```

**Hasil Aktual**: **Berhasil (Compiled Successfully dengan 0 Error)**.
Rute baru `/dashboard/katalog` berhasil dikompilasi secara optimal.

### C. Hasil Pengujian Aplikasi Android (`SiEja/`)

Perintah yang dijalankan:
```bash
flutter test
```

**Hasil Aktual**: **97 tests passed, 0 failed**.

```text
00:02 +97: All tests passed!
```

Rincian pengujian:
- `test/phase4_dynamic_catalog_test.dart` (**16 tes baru**):
  1. Parsing `MaterialModel.fromMap` dengan data lengkap.
  2. Fallback normalisasi otomatis pada `MaterialModel`.
  3. Penolakan data dengan kata kosong.
  4. Independensi `letterAudioId` terhadap `initialLetter`.
  5. Pemetaan `letterAudioId` ke audio lokal `AppAudio.huruf`.
  6. Pemetaan audio huruf pilihan khusus guru.
  7. Resolusi audio kata menggunakan cache Storage URL.
  8. Fallback audio kata lokal saat materi tidak ada di cloud.
  9. Resolusi gambar menggunakan cache Storage URL.
  10. Fallback gambar lokal bawaan saat materi tidak ada di cloud.
  11. Pengembalian null aman jika kata sama sekali tidak memiliki aset.
  12. `QuestionService.hasValidAsset` menerima pasangan lokal bawaan.
  13. `QuestionService.hasValidAsset` menerima kata dinamis dari cloud catalog.
  14. `QuestionService.hasValidAsset` menolak kata fiktif tak terdaftar.
  15. `MaterialImageWidget` merender ikon fallback saat gambar kosong tanpa crash.
  16. `MaterialImageWidget` merender aset lokal bawaan dengan benar.
- Pengujian Fase 1, Fase 2, Fase 3, dan regresi lama (**81 tes**): Seluruhnya tetap lulus 100%.

### D. Hasil Analisis Statis Kode Android (`flutter analyze`)

Perintah yang dijalankan:
```bash
flutter analyze lib/models/material_model.dart lib/services/material_service.dart lib/widgets/material_image_widget.dart
```

**Hasil Aktual**: **No issues found! (0 error, 0 warning)**.
Semua berkas Fase 4 yang ditambahkan bersih dari kesalahan tipe, sintaksis, maupun pelanggaran *lint*.

---

## 8. Status Akhir Komponen Fase 4

### A. Selesai (Completed)
- Model & schema data Firestore `material_catalog`.
- Integrasi Firebase Storage pada Website (`services/catalog-service.ts`) dan Android (`pubspec.yaml`, `MaterialService`).
- Antarmuka manajemen katalog materi guru (`components/catalog/catalog-page.tsx`) dengan pratinjau media dan validasi berkas.
- Pemetaan audio huruf A–Z bawaan tanpa penggandaan berkas audio huruf.
- Resolusi media cloud dinamis dengan cache dan fallback luring.
- Pengakuan materi dinamis pada `QuestionService.hasValidAsset()`.
- Integrasi `MaterialImageWidget` pada mini-game siswa di `stage_screen.dart`.

### B. Teruji (Tested)
- 85 pengujian otomatis Website lulus (`node scripts/run-tests.mjs`).
- Build produksi Next.js lulus (`npm run build`).
- 97 pengujian otomatis Flutter lulus (`flutter test`).
- Analisis statis berkas Fase 4 bersih (`flutter analyze`).

### C. Belum Teruji (Unexecuted Tests)
- Pengujian unggah berkas video/media berukuran masif di atas bandwidth jaringan lambat (2G/3G).
- Pengujian multi-perangkat serentak mengunggah ratusan materi pada milidetik yang sama di server live Firebase (uji beban/stres).

### D. Blocker / Kendala Arsitektur
- **Otorisasi Siswa pada Firebase Storage**: Siswa Android saat ini tidak memiliki akun Firebase Authentication individu (menggunakan sistem login kustom username + PIN). Akibatnya, akses membaca berkas media di Firebase Storage memerlukan aturan baca terbuka (`allow read: if true`) pada path `material_catalog/{materialId}/*`. Solusi jangka panjang yang direkomendasikan adalah implementasi Firebase Custom Tokens atau Anonymous Auth terhubung ke akun siswa sebelum peluncuran produksi massal.
