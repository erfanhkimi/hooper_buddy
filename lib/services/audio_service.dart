import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  static final AudioPlayer _player = AudioPlayer();

  /// Reactive notifier for global sound toggle state
  final ValueNotifier<bool> isSoundEnabled = ValueNotifier<bool>(true);

  /// Load persisted sound preferences on app start
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isSoundEnabled.value = prefs.getBool('is_sound_enabled') ?? true;
    } catch (_) {
      isSoundEnabled.value = true;
    }
  }

  /// Toggle sound on/off and save preference
  Future<void> toggleSound() async {
    isSoundEnabled.value = !isSoundEnabled.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_sound_enabled', isSoundEnabled.value);
    } catch (_) {}
  }

  /// High chime/swish for a MADE shot + medium haptic tap
  static Future<void> playMake() async {
    HapticFeedback.mediumImpact();

    if (!instance.isSoundEnabled.value) return;

    try {
      await _player.stop();
      await _player.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'),
      );
    } catch (_) {
      // Graceful fallback if offline/failed
    }
  }

  /// Low thump for a MISSED shot + heavy haptic vibration
  static Future<void> playMiss() async {
    HapticFeedback.heavyImpact();

    if (!instance.isSoundEnabled.value) return;

    try {
      await _player.stop();
      await _player.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2003/2003-preview.mp3'),
      );
    } catch (_) {
      // Graceful fallback if offline/failed
    }
  }
}