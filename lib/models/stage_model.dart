class StageModel {
  final String id;
  final int number;
  final String nama;
  final String huruf;
  final String lokasi;
  final bool isOpenByTeacher;
  final DateTime? createdAt;
  final String createdBy;

  const StageModel({
    required this.id,
    required this.number,
    required this.nama,
    required this.huruf,
    required this.lokasi,
    this.isOpenByTeacher = false,
    this.createdAt,
    this.createdBy = '',
  });

  factory StageModel.fromMap(String id, Map<String, dynamic> data) {
    final stageNum = (data['number'] as num?)?.toInt() ??
        int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;
    final range = (data['range'] ?? data['huruf'] ?? 'A - Z').toString();
    final name = (data['nama'] ?? data['title'] ?? 'Stage $stageNum').toString();
    final location = (data['lokasi'] ?? 'Petualangan Literasi').toString();
    final isOpen = data['isOpenByTeacher'] == true;

    return StageModel(
      id: id,
      number: stageNum,
      nama: name,
      huruf: range,
      lokasi: location,
      isOpenByTeacher: isOpen,
      createdBy: (data['createdBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'nama': nama,
      'huruf': huruf,
      'lokasi': lokasi,
      'isOpenByTeacher': isOpenByTeacher,
      'createdBy': createdBy,
    };
  }
}
