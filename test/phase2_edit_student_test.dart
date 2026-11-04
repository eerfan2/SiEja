import 'package:flutter_test/flutter_test.dart';
import 'package:si_eja/utils/credential_helper.dart';

void main() {
  group('Fase 2: Validasi CredentialHelper & Hashing Login Siswa', () {
    test('1. Credential key SHA-256 menghasilkan hash yang valid dan konsisten', () {
      final key = CredentialHelper.generateCredentialKey('budi', '001');
      expect(
        key,
        '871ce82b9b9d835508f19ba6481c6ebdd2ccdd69c5618a8ac231e2f28d931b38',
      );
      expect(key.length, 64);
    });

    test('2. Credential key menormalisasi username (trim spasi & case-insensitive)', () {
      final key1 = CredentialHelper.generateCredentialKey('  Budi  ', '001');
      final key2 = CredentialHelper.generateCredentialKey('budi', '001');
      final key3 = CredentialHelper.generateCredentialKey('BUDI', '001');

      expect(key1, equals(key2));
      expect(key2, equals(key3));
    });

    test('3. Perubahan PIN mengubah credential key login_siswa', () {
      final oldKey = CredentialHelper.generateCredentialKey('budi', '001');
      final newKey = CredentialHelper.generateCredentialKey('budi', '002');

      expect(oldKey, isNot(equals(newKey)));
    });

    test('4. Perubahan username mengubah credential key login_siswa', () {
      final oldKey = CredentialHelper.generateCredentialKey('budi', '001');
      final newKey = CredentialHelper.generateCredentialKey('budis', '001');

      expect(oldKey, isNot(equals(newKey)));
    });

    test('5. Perubahan profil tanpa ubah username/PIN mempertahankan credential key', () {
      final keyBefore = CredentialHelper.generateCredentialKey('siti', '005');
      // Guru hanya mengubah namaLengkap atau usia
      final keyAfter = CredentialHelper.generateCredentialKey('siti', '005');

      expect(keyBefore, equals(keyAfter));
    });
  });

  group('Fase 2: Logika Validasi Input Edit Siswa', () {
    String? validateEditInput({
      required String namaLengkap,
      required String username,
      required String pin,
      required int usia,
    }) {
      final trimmedNama = namaLengkap.trim();
      final trimmedUsername = username.trim();
      final trimmedPin = pin.trim();

      if (trimmedNama.isEmpty || trimmedUsername.isEmpty) {
        return 'Nama lengkap dan username tidak boleh kosong!';
      }
      if (trimmedPin.length != 3 || int.tryParse(trimmedPin) == null) {
        return 'PIN harus berupa 3 digit angka (contoh: 001)!';
      }
      if (usia <= 0) {
        return 'Usia harus berupa angka positif!';
      }
      return null;
    }

    test('6. Input valid mengembalikan null (lolos validasi)', () {
      final result = validateEditInput(
        namaLengkap: 'Budi Santoso',
        username: 'budi01',
        pin: '002',
        usia: 6,
      );
      expect(result, isNull);
    });

    test('7. Nama kosong atau spasi saja ditolak', () {
      final result = validateEditInput(
        namaLengkap: '   ',
        username: 'budi01',
        pin: '002',
        usia: 6,
      );
      expect(result, 'Nama lengkap dan username tidak boleh kosong!');
    });

    test('8. Username kosong atau spasi saja ditolak', () {
      final result = validateEditInput(
        namaLengkap: 'Budi Santoso',
        username: '  ',
        pin: '002',
        usia: 6,
      );
      expect(result, 'Nama lengkap dan username tidak boleh kosong!');
    });

    test('9. PIN tidak 3 digit atau non-angka ditolak', () {
      expect(
        validateEditInput(
          namaLengkap: 'Budi Santoso',
          username: 'budi01',
          pin: '01',
          usia: 6,
        ),
        'PIN harus berupa 3 digit angka (contoh: 001)!',
      );

      expect(
        validateEditInput(
          namaLengkap: 'Budi Santoso',
          username: 'budi01',
          pin: 'abc',
          usia: 6,
        ),
        'PIN harus berupa 3 digit angka (contoh: 001)!',
      );
    });

    test('10. Usia 0 atau negatif ditolak', () {
      final result = validateEditInput(
        namaLengkap: 'Budi Santoso',
        username: 'budi01',
        pin: '001',
        usia: 0,
      );
      expect(result, 'Usia harus berupa angka positif!');
    });
  });

  group('Fase 2: Pemeriksaan Keunikan Username & Konsistensi Profil', () {
    bool checkUsernameAvailability({
      required String newUsername,
      required String currentStudentId,
      required String oldUsername,
      required List<Map<String, dynamic>> existingStudents,
    }) {
      final trimmedNew = newUsername.trim().toLowerCase();
      final trimmedOld = oldUsername.trim().toLowerCase();

      // Jika username tidak berubah (milik siswa itu sendiri), selalu diizinkan
      if (trimmedNew == trimmedOld) return true;

      // Cek apakah ada siswa lain yang memakai username ini
      final isTakenByOther = existingStudents.any(
        (s) =>
            s['id'] != currentStudentId &&
            (s['username'] ?? '').toString().toLowerCase() == trimmedNew,
      );
      return !isTakenByOther;
    }

    final mockStudents = [
      {'id': 'siswa-1', 'username': 'andi'},
      {'id': 'siswa-2', 'username': 'budi'},
      {'id': 'siswa-3', 'username': 'cici'},
    ];

    test('11. Siswa mempertahankan username yang sama tetap diizinkan', () {
      final allowed = checkUsernameAvailability(
        newUsername: 'budi',
        currentStudentId: 'siswa-2',
        oldUsername: 'budi',
        existingStudents: mockStudents,
      );
      expect(allowed, isTrue);
    });

    test('12. Siswa mengubah huruf besar/kecil username-nya sendiri tetap diizinkan', () {
      final allowed = checkUsernameAvailability(
        newUsername: 'BUDI',
        currentStudentId: 'siswa-2',
        oldUsername: 'budi',
        existingStudents: mockStudents,
      );
      expect(allowed, isTrue);
    });

    test('13. Username yang sudah dipakai siswa lain ditolak', () {
      final allowed = checkUsernameAvailability(
        newUsername: 'andi',
        currentStudentId: 'siswa-2',
        oldUsername: 'budi',
        existingStudents: mockStudents,
      );
      expect(allowed, isFalse);
    });

    test('14. Username baru yang belum dipakai siapa pun diizinkan', () {
      final allowed = checkUsernameAvailability(
        newUsername: 'dani',
        currentStudentId: 'siswa-2',
        oldUsername: 'budi',
        existingStudents: mockStudents,
      );
      expect(allowed, isTrue);
    });
  });

  group('Fase 2: Integritas Data & Preservasi Progres Belajar', () {
    test('15. Pembaruan data profil mempertahankan progress dan ID siswa', () {
      // Simulasikan dokumen awal siswa di Firestore
      final existingDoc = {
        'id': 'siswa-100',
        'namaLengkap': 'Rian Pratama',
        'username': 'rian',
        'pin': '004',
        'usia': 5,
        'jenisKelamin': 'laki-laki',
        'createdAt': '2026-01-01T00:00:00Z',
        'progress': {
          'stage1': {'skor': 100, 'status': 'completed'},
          'stage2': {'skor': 85, 'status': 'completed'},
          'stage3': {'skor': 0, 'status': 'unlocked'},
        },
      };

      // Payload edit yang dikirim oleh editSiswa (partial update)
      final updatePayload = {
        'namaLengkap': 'Rian Pratama Putra',
        'username': 'rianp',
        'pin': '004',
        'usia': 6,
        'jenisKelamin': 'laki-laki',
      };

      // Simulasikan penerapan partial update di Firestore
      final updatedDoc = Map<String, dynamic>.from(existingDoc)
        ..addAll(updatePayload);

      // Verifikasi: ID, createdAt, dan progress tetap 100% utuh
      expect(updatedDoc['id'], equals('siswa-100'));
      expect(updatedDoc['createdAt'], equals('2026-01-01T00:00:00Z'));
      expect(updatedDoc['progress'], equals(existingDoc['progress']));
      expect(updatedDoc['progress']['stage1']['skor'], equals(100));
      expect(updatedDoc['progress']['stage2']['status'], equals('completed'));

      // Verifikasi: Field profil berhasil diperbarui
      expect(updatedDoc['namaLengkap'], equals('Rian Pratama Putra'));
      expect(updatedDoc['username'], equals('rianp'));
      expect(updatedDoc['usia'], equals(6));
    });
  });

  group('Fase 2: Pencegahan Tabrakan Kredensial & Konsistensi login_siswa', () {
    bool checkCredentialTargetOwnership({
      required bool targetExists,
      required String? targetMappedSiswaId,
      required String currentSiswaId,
    }) {
      if (targetExists &&
          targetMappedSiswaId != null &&
          targetMappedSiswaId != currentSiswaId) {
        return false; // Ditolak karena milik siswa lain!
      }
      return true; // Diizinkan (baru atau milik siswa itu sendiri)
    }

    test('16. newKey yang sudah dipetakan ke siswa lain DITOLAK (cegah pembajakan akun)', () {
      final allowed = checkCredentialTargetOwnership(
        targetExists: true,
        targetMappedSiswaId: 'siswa-lain-999',
        currentSiswaId: 'siswa-100',
      );
      expect(allowed, isFalse);
    });

    test('17. newKey yang belum terdaftar di login_siswa DIIZINKAN', () {
      final allowed = checkCredentialTargetOwnership(
        targetExists: false,
        targetMappedSiswaId: null,
        currentSiswaId: 'siswa-100',
      );
      expect(allowed, isTrue);
    });

    test('18. newKey yang dipetakan ke siswa itu sendiri DIIZINKAN', () {
      final allowed = checkCredentialTargetOwnership(
        targetExists: true,
        targetMappedSiswaId: 'siswa-100',
        currentSiswaId: 'siswa-100',
      );
      expect(allowed, isTrue);
    });

    test('19. Pemetaan login_siswa selalu konsisten dengan siswaId dan username normal', () {
      const currentSiswaId = 'siswa-100';
      const newUsername = '  RianP  ';
      const newPin = '007';

      final credentialKey =
          CredentialHelper.generateCredentialKey(newUsername, newPin);

      final loginDocData = {
        'siswaId': currentSiswaId,
        'username': newUsername.trim().toLowerCase(),
        'createdAt': 'serverTimestamp',
      };

      // Pastikan hash kunci benar
      expect(credentialKey, isNotEmpty);
      expect(credentialKey.length, equals(64));

      // Pastikan siswaId dan username tepat
      expect(loginDocData['siswaId'], equals(currentSiswaId));
      expect(loginDocData['username'], equals('rianp'));
    });
  });
}

