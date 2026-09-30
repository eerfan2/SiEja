import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:si_eja/services/firebase_service.dart';

class ProgressService {
  // Singleton pattern
  static final ProgressService _instance = ProgressService._internal();

  factory ProgressService() {
    return _instance;
  }

  ProgressService._internal();

  late SharedPreferences _prefs;
  String _currentSiswaId = '';
  String _currentJenisKelamin = '';

  // Harus dipanggil saat inisialisasi aplikasi (contoh di main.dart)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentSiswaId = _prefs.getString('currentSiswaId') ?? '';
    _currentJenisKelamin = _prefs.getString('currentJenisKelamin') ?? '';
  }

  // Helper key generator agar data tiap akun siswa terpisah berdasarkan ID
  String _getScoreKey(int stageId) {
    if (_currentSiswaId.isNotEmpty) {
      return 'score_${_currentSiswaId}_stage_$stageId';
    }
    return 'score_stage_$stageId';
  }

  String _getStatusKey(int stageId) {
    if (_currentSiswaId.isNotEmpty) {
      return 'status_${_currentSiswaId}_stage_$stageId';
    }
    return 'status_stage_$stageId';
  }

  String _getDraftKey(int stageId) {
    if (_currentSiswaId.isNotEmpty) {
      return 'draft_${_currentSiswaId}_stage_$stageId';
    }
    return 'draft_stage_$stageId';
  }

  // Setter
  void setCurrentSiswa(String siswaId, String jenisKelamin) {
    _currentSiswaId = siswaId;
    _currentJenisKelamin = jenisKelamin;
    // Simpan ke SharedPreferences
    _prefs.setString('currentSiswaId', siswaId);
    _prefs.setString('currentJenisKelamin', jenisKelamin);
  }

  // Getter
  String get currentSiswaId => _currentSiswaId;
  String get currentJenisKelamin => _currentJenisKelamin;

  Future<void> saveStudent(String nama, String pin) async {
    await _prefs.setString('student_name', nama);
    await _prefs.setString('student_pin', pin);
  }

  String getStudentName() {
    return _prefs.getString('student_name') ?? '';
  }

  String getStudentPin() {
    return _prefs.getString('student_pin') ?? '';
  }

  // Sinkronisasi data progress dari Firebase milik siswa yang sedang login
  Future<void> loadStudentProgressFromFirebase(Map<String, dynamic> siswaData) async {
    final progress = siswaData['progress'] as Map<String, dynamic>? ?? {};
    for (int stageId = 1; stageId <= 6; stageId++) {
      final stageKey = 'stage$stageId';
      if (progress.containsKey(stageKey) && progress[stageKey] != null) {
        final stageData = Map<String, dynamic>.from(progress[stageKey]);
        final skor = (stageData['skor'] as num?)?.toInt() ?? 0;
        final status = stageData['status'] as String? ?? 'locked';
        await _prefs.setInt(_getScoreKey(stageId), skor);
        await _prefs.setString(_getStatusKey(stageId), status);
      } else {
        await _prefs.remove(_getScoreKey(stageId));
        await _prefs.remove(_getStatusKey(stageId));
      }
    }
  }

  Future<void> saveStageScore(int stageId, int score) async {
    await _prefs.setInt(_getScoreKey(stageId), score);
    // Jika siswa menyimpan skor (selesai mengerjakan), maka statusnya menjadi completed
    await _prefs.setString(_getStatusKey(stageId), 'completed');

    if (_currentSiswaId.isNotEmpty) {
      await FirebaseService().saveProgress(
        _currentSiswaId,
        stageId,
        score,
        'completed',
      );
    }
  }

  int getStageScore(int stageId) {
    return _prefs.getInt(_getScoreKey(stageId)) ?? 0;
  }

  String getStageStatus(int stageId) {
    final savedStatus = _prefs.getString(_getStatusKey(stageId));
    if (savedStatus != null) {
      return savedStatus;
    }
    if (stageId == 1) return 'unlocked';
    return 'locked';
  }

  bool isStageUnlocked(int stageId) {
    final status = getStageStatus(stageId);
    // Stage bisa diakses jika statusnya unlocked atau completed
    return status == 'unlocked' || status == 'completed';
  }

  // HANYA guru yang memanggil method ini
  Future<void> unlockStageByTeacher(int stageId) async {
    await _prefs.setString(_getStatusKey(stageId), 'unlocked');
  }

  // Guru bisa mengunci kembali stage jika perlu
  Future<void> lockStageByTeacher(int stageId) async {
    await _prefs.setString(_getStatusKey(stageId), 'locked');
  }

  // --- DRAFT STAGE PROGRESS (Tersimpan otomatis saat keluar dari stage) ---

  Future<void> saveDraftStageProgress({
    required int stageId,
    required int currentQuestion,
    required int score,
    required List<Map<String, dynamic>> questions,
  }) async {
    final draftData = {
      'currentQuestion': currentQuestion,
      'score': score,
      'questions': questions.map((q) => {
        'typeIndex': (q['type'] as Enum).index,
        'kata': q['kata'],
        'huruf': q['huruf'],
      }).toList(),
    };
    await _prefs.setString(_getDraftKey(stageId), jsonEncode(draftData));
  }

  Map<String, dynamic>? getDraftStageProgress(int stageId) {
    final raw = _prefs.getString(_getDraftKey(stageId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final questionsRaw = decoded['questions'] as List<dynamic>;
      final questions = questionsRaw.map((item) {
        final mapItem = Map<String, dynamic>.from(item as Map);
        return {
          'typeIndex': mapItem['typeIndex'] as int,
          'kata': mapItem['kata'] as String,
          'huruf': mapItem['huruf'] as String,
        };
      }).toList();

      return {
        'currentQuestion': decoded['currentQuestion'] as int,
        'score': decoded['score'] as int,
        'questions': questions,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDraftStageProgress(int stageId) async {
    await _prefs.remove(_getDraftKey(stageId));
  }

  Future<void> resetStageProgress(int stageId) async {
    await _prefs.remove(_getScoreKey(stageId));
    await clearDraftStageProgress(stageId);
    // Selalu set ke 'unlocked' agar siswa dapat langsung memainkan ulang
    // stage yang di-reset guru, tanpa perlu mengulang dari stage 1.
    await _prefs.setString(_getStatusKey(stageId), 'unlocked');
  }

  Future<void> resetAllProgress() async {
    // Reset skor, status, dan draf stage 1 sampai 6 untuk siswa yang aktif
    for (int i = 1; i <= 6; i++) {
      await _prefs.remove(_getScoreKey(i));
      await _prefs.remove(_getStatusKey(i));
      await clearDraftStageProgress(i);
    }
  }

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

  // Ambil daftar siswa yang pernah login (berdasarkan data tersimpan)
  List<Map<String, dynamic>> getAllStudents() {
    final name = _prefs.getString('student_name') ?? '';
    if (name.isEmpty) return [];

    // Cek apakah siswa punya progress (ada skor di stage manapun)
    bool hasProgress = false;
    for (int i = 1; i <= 6; i++) {
      if (_prefs.containsKey(_getScoreKey(i))) {
        hasProgress = true;
        break;
      }
    }

    return [
      {
        'name': name,
        'hasProgress': hasProgress,
      }
    ];
  }

  // Ambil list key notifikasi yang sudah dibaca
  List<String> getReadNotifications() {
    return _prefs.getStringList('read_notification_keys') ?? [];
  }

  // Tandai notifikasi tertentu atau semua sebagai sudah dibaca
  Future<void> markNotificationAsRead(String notifKey) async {
    final keys = getReadNotifications();
    if (!keys.contains(notifKey)) {
      keys.add(notifKey);
      await _prefs.setStringList('read_notification_keys', keys);
    }
  }

  Future<void> markAllNotificationsAsRead(List<String> notifKeys) async {
    final keys = getReadNotifications();
    for (final k in notifKeys) {
      if (!keys.contains(k)) {
        keys.add(k);
      }
    }
    await _prefs.setStringList('read_notification_keys', keys);
  }
}
