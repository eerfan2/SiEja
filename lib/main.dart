import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:si_eja/firebase_options.dart';
import 'package:si_eja/app/router.dart';
import 'package:si_eja/services/audio_service.dart';
import 'package:si_eja/services/connectivity_service.dart';
import 'package:si_eja/services/progress_service.dart';
import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/widgets/asset_button.dart';

void main() async {
  // Wajib dipanggil sebelum inisialisasi async di main
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi ConnectivityService untuk deteksi koneksi internet
  await ConnectivityService().init();

  // Kunci orientasi aplikasi agar portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inisialisasi Service SharedPreferences
  await ProgressService().init();
  
  // Inisialisasi AudioService & hentikan audio sisa dari Hot Restart sebelumnya
  await AudioService().resetAllAudio();

  runApp(
    MultiProvider(
      providers: [
        Provider<ProgressService>.value(
          value: ProgressService(),
        ),
      ],
      child: const SiEjaApp(),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SiEjaApp extends StatefulWidget {
  const SiEjaApp({super.key});

  @override
  State<SiEjaApp> createState() => _SiEjaAppState();
}

class _SiEjaAppState extends State<SiEjaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AudioService().pauseBGM();
    } else if (state == AppLifecycleState.resumed) {
      AudioService().resumeBGM();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'SiEja',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: ConnectivityWrapper(child: child!),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          // Tema warna pastel
          seedColor: const Color(0xFF81D4FA), // Pastel Biru
          primary: const Color(0xFF4FC3F7),
          secondary: const Color(0xFFF48FB1), // Pastel Pink
          surface: const Color(0xFFF9FBE7), // Light background
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FBE7),
        useMaterial3: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ConnectivityWrapper: listener koneksi global
// ---------------------------------------------------------------------------
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  StreamSubscription<bool>? _subscription;
  bool _wasConnected = true;

  @override
  void initState() {
    super.initState();
    _wasConnected = ConnectivityService().isConnected;

    // Listen ke perubahan rute navigasi untuk menangani saat keluar dari /stage dalam keadaan offline
    appRouter.routerDelegate.addListener(_onRouteChanged);

    _subscription = ConnectivityService().onConnectivityChanged.listen(
      (isConnected) {
        if (!isConnected && _wasConnected) {
          _wasConnected = false;
          _handleDisconnection();
        } else if (isConnected && !_wasConnected) {
          _wasConnected = true;
          _hideNoConnectionBanner();
        }
      },
    );
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    _subscription?.cancel();
    super.dispose();
  }

  String _getCurrentPath() {
    try {
      return appRouter.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '';
    }
  }

  void _onRouteChanged() {
    if (!ConnectivityService().isConnected && !_wasConnected) {
      final currentPath = _getCurrentPath();
      // Jika pengguna keluar dari /stage dan tidak sedang di halaman offline, tampilkan pop up template offline
      if (currentPath != '/stage' && !currentPath.startsWith('/offline')) {
        _showNoConnectionDialog();
      }
    }
  }

  void _handleDisconnection() {
    final currentPath = _getCurrentPath();

    // Jika bukan di /stage dan bukan di halaman offline, tampilkan pop up template offline
    if (currentPath != '/stage' && !currentPath.startsWith('/offline')) {
      _showNoConnectionDialog();
    }
    // Catatan: Jika saat ini di /stage, dibiarkan menyelesaikan stage terlebih dahulu untuk menyimpan poin.
    // Setelah selesai/keluar dari /stage, _onRouteChanged akan menampilkan pop up template offline.
  }

  void _showNoConnectionDialog() {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) {
      appRouter.go('/offline-dashboard');
      return;
    }

    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: SizedBox(
            width: 290,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/template/frame_login.png',
                  width: 290,
                  fit: BoxFit.fitWidth,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 75, 32, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 35,
                        color: Color(0xFF5A4FCF),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Koneksi Terputus! ⚠️',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Fredoka',
                          color: Color(0xFF5A4FCF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Jaringan internet terputus.\nSilakan beralih ke mode offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Fredoka',
                          color: Color(0xFF7B6FD4),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AssetButton(
                        normalAsset: AppImages.btnOfflineNormal,
                        pressedAsset: AppImages.btnOfflinePressed,
                        onTap: () {
                          Navigator.pop(dialogContext);
                          appRouter.go('/offline-dashboard');
                        },
                        height: 42,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideNoConnectionBanner() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Koneksi tersambung kembali! 🎉',
              style: TextStyle(fontFamily: 'Fredoka'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
