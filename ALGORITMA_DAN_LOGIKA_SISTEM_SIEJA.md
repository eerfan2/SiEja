# 🧠 Dokumentasi Algoritma dan Logika Komputasi Aplikasi "SiEja"

> **Sistem Informasi Edukasi Eja (SiEja)** — Dokumen teknis mengenai algoritma, metode komputasi, dan logika pemrosesan data yang diimplementasikan pada modul Siswa, Guru, dan Layanan Backend.

---

## 📌 Daftar Isi
1. [Ringkasan Algoritma & Metode Komputasi](#1-ringkasan-algoritma--metode-komputasi)
2. [Algoritma Pengacakan & Komposisi Soal (*Fisher-Yates Shuffle & Random Sampling*)](#2-algoritma-pengacakan--komposisi-soal-fisher-yates-shuffle--random-sampling)
3. [Algoritma Kriptografi & Hashing Kredensial (*SHA-256 Hashing Algorithm*)](#3-algoritma-kriptografi--hashing-kredensial-sha-256-hashing-algorithm)
4. [Algoritma Alokasi Slot Terkecil (*First-Fit / Lowest Unassigned Integer*)](#4-algoritma-alokasi-slot-terkecil-first-fit--lowest-unassigned-integer)
5. [Algoritma Validasi & Pencocokan Karakter (*Sequential & Token Matching*)](#5-algoritma-validasi--pencocokan-karakter-sequential--token-matching)
6. [Algoritma Penilaian & Gamifikasi (*Rule-Based Threshold & Progression*)](#6-algoritma-penilaian--gamifikasi-rule-based-threshold--progression)
7. [Algoritma Agregasi Data & Deteksi Remedial (*Heuristic Stuck Detection*)](#7-algoritma-agregasi-data--deteksi-remedial-heuristic-stuck-detection)
8. [Algoritma Pencarian Teks Real-Time (*Case-Insensitive Substring Search*)](#8-algoritma-pencarian-teks-real-time-case-insensitive-substring-search)
9. [Algoritma Manajemen State & Checkpoint Sesi (*State Checkpointing & Sync*)](#9-algoritma-manajemen-state--checkpoint-sesi-state-checkpointing--sync)
10. [Tabel Pemetaan Algoritma ke Berkas Kode](#10-tabel-pemetaan-algoritma-ke-berkas-kode)

---

## 1. Ringkasan Algoritma & Metode Komputasi

Aplikasi **SiEja** mengombinasikan berbagai algoritma komputasi untuk mendukung proses belajar mengajar yang interaktif, aman, adaptif, serta andal baik secara *online* maupun *offline*.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ALGORITMA UTAMA SIEJA                           │
├────────────────────────────────────────────────────────────────────────┤
│ • Pengacakan & Distribusi Soal : Fisher-Yates Shuffle & Sampling       │
│ • Autentikasi Cepat & Aman     : SHA-256 Hash-Based Direct Lookup      │
│ • Manajemen Akun Otomatis      : Lowest Unassigned Integer (Auto-PIN)  │
│ • Validasi Jawaban Game        : Sequential Token & Character Matching │
│ • Evaluasi & Gamifikasi        : Rule-Based Threshold (Star Rating)    │
│ • Monitoring & Analisis Kelas  : Heuristic Aggregation (Stuck Alert)   │
│ • Pencarian Data               : Case-Insensitive Substring Matching   │
│ • Ketahanan Sesi Belajar       : Session State Checkpointing           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Algoritma Pengacakan & Komposisi Soal (*Fisher-Yates Shuffle & Random Sampling*)

### 📄 Berkas Terkait:
- `lib/services/stage_question_composer.dart`
- `lib/screens/student/stage_screen.dart`

### 💡 Deskripsi & Cara Kerja:
Algoritma pengacakan diterapkan untuk memastikan soal yang disajikan tidak monoton dan mencegah anak hanya menghafal urutan tombol/nomor soal.

1. **Pengacakan Soal (*Fisher-Yates / Knuth Shuffle*):**
   - Diimplementasikan melalui metode `List.shuffle(Random)`.
   - Mengocok daftar 10 soal aktif dengan kompleksitas waktu **$O(n)$** sebelum soal disajikan ke pemain.
2. **Pembangkitan Opsi Pengecoh (*Distractor Generation with Random Sampling*):**
   - Pada mini-game pilihan ganda (*dengar suara huruf, tebak gambar, huruf awal, huruf yang hilang*), sistem menyaring jawaban benar:
     $$\text{Kandidat Pengecoh} = \{ x \in \text{Kumpulan Data Stage} \mid x \neq \text{Jawaban Benar} \}$$
   - Kumpulan kandidat diacak, lalu diambil $k$ elemen pertama (*sampling*) dan digabungkan dengan jawaban benar sebelum dikocok kembali untuk tata letak tombol pilihan.
3. **Pembangkitan Urutan Huruf (*Anti-Sorted Validation Loop*):**
   - Pada mini-game `urutkanHuruf`, kepingan huruf acak disiapkan.
   - Sistem memiliki loop validasi untuk memastikan susunan huruf acak tidak identik dengan susunan alfabetis yang benar saat pertama kali ditampilkan:
     ```dart
     int shuffleAttempts = 0;
     while (_shuffledLetters.join('') == _choices.join('') &&
         _shuffledLetters.length > 1 &&
         shuffleAttempts < 10) {
       _shuffledLetters.shuffle(random);
       shuffleAttempts++;
     }
     ```

---

## 3. Algoritma Kriptografi & Hashing Kredensial (*SHA-256 Hashing Algorithm*)

### 📄 Berkas Terkait:
- `lib/utils/credential_helper.dart`
- `lib/services/firebase_service.dart`

### 💡 Deskripsi & Cara Kerja:
Untuk mendukung autentikasi siswa yang cepat dan aman tanpa harus melakukan pemindaian seluruh dokumen database (*full collection scan*), sistem menggunakan pemetaan berbasis **Hash SHA-256** (*Secure Hash Algorithm 256-bit*).

1. **Normalisasi & Pembentukan String Kredensial:**
   $$\text{Input String} = \text{lowercase}(\text{trim}(\text{username})) + \text{":"} + \text{PIN}$$
2. **Kalkulasi Digest SHA-256:**
   $$\text{Credential Key} = \text{SHA256}(\text{UTF8}(\text{Input String}))$$
3. **Direct Document Lookup:**
   - Kunci hash ini dijadikan `Document ID` pada koleksi Firestore `login_siswa`.
   - Waktu pencarian akun saat login bernilai konstan **$O(1)$** dan PIN tidak disimpan dalam bentuk teks mentah terbuka (*plain text*).

---

## 4. Algoritma Alokasi Slot Terkecil (*First-Fit / Lowest Unassigned Integer*)

### 📄 Berkas Terkait:
- `lib/services/firebase_service.dart` (Fungsi `generatePin()`)

### 💡 Deskripsi & Cara Kerja:
Digunakan pada modul pendaftaran murid oleh guru untuk menghasilkan PIN 3 digit secara otomatis (*Auto-PIN*) dengan memanfaatkan kembali slot angka terkecil yang kosong (*Greedy Slot Allocation*).

1. Sistem mengambil seluruh PIN yang terdaftar pada koleksi `siswa` dan menyimpannya dalam struktur data `Set<int>` (memungkinkan pengecekan $O(1)$).
2. Algoritma melakukan pencarian terurut mulai dari integer kandidat terkecil ($c = 1$):
   $$\text{Cari } c \in \mathbb{N}^+ \text{ terkecil sedemikian sehingga } c \notin \text{ExistingPins}$$
3. Hasilnya dikonversi menjadi string dengan *zero padding* 3 digit:
   $$\text{PIN} = \text{padLeft}(c, 3, \text{'0'})$$
   *Contoh:* Jika siswa dengan PIN `002` dihapus, pendaftaran berikutnya akan otomatis mendapatkan `002` kembali.

---

## 5. Algoritma Validasi & Pencocokan Karakter (*Sequential & Token Matching*)

### 📄 Berkas Terkait:
- `lib/screens/student/stage_screen.dart`
- `lib/screens/student/spell_guided_screen.dart`

### 💡 Deskripsi & Cara Kerja:
Digunakan untuk mengevaluasi ketepatan input pengguna pada berbagai jenis mini-game:

1. **Pencocokan Sekuensial Bertahap (*Sequential Character Matching*):**
   - Pada modul `SpellGuidedScreen`, sistem memeriksa karakter yang ditekan terhadap karakter target pada indeks kursor aktif:
     $$\text{isCorrect} = (\text{Input Letter} == \text{Kata}[\text{currentIndex}])$$
   - Memberikan umpan balik visual animasi getar (*shake animation*) jika salah dan lanjut ke indeks berikutnya jika benar.
2. **Pencocokan Rekonstruksi Token (*Token Join Matching*):**
   - Pada `susunKata` dan `urutkanHuruf`, array token karakter digabungkan kembali:
     $$\text{isCorrect} = (\text{join}(\text{UserAnswer}) == \text{join}(\text{TargetAnswer}))$$
3. **Penentuan Indeks Tengah Dinamis (*Dynamic Middle-Index Selection*):**
   - Pada `hurufYangHilang`, posisi huruf yang dihilangkan ditentukan melalui operasi pembagian bulat:
     $$\text{hiddenIndex} = \lfloor \text{length}(\text{kata}) / 2 \rfloor$$

---

## 6. Algoritma Penilaian & Gamifikasi (*Rule-Based Threshold & Progression*)

### 📄 Berkas Terkait:
- `lib/screens/student/reward_screen.dart`
- `lib/services/progress_service.dart`

### 💡 Deskripsi & Cara Kerja:
Sistem evaluasi mengadopsi mekanisme *Rule-Based Classification* untuk menentukan perolehan bintang serta status pembukaan stage:

1. **Klasifikasi Bintang (*Star Rating Mapping*):**
   $$\text{Bintang} = \begin{cases} 
      3, & \text{jika } \text{Skor} \ge 90 \\
      2, & \text{jika } 70 \le \text{Skor} < 90 \\
      1, & \text{jika } 50 \le \text{Skor} < 70 \\
      0, & \text{jika } \text{Skor} < 50 
   \end{cases}$$

2. **Aturan Pembukaan Level (*Stage Unlock Progression*):**
   - Stage 1 terbuka secara bawaan (*default unlocked*).
   - Stage $N+1$ akan beralih status dari `locked` menjadi `unlocked` jika Stage $N$ mencapai status `completed` atau jika dibuka secara manual oleh guru melalui portal guru.

---

## 7. Algoritma Agregasi Data & Deteksi Remedial (*Heuristic Stuck Detection*)

### 📄 Berkas Terkait:
- `lib/screens/teacher/teacher_dashboard_screen.dart`
- `lib/screens/teacher/progress_report_screen.dart`

### 💡 Deskripsi & Cara Kerja:
Membantu guru memantau performa kelas secara otomatis melalui kalkulasi agregat dan aturan heuristik:

1. **Heuristik Deteksi Siswa Perlu Perhatian (*Stuck Detection*):**
   - Sistem menandai siswa yang membutuhkan bimbingan khusus pada suatu stage jika:
     $$\text{isStuck} = (\text{Status} == \text{'completed'}) \land (\text{Skor} < 50)$$
2. **Pengurutan Prioritas Notifikasi (*Priority Comparator Sorting*):**
   - Notifikasi penyelesaian stage diurutkan berdasarkan status keterbacaan dengan fungsi komparator:
     ```dart
     notifs.sort((a, b) {
       if (a['isRead'] == b['isRead']) return 0;
       return (a['isRead'] as bool) ? 1 : -1;
     });
     ```
   - Memastikan notifikasi yang belum dibaca (*unread*) selalu berada di puncak daftar.

---

## 8. Algoritma Pencarian Teks Real-Time (*Case-Insensitive Substring Search*)

### 📄 Berkas Terkait:
- `lib/screens/teacher/student_list_screen.dart`
- `lib/screens/teacher/progress_report_screen.dart`

### 💡 Deskripsi & Cara Kerja:
Pencarian cepat nama siswa atau username pada daftar murid:

1. Kueri pencarian dari `TextEditingController` dinormalisasi ke huruf kecil (*lowercase*).
2. Filter linier diterapkan pada kumpulan data siswa:
   $$\text{Hasil} = \{ s \in \text{Students} \mid \text{lowercase}(s.\text{nama}).\text{contains}(q) \lor \text{lowercase}(s.\text{username}).\text{contains}(q) \}$$
3. Memberikan pengalaman pencarian instan (*real-time reactive filtering*) tanpa *lag* UI.

---

## 9. Algoritma Manajemen State & Checkpoint Sesi (*State Checkpointing & Sync*)

### 📄 Berkas Terkait:
- `lib/services/progress_service.dart`
- `lib/screens/student/stage_screen.dart`

### 💡 Deskripsi & Cara Kerja:
Mencegah kehilangan progres belajar saat aplikasi tertutup tiba-tiba serta mencegah manipulasi skor (*anti-cheat / progress saver*):

1. **Siklus Checkpoint (*AppLifecycleState Listener*):**
   - Saat state aplikasi berpindah ke `paused` atau `inactive`, indeks soal aktif `_currentQuestion`, nilai sementara `_score`, dan susunan soal acak `_questions` disimpan ke penyimpanan lokal (`SharedPreferences`/`SQLite`).
2. **Mekanisme Pemulihan (*Resume Session*):**
   - Saat siswa membuka kembali stage yang sama, aplikasi mendeteksi keberadaan draf aktif dan langsung memulihkan posisi soal terakhir tanpa mereset skor dari awal.
3. **Pembersihan Draf (*Draft Clearing*):**
   - Setelah soal ke-10 selesai dikerjakan, draf dihapus dan nilai final disimpan secara permanen ke Firebase Firestore dan cache lokal.

---

## 10. Tabel Pemetaan Algoritma ke Berkas Kode

| No | Nama Algoritma / Metode | Lokasi Berkas Utama | Fungsi dalam Aplikasi |
| :---: | :--- | :--- | :--- |
| **1** | **Fisher-Yates Shuffle & Sampling** | `lib/services/stage_question_composer.dart`<br>`lib/screens/student/stage_screen.dart` | Mengacak 10 soal stage, memilih distraktor pengecoh, dan mengacak kepingan huruf. |
| **2** | **SHA-256 Cryptographic Hash** | `lib/utils/credential_helper.dart`<br>`lib/services/firebase_service.dart` | Mengenkripsi kombinasi username+PIN menjadi kunci indeks unik Firestore $O(1)$. |
| **3** | **First-Fit / Lowest Unassigned Integer** | `lib/services/firebase_service.dart` | Mengalokasikan nomor PIN 3 digit terkecil yang kosong secara otomatis. |
| **4** | **Sequential & Token Matching** | `lib/screens/student/stage_screen.dart`<br>`lib/screens/student/spell_guided_screen.dart` | Validasi jawaban di 7 tipe mini-game dan pengejaan kata berurutan. |
| **5** | **Rule-Based Threshold Classification** | `lib/screens/student/reward_screen.dart`<br>`lib/services/progress_service.dart` | Konversi skor akhir menjadi bintang (⭐ 1-3) dan pembukaan stage berikutnya. |
| **6** | **Heuristic Data Aggregation & Stuck Detection** | `lib/screens/teacher/teacher_dashboard_screen.dart`<br>`lib/screens/teacher/progress_report_screen.dart` | Rekapitulasi nilai kelas dan deteksi otomatis siswa yang membutuhkan remedial. |
| **7** | **Case-Insensitive Substring Search** | `lib/screens/teacher/student_list_screen.dart`<br>`lib/screens/teacher/progress_report_screen.dart` | Penyaringan dan pencarian instan nama/username siswa di portal guru. |
| **8** | **Session State Checkpointing** | `lib/services/progress_service.dart`<br>`lib/screens/student/stage_screen.dart` | Penyimpanan draf progres sementara untuk melanjutkan sesi permainan (*resume*). |

---
*Dokumen ini disusun untuk keperluan dokumentasi teknis, laporan tugas akhir / skripsi, serta publikasi ilmiah aplikasi **SiEja**.*
