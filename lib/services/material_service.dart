import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/models/material_model.dart';

/// Service untuk memuat dan mengelola katalog materi dinamis dari Firestore & Storage.
///
/// Menyediakan mekanisme caching in-memory, resolusi download URL Firebase Storage,
/// serta fallback aman ke aset lokal bawaan ketika offline atau saat aset cloud belum siap.
class MaterialService {
  // ─── Singleton ──────────────────────────────────────────────────────────────
  static final MaterialService _instance = MaterialService._internal();
  factory MaterialService() => _instance;
  MaterialService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Cache materi berdasarkan kata ternormalisasi (`normalizedWord`).
  final Map<String, MaterialModel> _materialsByWord = {};

  /// Cache URL unduh dari Firebase Storage (`url_key` -> `downloadUrl`).
  final Map<String, String> _urlCache = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ─── Public API: Memuat Katalog ─────────────────────────────────────────────

  /// Memuat semua materi aktif (`isActive == true`) dari koleksi `material_catalog`.
  ///
  /// Aman dipanggil berulang kali; jika jaringan terputus (offline), fungsi
  /// mengembalikan data yang sudah ada di cache tanpa melempar eksepsi.
  Future<List<MaterialModel>> loadActiveMaterials({
    bool forceRefresh = false,
  }) async {
    if (_isLoaded && !forceRefresh && _materialsByWord.isNotEmpty) {
      return _materialsByWord.values.toList();
    }

    try {
      final snapshot = await _firestore
          .collection('material_catalog')
          .where('isActive', isEqualTo: true)
          .get();

      final List<MaterialModel> loaded = [];

      for (final doc in snapshot.docs) {
        final model = MaterialModel.fromFirestore(doc);
        if (model != null) {
          _materialsByWord[model.normalizedWord] = model;
          loaded.add(model);
        }
      }

      _isLoaded = true;
      debugPrint('[MaterialService] Berhasil memuat ${loaded.length} materi aktif dari Firestore');
      return loaded;
    } on FirebaseException catch (e) {
      debugPrint('[MaterialService] FirebaseException saat memuat katalog: ${e.code} – ${e.message}');
      return _materialsByWord.values.toList();
    } catch (e) {
      debugPrint('[MaterialService] Error tidak terduga saat memuat katalog: $e');
      return _materialsByWord.values.toList();
    }
  }

  // ─── Query Helper Cepat (Synchronous) ───────────────────────────────────────

  /// Memeriksa apakah suatu kata terdaftar dalam materi aktif (lokal atau cloud).
  bool hasMaterial(String word) {
    final clean = word.trim().toLowerCase();
    if (_materialsByWord.containsKey(clean)) return true;

    // Periksa apakah ada di pemetaan lokal bawaan
    for (final entry in AppImages.hurufKeKata.entries) {
      if (entry.value.toLowerCase() == clean) return true;
    }
    return false;
  }

  /// Mengambil data [MaterialModel] berdasarkan kata jika ada di cloud catalog.
  MaterialModel? getMaterial(String word) {
    final clean = word.trim().toLowerCase();
    return _materialsByWord[clean];
  }

  /// Mengambil URL gambar yang sudah tersimpan di cache (jika ada).
  String? getCachedImageUrl(String word) {
    return _urlCache['img_${word.trim().toLowerCase()}'];
  }

  /// Mengambil URL audio kata yang sudah tersimpan di cache (jika ada).
  String? getCachedWordAudioUrl(String word) {
    return _urlCache['aud_${word.trim().toLowerCase()}'];
  }

  // ─── Resolusi Media ────────────────────────────────────────────────────────

