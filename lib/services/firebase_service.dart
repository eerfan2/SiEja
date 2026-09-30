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
