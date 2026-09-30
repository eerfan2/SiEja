/// Enum GameType — mendefinisikan 7 jenis mini-game yang digunakan di SiEja.
///
/// Nilai string masing-masing tipe harus cocok persis dengan nilai [gameType]
/// yang disimpan di Cloud Firestore collection `soal`.
enum GameType {
  dengarSuaraHuruf,
  tebakGambarObjek,
  susunKata,
  hurufYangHilang,
  hurufAwalApa,
  cocokkanHuruf,
  urutkanHuruf,
}

/// Konversi string dari Firestore ke [GameType].
///
/// Mengembalikan [null] jika string tidak dikenal, sehingga dokumen tidak valid
/// dapat di-skip oleh caller tanpa menyebabkan exception.
GameType? gameTypeFromString(String value) {
  switch (value.trim()) {
    case 'dengarSuaraHuruf':
      return GameType.dengarSuaraHuruf;
    case 'tebakGambarObjek':
      return GameType.tebakGambarObjek;
    case 'susunKata':
      return GameType.susunKata;
    case 'hurufYangHilang':
      return GameType.hurufYangHilang;
    case 'hurufAwalApa':
      return GameType.hurufAwalApa;
    case 'cocokkanHuruf':
      return GameType.cocokkanHuruf;
    case 'urutkanHuruf':
      return GameType.urutkanHuruf;
    default:
      return null;
  }
}

/// Konversi [GameType] ke string yang disimpan di Firestore.
String gameTypeToString(GameType type) {
  return type.name; // enum.name mengembalikan nama field sebagai string
}
