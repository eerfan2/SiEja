import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:si_eja/models/stage_model.dart';

class StageService {
  static final StageService _instance = StageService._internal();
  factory StageService() => _instance;
  StageService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const List<StageModel> defaultStages = [
    StageModel(
      id: 'stage1',
      number: 1,
      nama: 'Stage 1',
      huruf: 'A - E',
      lokasi: 'Awal Petualangan',
      isOpenByTeacher: true,
    ),
    StageModel(
      id: 'stage2',
      number: 2,
      nama: 'Stage 2',
      huruf: 'F - J',
      lokasi: 'Taman Bintang',
      isOpenByTeacher: false,
    ),
    StageModel(
      id: 'stage3',
      number: 3,
      nama: 'Stage 3',
      huruf: 'K - O',
      lokasi: 'Desa Alfabet',
      isOpenByTeacher: false,
    ),
    StageModel(
      id: 'stage4',
      number: 4,
      nama: 'Stage 4',
      huruf: 'P - T',
      lokasi: 'Pelangi Mengeja',
      isOpenByTeacher: false,
    ),
    StageModel(
      id: 'stage5',
      number: 5,
      nama: 'Stage 5',
      huruf: 'U - Z',
      lokasi: 'Taman Huruf',
      isOpenByTeacher: false,
    ),
    StageModel(
      id: 'stage6',
      number: 6,
      nama: 'Stage 6',
      huruf: 'A - Z',
      lokasi: 'Istana Literasi',
      isOpenByTeacher: false,
    ),
  ];

  /// Mengambil seluruh stage (default + dokumen dari Firestore koleksi `stages`).
  /// Diurutkan strictly berdasarkan nomor urut (number) secara menaik.
  Future<List<StageModel>> getStages() async {
    final Map<int, StageModel> stageMap = {};
    for (final def in defaultStages) {
      stageMap[def.number] = def;
    }

    try {
      final snapshot = await _firestore.collection('stages').get();
      for (final doc in snapshot.docs) {
        final model = StageModel.fromMap(doc.id, doc.data());
        stageMap[model.number] = model;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StageService] getStages offline/error: $e — fallback default');
      }
    }

    final result = stageMap.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return result;
  }
}
