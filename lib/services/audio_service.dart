import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    _init();
  }

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isBgmEnabled = true;
  bool get isBgmEnabled => _isBgmEnabled;
  bool get isMuted => !_isBgmEnabled;

  final double _bgmVolume = 0.5;
  String? _currentBGMPath;
  StreamSubscription? _bgmSubscription;
  StreamSubscription? _sfxSubscription;

  void _init() {
    // BGM loop dengan jeda 2 detik tiap pengulangan
    _bgmPlayer.setReleaseMode(ReleaseMode.stop);
    _bgmPlayer.setVolume(_bgmVolume);

    _bgmSubscription?.cancel();
    _bgmSubscription = _bgmPlayer.onPlayerComplete.listen((_) async {
      if (_currentBGMPath != null) {
        await Future.delayed(const Duration(seconds: 2));
        if (_currentBGMPath != null) {
          try {
            await _bgmPlayer.play(AssetSource(_currentBGMPath!));
            if (!_isBgmEnabled) {
              await _bgmPlayer.setVolume(0.0);
            } else {
              await _bgmPlayer.setVolume(_bgmVolume);
            }
          } catch (e) {
            debugPrint("AudioService BGM loop error: $e");
          }
        }
      }
    });
  }

  // Dipanggil saat main() untuk mematikan sisa audio yang masih jalan akibat Hot Restart
  Future<void> resetAllAudio() async {
    try {
      _currentBGMPath = null;
      await _bgmPlayer.stop();
      await _sfxPlayer.stop();
    } catch (e) {
      debugPrint("AudioService resetAllAudio error: $e");
    }
  }

  // Method helper untuk menghapus prefix 'assets/' jika ada
  String _formatPath(String path) {
    if (path.startsWith('assets/')) {
      return path.replaceFirst('assets/', '');
    }
    return path;
  }

  void setBgmEnabled(bool enabled) {
    _isBgmEnabled = enabled;
    if (_isBgmEnabled) {
      _bgmPlayer.setVolume(_bgmVolume);
    } else {
      _bgmPlayer.setVolume(0.0);
    }
  }

  void toggleBgm() {
    setBgmEnabled(!_isBgmEnabled);
  }

  // Backward compatibility alias
  void toggleMute() {
    toggleBgm();
  }

  Future<void> playBGM(String path) async {
    try {
      final formattedPath = _formatPath(path);

      // Jika lagu BGM sama dan sedang berputar, teruskan tanpa interupsi/diulang
      if (_currentBGMPath == formattedPath && _bgmPlayer.state == PlayerState.playing) {
        if (!_isBgmEnabled) {
          await _bgmPlayer.setVolume(0.0);
        } else {
          await _bgmPlayer.setVolume(_bgmVolume);
        }
        return;
      }

      // Jika lagu BGM sama dan sedang dipause, lanjutkan (resume)
      if (_currentBGMPath == formattedPath && _bgmPlayer.state == PlayerState.paused) {
        await _bgmPlayer.resume();
        if (!_isBgmEnabled) {
          await _bgmPlayer.setVolume(0.0);
        } else {
          await _bgmPlayer.setVolume(_bgmVolume);
        }
        return;
      }

      _currentBGMPath = formattedPath;
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource(formattedPath));
      
      if (!_isBgmEnabled) {
        await _bgmPlayer.setVolume(0.0);
      } else {
        await _bgmPlayer.setVolume(_bgmVolume);
      }
    } catch (e) {
      debugPrint("AudioService playBGM error: $e");
    }
  }

  Future<void> stopBGM() async {
    try {
      _currentBGMPath = null;
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint("AudioService stopBGM error: $e");
    }
  }

  Future<void> stopSFX() async {
    try {
      await _sfxPlayer.stop();
      _sfxSubscription?.cancel();
      if (_isBgmEnabled) {
        await _bgmPlayer.setVolume(_bgmVolume);
      }
    } catch (e) {
      debugPrint("AudioService stopSFX error: $e");
    }
  }

  Future<void> pauseBGM() async {
    try {
      if (_bgmPlayer.state == PlayerState.playing) {
        await _bgmPlayer.pause();
      }
    } catch (e) {
      debugPrint("AudioService pauseBGM error: $e");
    }
  }

  Future<void> resumeBGM() async {
    try {
      if (_bgmPlayer.state == PlayerState.paused) {
        await _bgmPlayer.resume();
      }
    } catch (e) {
      debugPrint("AudioService resumeBGM error: $e");
    }
  }

  // SFX (pelafalan huruf, kata, instruksi suara) SELALU diputar dengan volume full 1.0!
  Future<void> playSFX(String path) async {
    try {
      if (_isBgmEnabled) {
        await _bgmPlayer.setVolume(0.2);
      }
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(
        AssetSource(path.replaceFirst('assets/', '')),
      );
      _sfxSubscription?.cancel();
      _sfxSubscription = _sfxPlayer.onPlayerComplete.listen((_) {
        if (_isBgmEnabled) {
          _bgmPlayer.setVolume(_bgmVolume);
        } else {
          _bgmPlayer.setVolume(0.0);
        }
      });
    } catch (e) {
      debugPrint('Audio error: $e');
      if (_isBgmEnabled) {
        await _bgmPlayer.setVolume(_bgmVolume);
      } else {
        await _bgmPlayer.setVolume(0.0);
      }
    }
  }

  Future<void> dispose() async {
    _bgmSubscription?.cancel();
    _sfxSubscription?.cancel();
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
