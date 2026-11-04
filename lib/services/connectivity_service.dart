import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance =
      ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream untuk broadcast status koneksi
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  // Inisialisasi service
  Future<void> init() async {
    // Cek status awal
    final result = await _connectivity.checkConnectivity();
    _isConnected = _checkResult(result);

    // Listen perubahan koneksi
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = _checkResult(results);
      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(_isConnected);
      }
    });
  }

  bool _checkResult(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  // Cek koneksi manual (saat klik ikon)
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = _checkResult(result);
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
