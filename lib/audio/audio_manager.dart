import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  static const String _hubTrack = 'music/Town Center Echoes.mp3';
  static const String _dungeonTrack = 'music/Chromatic Skyline.mp3';

  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isMuted = false;
  double _savedVolume = 0.5;
  String? _currentTrack;

  bool get isMuted => _isMuted;

  Future<void> init() async {
    if (_isInitialized) return;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.5);
    _isInitialized = true;
  }

  Future<void> playMusic() async {
    await playHubMusic();
  }

  Future<void> playHubMusic() async {
    await _playTrack(_hubTrack);
  }

  Future<void> playDungeonMusic() async {
    await _playTrack(_dungeonTrack);
  }

  Future<void> _playTrack(String track) async {
    if (_currentTrack == track) return;
    if (!_isInitialized) await init();

    _currentTrack = track;
    await _musicPlayer.stop();
    await _musicPlayer.play(AssetSource(track));
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeMusic() async {
    await _musicPlayer.resume();
  }

  Future<void> setMusicVolume(double volume) async {
    _savedVolume = volume.clamp(0.0, 1.0);
    if (!_isMuted) {
      await _musicPlayer.setVolume(_savedVolume);
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _musicPlayer.setVolume(0.0);
    } else {
      await _musicPlayer.setVolume(_savedVolume);
    }
  }

  void dispose() {
    _musicPlayer.dispose();
  }
}
