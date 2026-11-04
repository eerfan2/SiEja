import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:si_eja/utils/credential_helper.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===== AUTH GURU =====

  // Login guru dengan email & password
  Future<bool> loginGuru(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Logout guru
  Future<void> logoutGuru() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout guru error: $e');
      }
    }
  }

  // Ubah kata sandi guru yang sedang login
  Future<String?> ubahKataSandiGuru(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return 'Sesi login guru tidak ditemukan. Silakan login kembali.';
      }

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword.trim());
      return null; // Berhasil
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Kata sandi saat ini yang Anda masukkan salah.';
      } else if (e.code == 'weak-password') {
        return 'Kata sandi baru terlalu lemah (minimal 6 karakter).';
      }
      return 'Gagal mengubah kata sandi: ${e.message}';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // Cek apakah guru sudah login
  bool get isGuruLoggedIn => _auth.currentUser != null;

  // ===== MANAJEMEN SISWA =====

  // Tambah siswa baru (Return null jika sukses, atau pesan error jika gagal)
  Future<String?> tambahSiswa({
    required String namaLengkap,
    required String username,
    required String pin,
    required int usia,
    required String jenisKelamin,
  }) async {
    try {
      // Cek username sudah ada atau belum
      final existing = await _firestore
          .collection('siswa')
          .where('username', isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) {
        return 'Username sudah digunakan!';
      }

      // Cek PIN sudah digunakan siswa lain atau belum
      final existingPin = await _firestore
          .collection('siswa')
          .where('pin', isEqualTo: pin.trim())
          .get();

      if (existingPin.docs.isNotEmpty) {
        return 'PIN ${pin.trim()} sudah digunakan siswa lain!';
      }

      final docRef = await _firestore.collection('siswa').add({
        'namaLengkap': namaLengkap,
        'username': username,
        'pin': pin,
        'usia': usia,
        'jenisKelamin': jenisKelamin,
        'createdAt': FieldValue.serverTimestamp(),
        'progress': {},
      });

      // Tambahkan ke mapping login_siswa
      final credentialKey =
          CredentialHelper.generateCredentialKey(username, pin);
      await _firestore.collection('login_siswa').doc(credentialKey).set({
        'siswaId': docRef.id,
        'username': username.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Sukses
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Tambah siswa FirebaseException: ${e.code}');
      }
      return 'Gagal menambahkan siswa: ${e.code}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Tambah siswa error: $e');
      }
      return 'Gagal menambahkan siswa: $e';
    }
  }

  // Edit data siswa (Return null jika sukses, atau pesan error jika gagal)
  Future<String?> editSiswa({
    required String siswaId,
    required String namaLengkap,
    required String username,
    required String pin,
    required int usia,
    required String jenisKelamin,
    required String oldUsername,
    required String oldPin,
  }) async {
    try {
      // 1. Cek otorisasi guru
      if (!isGuruLoggedIn) {
        return 'Hanya guru yang berwenang untuk mengubah data siswa!';
      }

      final trimmedNama = namaLengkap.trim();
      final trimmedUsername = username.trim();
      final trimmedPin = pin.trim();

      // 2. Validasi input
      if (trimmedNama.isEmpty || trimmedUsername.isEmpty) {
        return 'Nama lengkap dan username tidak boleh kosong!';
      }
      if (trimmedPin.length != 3 || int.tryParse(trimmedPin) == null) {
        return 'PIN harus berupa 3 digit angka (contoh: 001)!';
      }
      if (usia <= 0) {
        return 'Usia harus berupa angka positif!';
      }

      // 3. Cek keunikan username jika username diubah
      if (trimmedUsername.toLowerCase() != oldUsername.trim().toLowerCase()) {
        final existing = await _firestore
            .collection('siswa')
            .where('username', isEqualTo: trimmedUsername)
            .get();

        final isTakenByOther = existing.docs.any((doc) => doc.id != siswaId);
        if (isTakenByOther) {
          return 'Username sudah digunakan siswa lain!';
        }
      }

      // 3b. Cek keunikan PIN jika PIN diubah
      if (trimmedPin != oldPin.trim()) {
        final existingPin = await _firestore
            .collection('siswa')
            .where('pin', isEqualTo: trimmedPin)
            .get();

        final isPinTaken = existingPin.docs.any((doc) => doc.id != siswaId);
        if (isPinTaken) {
          return 'PIN $trimmedPin sudah digunakan siswa lain!';
        }
      }

      // 4. Hitung credential key lama dan baru
      final oldCredentialKey =
          CredentialHelper.generateCredentialKey(oldUsername, oldPin);
      final newCredentialKey =
          CredentialHelper.generateCredentialKey(trimmedUsername, trimmedPin);

      // 4b. Pastikan kredensial tujuan pada login_siswa tidak digunakan oleh siswa lain
      if (oldCredentialKey != newCredentialKey) {
        final existingLoginDoc = await _firestore
            .collection('login_siswa')
            .doc(newCredentialKey)
            .get();
        if (existingLoginDoc.exists) {
          final mappedSiswaId = existingLoginDoc.data()?['siswaId'];
          if (mappedSiswaId != null && mappedSiswaId != siswaId) {
            return 'Kredensial login (kombinasi username dan PIN) sudah digunakan oleh siswa lain!';
          }
        }
      }

      final batch = _firestore.batch();
      final siswaDocRef = _firestore.collection('siswa').doc(siswaId);

      // 5. Update parsial dokumen siswa (MEMPERTAHANKAN progress, createdAt, dan id)
      batch.update(siswaDocRef, {
        'namaLengkap': trimmedNama,
        'username': trimmedUsername,
        'pin': trimmedPin,
        'usia': usia,
        'jenisKelamin': jenisKelamin.toLowerCase(),
      });

      // 6. Sinkronisasi mapping login_siswa secara atomik
      if (oldCredentialKey != newCredentialKey) {
        batch.delete(_firestore.collection('login_siswa').doc(oldCredentialKey));
        batch.set(_firestore.collection('login_siswa').doc(newCredentialKey), {
          'siswaId': siswaId,
          'username': trimmedUsername.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.set(
          _firestore.collection('login_siswa').doc(newCredentialKey),
          {
            'siswaId': siswaId,
            'username': trimmedUsername.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      return null; // Sukses
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Edit siswa FirebaseException: ${e.code}');
      }
      return 'Gagal memperbarui data siswa: ${e.code}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Edit siswa error: $e');
      }
      return 'Gagal memperbarui data siswa: $e';
    }
  }

  // Ambil semua siswa
  Future<List<Map<String, dynamic>>> getAllSiswa() async {
    try {
      final snapshot = await _firestore
          .collection('siswa')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Get siswa error: $e');
      return [];
    }
  }

  // Hapus siswa
  Future<bool> hapusSiswa(String siswaId) async {
    try {
      final doc = await _firestore.collection('siswa').doc(siswaId).get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final username = data['username'] as String?;
      final pin = data['pin'] as String?;

      final batch = _firestore.batch();

      // Hapus data utama siswa
      batch.delete(_firestore.collection('siswa').doc(siswaId));

      // Hapus data login_siswa jika credential tersedia
      if (username != null && pin != null) {
        final credentialKey =
            CredentialHelper.generateCredentialKey(username, pin);
        batch.delete(_firestore.collection('login_siswa').doc(credentialKey));
      }

      await batch.commit();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Hapus siswa error: $e');
      }
      return false;
    }
  }

  // Generate PIN otomatis (001, 002, dst) mengisi nomor terkecil yang belum digunakan
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

  // ===== LOGIN SISWA =====

  // Login siswa dengan username & PIN
  Future<Map<String, dynamic>?> loginSiswa(String username, String pin) async {
    try {
      final credentialKey =
          CredentialHelper.generateCredentialKey(username, pin);

      final loginDoc = await _firestore
          .collection('login_siswa')
          .doc(credentialKey)
          .get(const GetOptions(source: Source.server));

      if (!loginDoc.exists) {
        return null; // Username atau PIN salah (credential tidak ada)
      }

      final siswaId = loginDoc.data()?['siswaId'] as String?;
      if (siswaId == null) return null;

      final siswaDoc = await _firestore
          .collection('siswa')
          .doc(siswaId)
          .get(const GetOptions(source: Source.server));

      if (!siswaDoc.exists) return null;

      return {
        'id': siswaDoc.id,
        ...siswaDoc.data()!,
      };
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Login siswa FirebaseException: ${e.code}');
      }
      if (e.code == 'permission-denied') {
        throw Exception('permission-denied');
      } else if (e.code == 'unavailable' ||
          e.code == 'network-request-failed') {
        throw Exception('unavailable');
      }
      throw Exception(e.code);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login siswa error: $e');
      }
      throw Exception('unknown');
    }
  }

  // ===== PROGRESS SISWA =====

  // Simpan progress stage siswa
  Future<void> saveProgress(
    String siswaId,
    int stageId,
    int skor,
    String status,
  ) async {
    try {
      await _firestore.collection('siswa').doc(siswaId).update({
        'progress.stage$stageId': {
          'skor': skor,
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('Save progress error: $e');
    }
  }

  // Ambil progress siswa
  Future<Map<String, dynamic>> getProgress(String siswaId) async {
    try {
      final doc = await _firestore.collection('siswa').doc(siswaId).get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      return data['progress'] ?? {};
    } catch (e) {
      debugPrint('Get progress error: $e');
      return {};
    }
  }

  // Reset progress siswa (seluruh stage)
  Future<void> resetProgress(String siswaId) async {
    try {
      await _firestore
          .collection('siswa')
          .doc(siswaId)
          .update({'progress': {}});
    } catch (e) {
      debugPrint('Reset progress error: $e');
    }
  }

  // Reset progress stage tertentu dari siswa (remedial per-stage).
  // Menyimpan skor:0 + status:'unlocked' — bukan menghapus field —
  // agar saat siswa login berikutnya, stage tetap terbaca sebagai 'unlocked'
  // dan tidak jatuh ke fallback 'locked'.
  Future<void> resetStageProgress(String siswaId, int stageId) async {
    try {
      await _firestore.collection('siswa').doc(siswaId).update({
        'progress.stage$stageId': {
          'skor': 0,
          'status': 'unlocked',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('Reset stage progress error: $e');
    }
  }

  // Reset progress semua siswa
  Future<void> resetAllProgress() async {
    try {
      final snapshot = await _firestore.collection('siswa').get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'progress': {}});
      }
    } catch (e) {
      debugPrint('Reset all progress error: $e');
    }
  }

  // ===== UNLOCK LEVEL =====

  // Unlock stage untuk semua siswa
  Future<void> unlockStageAllSiswa(int stageId) async {
    try {
      final snapshot = await _firestore.collection('siswa').get();

      for (final doc in snapshot.docs) {
        final progress = doc.data()['progress'] ?? {};
        final stageKey = 'stage$stageId';

        if (progress[stageKey] == null ||
            progress[stageKey]['status'] == 'locked') {
          await doc.reference.update({
            'progress.$stageKey': {
              'skor': 0,
              'status': 'unlocked',
            },
          });
        }
      }
    } catch (e) {
      debugPrint('Unlock stage error: $e');
    }
  }

  // Lock stage untuk semua siswa
  Future<void> lockStageAllSiswa(int stageId) async {
    try {
      final snapshot = await _firestore.collection('siswa').get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'progress.stage$stageId': {
            'skor': 0,
            'status': 'locked',
          },
        });
      }
    } catch (e) {
      debugPrint('Lock stage error: $e');
    }
  }

  // ===== MIGRATION SCRIPT =====

  // Script internal untuk membuat mapping login_siswa untuk semua siswa existing jika dibutuhkan (development/internal)
  Future<void> migrateExistingStudentsToLoginMapping() async {
    try {
      final snapshot = await _firestore.collection('siswa').get();
      final batch = _firestore.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = data['username'] as String?;
        final pin = data['pin'] as String?;

        if (username != null && pin != null) {
          final credentialKey =
              CredentialHelper.generateCredentialKey(username, pin);

          batch.set(
            _firestore.collection('login_siswa').doc(credentialKey),
            {
              'siswaId': doc.id,
              'username': username.trim().toLowerCase(),
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          count++;
          if (count % 400 == 0) {
            // Limit firestore batch is 500
            await batch.commit();
          }
        }
      }

      if (count % 400 != 0) {
        await batch.commit();
      }

      if (kDebugMode) {
        debugPrint('Migration complete: $count students mapped.');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Migration FirebaseException: ${e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Migration error: $e');
      }
    }
  }
}
