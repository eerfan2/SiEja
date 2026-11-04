import 'package:cloud_firestore/cloud_firestore.dart';

/// Model yang merepresentasikan satu dokumen dalam collection `material_catalog` Firestore.
///
/// Menyimpan metadata kata/objek, path Firebase Storage untuk gambar objek dan
/// audio kata utuh, serta ID audio huruf bawaan A–Z yang dipilih oleh guru.
class MaterialModel {
  /// ID dokumen Firestore
  final String id;

  /// Nama kata/objek yang ditampilkan, contoh: 'BOLA', 'JERAPAH'.
  final String word;

  /// Kata dalam format normalisasi (trim + lowercase), contoh: 'bola', 'jerapah'.
  final String normalizedWord;

  /// Huruf awal sebenarnya dari kata (uppercase A–Z), contoh: 'B'.
  final String initialLetter;

  /// ID huruf A–Z untuk audio pelafalan huruf bawaan yang dipilih guru.
  /// Memetakan ke `AppAudio.huruf(letterAudioId.toLowerCase())`.
  final String letterAudioId;

  /// Path objek di Firebase Storage untuk gambar, contoh:
  /// `material_catalog/{materialId}/image_12345.png`
  final String imagePath;

  /// Path objek di Firebase Storage untuk audio kata utuh, contoh:
  /// `material_catalog/{materialId}/word_12345.mp3`
  final String wordAudioPath;

  /// Status aktif materi katalog.
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const MaterialModel({
    required this.id,
    required this.word,
    required this.normalizedWord,
    required this.initialLetter,
    required this.letterAudioId,
    required this.imagePath,
    required this.wordAudioPath,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Factory constructor dari Firestore [DocumentSnapshot].
  static MaterialModel? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return fromMap(data, doc.id);
  }

  /// Factory constructor dari Map data (bisa digunakan untuk mock & testing).
  static MaterialModel? fromMap(Map<String, dynamic> data, String id) {
    try {
      final word = (data['word'] as String?)?.trim() ?? '';
      if (word.isEmpty) return null;

      final normalizedWord = (data['normalizedWord'] as String?)?.trim().toLowerCase() ??
          word.toLowerCase();
      final initialLetter = (data['initialLetter'] as String?)?.trim().toUpperCase() ??
          (word.isNotEmpty ? word[0].toUpperCase() : 'A');
      final letterAudioId = (data['letterAudioId'] as String?)?.trim().toUpperCase() ??
          initialLetter;
      final imagePath = (data['imagePath'] as String?)?.trim() ?? '';
      final wordAudioPath = (data['wordAudioPath'] as String?)?.trim() ?? '';
      final isActive = (data['isActive'] as bool?) ?? true;

      DateTime? createdAt;
      DateTime? updatedAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        createdAt = data['createdAt'] as DateTime;
      }

      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is DateTime) {
        updatedAt = data['updatedAt'] as DateTime;
      }

      return MaterialModel(
        id: id,
        word: word,
        normalizedWord: normalizedWord,
        initialLetter: initialLetter,
        letterAudioId: letterAudioId,
        imagePath: imagePath,
        wordAudioPath: wordAudioPath,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: data['createdBy'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Konversi ke format Map untuk Firestore atau testing.
  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'normalizedWord': normalizedWord,
      'initialLetter': initialLetter,
      'letterAudioId': letterAudioId,
      'imagePath': imagePath,
      'wordAudioPath': wordAudioPath,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  /// Mendapatkan key lowercase untuk audio huruf bawaan (misal: 'B' -> 'b').
  String get letterAudioKey => letterAudioId.toLowerCase();

  @override
  String toString() {
    return 'MaterialModel(id: $id, word: $word, initialLetter: $initialLetter, '
        'letterAudioId: $letterAudioId, isActive: $isActive)';
  }
}
