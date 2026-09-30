import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/core/app_constants.dart';
import 'package:si_eja/services/connectivity_service.dart';
import 'package:si_eja/widgets/bg_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _player = AudioPlayer();

  Future<void> _navigateAfterSplash() async {
    final isConnected = await ConnectivityService().checkConnection();

    if (!mounted) return;

    if (isConnected) {
      // Online → ke halaman pilih role
      context.go('/select-role');
    } else {
      // Offline → langsung ke dashboard offline
      context.go('/offline-dashboard');
    }
  }

  Future<void> _playWelcome() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
    await _player.play(
      AssetSource('audio/instruksi/selamat_datang.mp3'),
    );
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        Future.delayed(
          const Duration(milliseconds: 500), () {
            if (mounted) _navigateAfterSplash();
          },
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _playWelcome();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      backgroundAsset: AppImages.bgSplash,
      child: const SizedBox.expand(),
    );
  }
}