  /// Meresolusi URL gambar untuk suatu kata.
  ///
  /// Alur resolusi:
  /// 1. Cek cache in-memory URL.
  /// 2. Jika ada di katalog cloud (`material_catalog`): minta download URL dari Firebase Storage.
  /// 3. Jika gagal atau tidak terdaftar di cloud, periksa fallback lokal di `AppImages.hurufKeGambar`.
  /// 4. Mengembalikan null jika gambar sama sekali tidak tersedia.
  Future<String?> resolveImageUrl(String word, {String? hurufFallback}) async {
    final cleanWord = word.trim().toLowerCase();
    final cacheKey = 'img_$cleanWord';

    if (_urlCache.containsKey(cacheKey)) {
      return _urlCache[cacheKey];
    }

    // 1. Cek dari katalog dinamis
    final material = _materialsByWord[cleanWord];
    if (material != null && material.imagePath.isNotEmpty) {
      if (material.imagePath.startsWith('http://') ||
          material.imagePath.startsWith('https://') ||
          material.imagePath.startsWith('data:image/')) {
        _urlCache[cacheKey] = material.imagePath;
        return material.imagePath;
      }

      try {
        final downloadUrl = await _storage.ref(material.imagePath).getDownloadURL();
        _urlCache[cacheKey] = downloadUrl;
        return downloadUrl;
      } catch (e) {
        debugPrint('[MaterialService] Gagal resolusi Storage URL gambar untuk "$word": $e');
        // Lanjutkan ke fallback lokal jika ada
      }
    }

    // 2. Cek fallback lokal bawaan
    // Jika kata cocok dengan kata lokal bawaan (misal: 'ayam' -> 'assets/images/kata/a_ayam.png')
    for (final entry in AppImages.hurufKeKata.entries) {
      if (entry.value.toLowerCase() == cleanWord) {
        final localAsset = AppImages.hurufKeGambar[entry.key];
        if (localAsset != null && localAsset.isNotEmpty) {
          return localAsset;
        }
      }
    }

    // Jika diberikan hurufFallback eksplisit (misal pada mini-game tebak gambar per opsi huruf)
    if (hurufFallback != null && hurufFallback.isNotEmpty) {
      final cleanHuruf = hurufFallback.toLowerCase().trim();
      if (AppImages.hurufKeGambar.containsKey(cleanHuruf)) {
        return AppImages.hurufKeGambar[cleanHuruf];
      }
    }

    return null;
  }

  /// Meresolusi URL audio pengucapan kata utuh.
  ///
  /// Alur resolusi:
  /// 1. Cek cache in-memory URL.
  /// 2. Jika ada di katalog cloud: minta download URL dari Firebase Storage.
  /// 3. Jika gagal atau tidak terdaftar di cloud, gunakan audio lokal `AppAudio.kata(word)`.
  Future<String> resolveWordAudioUrl(String word) async {
    final cleanWord = word.trim().toLowerCase();
    final cacheKey = 'aud_$cleanWord';

    if (_urlCache.containsKey(cacheKey)) {
      return _urlCache[cacheKey]!;
    }

    final material = _materialsByWord[cleanWord];
    if (material != null && material.wordAudioPath.isNotEmpty) {
      if (material.wordAudioPath.startsWith('http://') ||
          material.wordAudioPath.startsWith('https://') ||
          material.wordAudioPath.startsWith('data:audio/')) {
        _urlCache[cacheKey] = material.wordAudioPath;
        return material.wordAudioPath;
      }

      try {
        final downloadUrl = await _storage.ref(material.wordAudioPath).getDownloadURL();
        _urlCache[cacheKey] = downloadUrl;
        return downloadUrl;
      } catch (e) {
        debugPrint('[MaterialService] Gagal resolusi Storage URL audio kata "$word": $e');
      }
    }

    // Fallback ke audio kata lokal
    return AppAudio.kata(cleanWord);
  }

  /// Meresolusi path audio huruf bawaan A–Z.
  ///
  /// Selalu memetakan ke audio lokal bawaan `AppAudio.huruf(...)` menggunakan `letterAudioId`
  /// yang dipilih oleh guru pada website.
  String resolveLetterAudioPath(String word, {String? hurufFallback}) {
    final cleanWord = word.trim().toLowerCase();
    final material = _materialsByWord[cleanWord];

    if (material != null) {
      return AppAudio.huruf(material.letterAudioKey);
    }

    final letter = hurufFallback?.toLowerCase().trim() ??
        (cleanWord.isNotEmpty ? cleanWord[0] : 'a');
    return AppAudio.huruf(letter);
  }

  // ─── Testing / Mock Helpers ─────────────────────────────────────────────────

  @visibleForTesting
  void setMockMaterials(List<MaterialModel> materials) {
    _materialsByWord.clear();
    for (final m in materials) {
      _materialsByWord[m.normalizedWord] = m;
    }
    _isLoaded = true;
  }

  @visibleForTesting
  void setMockUrl(String key, String url) {
    _urlCache[key] = url;
  }

  @visibleForTesting
  void clearCache() {
    _materialsByWord.clear();
    _urlCache.clear();
    _isLoaded = false;
  }
}
