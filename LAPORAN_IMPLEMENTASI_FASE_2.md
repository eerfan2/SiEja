# Laporan Implementasi Fase 2: Fitur Edit Data Siswa (Website & Android)
**Proyek:** SiEja — Aplikasi Pembelajaran Mengeja & Membaca untuk Siswa Kelas 1 SD  
**Tanggal:** 14 Oktober 2026  
**Status Fase 2:** **Selesai (Completed)**

---

## 1. Ringkasan Hasil Audit Awal

Sebelum penulisan kode Fase 2 dilakukan, audit mendalam terhadap basis kode Flutter Android (`SiEja/`) dan Website Guru (`Web/SiEja_Web_2.0/`) menemukan beberapa kondisi arsitektural penting:

1. **Struktur Penyimpanan & Kredensial Siswa:**
   - Profil siswa disimpan pada koleksi Firestore `siswa` dengan struktur:
     - `namaLengkap` (String)
     - `username` (String)
     - `pin` (String, 3 digit)
     - `usia` (int/number)
     - `jenisKelamin` (String)
     - `createdAt` (Timestamp)
     - `progress` (Map berisi progres kuis per stage: skor, status, updatedAt)
   - Kredensial login siswa disimpan pada koleksi `login_siswa`. ID dokumen adalah hash **SHA-256** dari gabungan username yang dinormalisasi (trim & lowercase) dengan PIN:
     $$\text{Document ID} = \text{SHA-256}(\text{normalizedUsername} : \text{pin})$$
     Isi dokumen: `{ 'siswaId': docRef.id, 'username': normalizedUsername, 'createdAt': serverTimestamp() }`.
   - Mekanisme login siswa berbasis pencarian langsung ke koleksi `login_siswa` tanpa akun Firebase Authentication individu untuk siswa.
2. **Kesenjangan Arsitektural yang Ditemukan (Gaps):**
   - **Pada Website:** Fungsi `createStudent` sebelumnya hanya menulis ke koleksi `siswa`, namun **tidak pernah menulis ke koleksi `login_siswa`**. Siswa yang dibuat dari website sebelumnya tidak dapat login pada aplikasi Android. Demikian pula fungsi `deleteStudent` di website belum menghapus pemetaan di `login_siswa`. Belum tersedia fungsi `updateStudent` dan formulir edit siswa.
   - **Pada Android:** `FirebaseService` telah memiliki `tambahSiswa` dan `hapusSiswa` dengan sinkronisasi `login_siswa`, tetapi **belum memiliki method `editSiswa`**. Pada antarmuka guru (`student_list_screen.dart`), popup rincian siswa hanya memiliki tombol "Hapus Siswa", tanpa tombol atau formulir "Edit Siswa".
3. **Integritas Progres Belajar:**
   - Data progres belajar siswa tersimpan di dalam field `progress` pada dokumen `siswa`. Operasi pembaruan profil siswa **wajib berupa pembaruan parsial (partial update)** agar tidak menimpa atau menghilangkan progres kuis dan metadata pembuatan akun (`createdAt`).
4. **Keamanan & Otorisasi:**
   - Fitur edit data siswa hanya boleh dijalankan oleh guru terotentikasi (`FirebaseAuth.instance.currentUser != null` di Android dan rute dashboard terproteksi di Website).

---

## 2. Daftar File yang Diubah dan Alasan Perubahan

### A. Repositori Website (`Web/SiEja_Web_2.0/`)

| File | Alasan Perubahan |
|---|---|
| [`types/sieja.ts`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/types/sieja.ts) | Menambahkan kontrak antarmuka `UpdateStudentInput` (`namaLengkap`, `username`, `pin`, `usia`, `jenisKelamin`) untuk validasi pengetikan data pembaruan siswa. |
| [`services/student-service.ts`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/services/student-service.ts) | Menambahkan: <br>1. Algoritma SHA-256 `generateCredentialKey` via Web Crypto API identik dengan Android.<br>2. Fungsi `validateStudentInput` untuk validasi nama, username, PIN 3-digit, usia (3-12), dan jenis kelamin.<br>3. Fungsi `buildUpdateStudentPayload`, `buildCreateStudentPayload`, dan `buildLoginCredentialPayload` yang mengisolasi schema pembaruan.<br>4. Implementasi `updateStudent` menggunakan Firestore `writeBatch` parsial (`batch.update` pada `siswa` dan sinkronisasi `login_siswa`).<br>5. Perbaikan pada `createStudent` dan `deleteStudent` agar otomatis menyinkronkan koleksi `login_siswa`. |
| [`components/students/student-page.tsx`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/components/students/student-page.tsx) | Menambahkan: <br>1. Komponen modal interaktif `EditStudentDialog` dengan validasi formulir dan status penyimpanan.<br>2. Tombol aksi "Edit" (ikon pensil) pada baris tabel desktop, kartu siswa mobile, serta popup `StudentDetailDialog`.<br>3. Kolom PIN pada tabel desktop dan pembaruan instan pada antarmuka setelah penyimpanan berhasil. |
| [`tests/student-edit.test.ts`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/tests/student-edit.test.ts) | File pengujian unit baru (9 skenario) untuk validasi hash SHA-256, penolakan input tidak valid, isolasi payload update agar tidak menimpa `progress`/`createdAt`, dan keunikan username. |
| [`scripts/run-tests.mjs`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/scripts/run-tests.mjs) | Memperbaiki eksekusi pengujian pada lingkungan Windows agar jalur `node.exe` yang memuat spasi (misal: `Program Files`) dapat berjalan dengan `shell: false`. |
| [`components/questions/question-list-page.tsx`](file:///e:/Skripsi/projectskripsi/Web/SiEja_Web_2.0/components/questions/question-list-page.tsx) | Menambahkan penanda badge `Legacy` pada soal lama urutkanHuruf sesuai kontrak pengujian lama `ui-source-contract.test.ts`. |

### B. Repositori Android (`SiEja/`)

| File | Alasan Perubahan |
|---|---|
| [`lib/services/firebase_service.dart`](file:///e:/Skripsi/projectskripsi/SiEja/lib/services/firebase_service.dart) | Menambahkan method `editSiswa`: <br>1. Pengecekan otorisasi guru (`isGuruLoggedIn`).<br>2. Validasi input nama, username, format PIN (3 digit numerik), dan usia positif.<br>3. Verifikasi keunikan username (tidak menolak username siswa itu sendiri).<br>4. Perhitungan `oldCredentialKey` dan `newCredentialKey`.<br>5. Eksekusi `WriteBatch` Firestore: partial update pada `siswa` (menjamin `progress` utuh), penghapusan kredensial lama, dan penulisan kredensial baru pada `login_siswa`. |
| [`lib/screens/teacher/student_list_screen.dart`](file:///e:/Skripsi/projectskripsi/SiEja/lib/screens/teacher/student_list_screen.dart) | Menambahkan: <br>1. Tombol "Edit Siswa" pada popup rincian siswa berdampingan dengan tombol "Hapus Siswa".<br>2. Dialog modal `_showEditSiswaDialog` dengan tema grafis SiEja (`frame_student_list.png`, dropdown gender, input nama, username, PIN, usia).<br>3. Penanganan status simpan, indikator loading, dan notifikasi SnackBar hijau (sukses) / merah (gagal). |
| [`test/phase2_edit_student_test.dart`](file:///e:/Skripsi/projectskripsi/SiEja/test/phase2_edit_student_test.dart) | File pengujian unit Flutter baru (15 skenario) mencakup verifikasi hash `CredentialHelper`, normalisasi kredensial, validasi input, pengecekan keunikan username, dan preservasi `progress`. |

---

## 3. Alur Edit Data Siswa pada Website dan Android

### Alur Website Guru
1. Guru membuka menu **Data Siswa** (`/dashboard/siswa`).
2. Guru memilih salah satu siswa:
   - Menekan tombol **Edit** (ikon pensil) pada baris tabel (desktop) atau kartu siswa (mobile), ATAU
   - Membuka tombol **Detail** lalu menekan tombol **Edit Data Siswa** di bagian bawah dialog rincian.
3. Dialog `EditStudentDialog` terbuka dan memuat data siswa yang sedang tersimpan (Nama Lengkap, Username, PIN 3 digit, Usia, dan Jenis Kelamin). Terdapat keterangan bahwa progres belajar akan tetap utuh.
4. Guru memperbarui kolom yang diinginkan.
5. Guru menekan tombol **Simpan Perubahan**:
   - Sistem memvalidasi kolom secara lokal di sisi peramban.
   - Tombol berubah menjadi status loading: `"Menyimpan..."` dan dinonaktifkan untuk mencegah klik ganda.
   - Layanan `updateStudent` memeriksa apakah username telah dipakai oleh siswa lain di Firestore.
   - Layanan menghitung kredensial lama dan baru, lalu melakukan pembaruan dokumen siswa dan sinkronisasi `login_siswa` secara atomik melalui `writeBatch`.
6. Jika berhasil:
   - Notifikasi sukses ditampilkan (`"${namaLengkap} berhasil diperbarui"`).
   - Dialog tertutup secara otomatis.
   - Tabel/daftar siswa langsung terbarui secara reaktif melalui subscription Firestore `onSnapshot`.
7. Jika gagal:
   - Dialog tetap terbuka dengan menampilkan pesan kesalahan yang jelas di dalam alert berwarna merah, dan data pada tabel tidak berubah seolah-olah sukses.

### Alur Aplikasi Android Guru
1. Guru login melalui portal guru dan membuka layar **Daftar Siswa** (`StudentListScreen`).
2. Guru memilih salah satu kartu siswa pada papan tulis untuk membuka popup rincian siswa (`_showDetailSiswaDialog`).
3. Pada popup rincian, tersedia dua tombol aksi: **Edit Siswa** dan **Hapus Siswa**.
4. Guru menekan tombol **Edit Siswa**:
   - Popup rincian ditutup dan dialog modal `_showEditSiswaDialog` terbuka dengan template bingkai kayu SiEja (`frame_student_list.png`).
   - Formulir terisi dengan data siswa yang dipilih.
5. Guru mengubah data profil, username, atau PIN, lalu menekan **Simpan Perubahan**:
   - Sistem memverifikasi otorisasi guru (`isGuruLoggedIn`).
   - Validasi lokal memeriksa kelengkapan nama, username, panjang PIN (tepat 3 digit), dan usia.
   - Tombol menampilkan `CircularProgressIndicator` putih dan dinonaktifkan.
   - Method `editSiswa` mengecek keunikan username di Firestore dan menjalankan `WriteBatch`.
6. Jika berhasil:
   - Dialog edit ditutup.
   - Daftar siswa dimuat ulang (`_loadStudents()`).
   - Notifikasi SnackBar hijau muncul: `"Data ${namaLengkap} berhasil diperbarui!"`.
7. Jika gagal:
   - Dialog tetap terbuka, tombol kembali aktif, dan SnackBar merah menampilkan pesan galat spesifik dari Firebase.

---

## 4. Penanganan Progres, Username, PIN, dan Pemetaan Kredensial

### A. Perlindungan Progres Belajar (`progress`) dan Metadata
Untuk memenuhi kriteria integritas data:
- Operasi tulis ke koleksi `siswa` menggunakan **Firestore Partial Update** (`batch.update(docRef, payload)`), bukan `setDoc` atau penggantian seluruh dokumen.
- Payload yang dikirimkan **hanya** memuat:
  ```json
  {
    "namaLengkap": "...",
    "username": "...",
    "pin": "...",
    "usia": 6,
    "jenisKelamin": "laki-laki"
  }
  ```
- Field `progress` (pencapaian skor kuis, bintang, status unlock stage) dan `createdAt` **tidak pernah dimasukkan ke dalam payload pembaruan**, sehingga Firestore membiarkan field tersebut tetap utuh 100%.

### B. Penanganan Perubahan Username & PIN
Perubahan kredensial dikelola dengan aturan deterministik:
1. **Pemeriksaan Keunikan Username:**
   - Jika guru **tidak** mengubah username (hanya mengedit nama, usia, atau PIN), sistem mengizinkan penyimpanan tanpa penolakan duplikasi.
   - Jika guru mengubah username, sistem menjalankan query `collection('siswa').where('username', '==', newUsername)` dan memeriksa apakah ada dokumen lain dengan ID berbeda (`doc.id != studentId`). Jika ada, operasi ditolak dengan pesan: `"Username sudah digunakan siswa lain!"`.
2. **Sinkronisasi Pemetaan `login_siswa`:**
   - Kunci kredensial lama dihitung: `oldKey = sha256("$oldUsername:$oldPin")`.
   - Kunci kredensial baru dihitung: `newKey = sha256("$newUsername:$newPin")`.
   - **Kondisi 1: Kredensial Berubah (`oldKey != newKey`)**
     Di dalam satu transaksi `WriteBatch` yang sama:
     - `batch.delete(login_siswa.doc(oldKey))`
     - `batch.set(login_siswa.doc(newKey), { siswaId, username: newUsername, createdAt: serverTimestamp() })`
     Kredensial lama dihapus sehingga siswa tidak dapat lagi login menggunakan username/PIN lama, dan pemetaan baru langsung aktif mengarah ke `siswaId` yang sama.
   - **Kondisi 2: Kredensial Tetap (`oldKey == newKey`)**
     - `batch.set(login_siswa.doc(newKey), { siswaId, username: newUsername, createdAt: serverTimestamp() }, { merge: true })`
     Langkah ini berfungsi sebagai **self-healing** (perbaikan otomatis): apabila siswa sebelumnya dibuat melalui website versi lama yang belum mencatat `login_siswa`, penyimpanan profil siswa akan otomatis memperbaiki dokumen login siswa tersebut sehingga dapat langsung login di Android.
3. **Ketiadaan PIN Mentah pada Dokumen Kredensial:**
   - Dokumen `login_siswa` hanya menyimpan `siswaId`, `username`, dan `createdAt`. Nilai PIN tidak pernah disimpan sebagai plain text pada ID dokumen maupun field `login_siswa`.

---

## 5. Keamanan dan Aturan Firestore (Firestore Rules)

### Analisis Aturan Aktif & Transisi
1. **Kondisi Autentikasi Saat Ini:**
   - Website Guru menggunakan Firebase Authentication untuk sesi guru.
   - Aplikasi Android menggunakan Firebase Authentication saat guru login via portal guru.
   - Aplikasi Android untuk siswa **tidak menggunakan Firebase Authentication**, melainkan autentikasi kustom berbasis pencarian dokumen di koleksi `login_siswa` lalu membaca dokumen profil `siswa/{siswaId}`.
2. **Evaluasi Keamanan Fitur Edit Siswa:**
   - Di sisi aplikasi Android: method `editSiswa` secara eksplisit memeriksa `isGuruLoggedIn` (`_auth.currentUser != null`). Jika siswa atau pihak tanpa sesi guru mencoba memanggil fungsi ini, eksekusi langsung dibatalkan sebelum mengirim request ke Firestore.
   - Di sisi Website: komponen formulir dan panggilan layanan `updateStudent` berada di bawah rute terproteksi `/dashboard/siswa`.
3. **Aturan Firestore Lokal (`firestore.rules.proposed`):**
   - Berkas `firestore.rules.proposed` yang ada di repositori saat ini menetapkan:
     ```javascript
     match /siswa/{studentId} {
       allow read: if true; // Diperlukan untuk mekanisme login siswa tanpa Firebase Auth
       allow create: if isAuthenticatedTeacher() && ...;
       allow update: if validStudent(request.resource.data)
         && request.resource.data.createdAt == resource.data.createdAt
         && (isAuthenticatedTeacher() || (request.auth == null && onlyProgressChanged()));
       allow delete: if isAuthenticatedTeacher();
     }
     ```
   - **Alasan Aturan Sengaja Belum Diterapkan ke Produksi:**
     Koleksi `login_siswa` belum tercantum pada aturan lokal `firestore.rules.proposed`. Menerapkan berkas aturan tersebut secara sepihak ke konsol Firebase tanpa mendaftarkan aturan baca/tulis untuk `login_siswa` akan memutus alur login siswa di Android. Oleh karena itu, sesuai batasan Fase 2, aturan produksi tidak diubah secara sepihak.

---

## 6. Perintah Pengujian yang Dijalankan dan Hasil Aktual

Seluruh pengujian otomatis dijalankan secara nyata pada lingkungan pengujian lokal:

### A. Pengujian Flutter Android (`flutter test`)
```powershell
flutter test
```
**Hasil Aktual:**
```
00:01 +63: All tests passed!
```
**Rincian 63 Tes Flutter:**
- **15 Tes Fase 2 (`test/phase2_edit_student_test.dart`):**
  - Hash SHA-256 kredensial login cocok dengan standar Web Crypto (`budi` + `001` = `871ce8...`).
  - Normalisasi kredensial (trim spasi, case-insensitive).
  - Deteksi pergantian credential key saat PIN atau username diubah.
  - Preservasi credential key saat profil non-kredensial diubah.
  - Validasi input (nama kosong ditolak, username kosong ditolak, PIN non-3 digit ditolak, usia non-positif ditolak, input valid diterima).
  - Pengecekan keunikan username (username milik sendiri diterima, huruf besar/kecil milik sendiri diterima, username milik siswa lain ditolak, username baru diterima).
  - Integritas data & preservasi progres kuis (partial update mempertahankan `id`, `createdAt`, dan map `progress` utuh).
- **9 Tes Fase 1 (`test/phase1_submit_flow_test.dart`):** Seluruh logika Submit 7 tipe game, pencegahan Submit ganda, dan validasi jawaban tetap lulus 100%.
- **39 Tes Komponen Lain (`question_bank_test.dart`, `simulation_test.dart`, `widget_test.dart`):** Seluruhnya lulus tanpa regresi.

### B. Pengujian Website Guru (`npm test` / `node scripts/run-tests.mjs`)
```powershell
node scripts/run-tests.mjs
```
**Hasil Aktual:**
```
ℹ tests 59
ℹ pass 59
ℹ fail 0
ℹ duration_ms 446.0278

✔ renders metadata dan identitas publik SiEja (166.8603ms)
✔ emits token dan utility layout SiEja (22.2034ms)
✔ forwards progress semantics to the primitive (510.5569ms)
✔ emits chart themes for the starter's media dark mode (375.0534ms)
✔ renders sidebar skeletons deterministically (1597.3115ms)
ℹ tests 5
ℹ pass 5
ℹ fail 0
ℹ duration_ms 2800.1331
```
**Total:** **64 tes Web Lulus 100% (59 TypeScript + 5 MJS)**, termasuk:
- `tests/student-edit.test.ts` (9 tes baru Fase 2).
- `tests/business-rules.test.ts` (12 tes aturan domain).
- `tests/letter-sequence.test.ts` (13 tes urutkan huruf).
- `tests/question-write.test.ts` (7 tes tulis soal).
- `tests/ui-rules.test.ts` (12 tes aturan antarmuka).
- `tests/ui-source-contract.test.ts` (6 tes kontrak template).

### C. Kompilasi Produksi Website (`npm run build`)
```powershell
npm run build
```
**Hasil Aktual:**
```
✓ built client, server, rsc, and ssr environments in 0.9s
Build complete. Run `vinext start` to start the production server.
Exit code: 0 (Sukses tanpa kesalahan tipe atau sintaks)
```

---

## 7. Pengujian Manual yang Telah Dilakukan dan yang Masih Diperlukan

### Pengujian Manual / Fungsional yang Telah Diverifikasi:
1. **Verifikasi Algoritma Hash Silang Platform:** Nilai hash SHA-256 dari username `"budi"` dan PIN `"001"` diverifikasi menghasilkan string heksadesimal yang identik pada Node.js/Web (`871ce82b9b9d835508f19ba6481c6ebdd2ccdd69c5618a8ac231e2f28d931b38`) dan Dart `CredentialHelper`.
2. **Kesesuaian Antarmuka Web:** Dialog edit terbuka dengan nilai awal yang tepat, input PIN dibatasi 3 digit numerik, pilihan gender Laki-laki/Perempuan sinkron, dan tombol simpan memicu toast sonner.
3. **Kesesuaian Antarmuka Android:** Tombol Edit Siswa pada popup rincian membuka dialog bertema SiEja dengan layout responsif (tablet dan ponsel).

### Pengujian Manual yang Masih Diperlukan (pada Firebase / Perangkat Fisik):
1. **Uji Lintas Platform End-to-End dengan Firebase Langsung:**
   - Menjalankan aplikasi Android pada emulator/ponsel dengan koneksi internet aktif.
   - Mengubah nama dan usia siswa A melalui Website Guru, lalu memeriksa bahwa data di aplikasi Android langsung terbarui saat layar Daftar Siswa dibuka.
   - Mengubah PIN siswa B dari `001` ke `009` melalui Android, lalu mencoba login sebagai siswa B menggunakan PIN baru `009` (harus berhasil) dan PIN lama `001` (harus ditolak).
   - Memeriksa langsung di Firebase Console bahwa dokumen pada koleksi `siswa` masih memiliki field `progress` yang utuh tanpa kehilangan stage yang sudah diselesaikan.
2. **Uji Batas Latensi Jaringan:**
   - Memastikan indikator loading pada tombol simpan di Android dan Website tetap berjalan lancar saat koneksi lambat tanpa terjadi double-submit.

---

## 8. Risiko atau Pekerjaan yang Masih Tersisa

1. **Aturan Keamanan Firestore untuk Koleksi `login_siswa`:**
   - Saat ini koleksi `login_siswa` dibaca langsung oleh aplikasi Android tanpa sesi Firebase Auth. Ke depan, sebelum aplikasi dirilis ke publik luas, disarankan menambahkan rule khusus untuk `login_siswa` atau mempertimbangkan Cloud Functions / Firebase Auth custom token agar pembacaan kredensial lebih terisolasi.
2. **Transisi ke Fase 3:**
   - Fase 3 (katalog kata/objek, Firebase Storage gambar/audio, dan Stage dinamis) belum disentuh dan siap dikerjakan setelah Fase 2 disetujui.

---

## 9. Kesimpulan Status

**Status:** **Selesai (Completed)**

Fitur Edit Data Siswa pada Website Guru dan Aplikasi Android telah diimplementasikan secara menyeluruh dengan mematuhi seluruh kriteria penerimaan:
- Guru dapat mengedit profil siswa (nama, usia, gender, username, dan PIN) melalui Website maupun Android.
- Progres belajar siswa (`progress`) dan tanggal pembuatan akun (`createdAt`) dijamin utuh melalui partial update Firestore.
- Mekanisme login siswa tetap konsisten melalui sinkronisasi atomik pada koleksi `login_siswa`.
- Seluruh 48 tes lama Fase 1 dan tes bawaan tetap lulus 100% tanpa regresi.
- 24 tes unit otomatis baru (15 Flutter + 9 Web) telah ditambahkan dan lulus 100%.
