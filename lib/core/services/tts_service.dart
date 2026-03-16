import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';

/// TTSService - TTS 朗讀服務 (專業升級版：整合 AudioService)
/// (原 Android service/TTSReadAloudService.kt)
class TTSService extends ChangeNotifier {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;

  late ReaderAudioHandler _audioHandler;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  double _pitch = 1.0;
  double _volume = 1.0;
  double _rate = 0.5;
  String? _language;
  List<dynamic> _languages = [];
  
  VoidCallback? onComplete;
  Timer? _sleepTimer;
  int _remainingMinutes = 0;

  bool get isPlaying => _isPlaying;
  int get remainingMinutes => _remainingMinutes;
  double get pitch => _pitch;
  double get volume => _volume;
  double get rate => _rate;
  String? get language => _language;
  List<dynamic> get languages => _languages;

  String currentSpokenText = '';
  int currentWordStart = 0;
  int currentWordEnd = 0;

  TTSService._internal();

  /// 在 main.dart 中初始化
  Future<void> init() async {
    _audioHandler = await AudioService.init(
      builder: () => ReaderAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.your.app.tts',
        androidNotificationChannelName: 'Legado TTS',
        androidNotificationOngoing: true,
      ),
    );

    await _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
      if (onComplete != null) onComplete!();
    });

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      currentSpokenText = text;
      currentWordStart = start;
      currentWordEnd = end;
      notifyListeners();
    });

    _languages = await _flutterTts.getLanguages;
    _language = _languages.contains('zh-CN') ? 'zh-CN' : (_languages.contains('zh-TW') ? 'zh-TW' : _languages.first.toString());
    await _flutterTts.setLanguage(_language!);
  }

  /// 更新系統通知欄資訊
  void updateMediaInfo({required String title, required String author, String? coverUrl}) {
    _audioHandler.updateMetadata(title: title, author: author, artUri: coverUrl);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _remainingMinutes = minutes;
    _sleepTimer?.cancel();
    if (minutes > 0) {
      _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (_remainingMinutes > 0) {
          _remainingMinutes--;
          notifyListeners();
        } else {
          stop();
          timer.cancel();
        }
      });
    }
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async { _language = lang; await _flutterTts.setLanguage(lang); notifyListeners(); }
  Future<void> setPitch(double pitch) async { _pitch = pitch; await _flutterTts.setPitch(pitch); notifyListeners(); }
  Future<void> setRate(double rate) async { _rate = rate; await _flutterTts.setSpeechRate(rate); notifyListeners(); }
  Future<void> setVolume(double volume) async { _volume = volume; await _flutterTts.setVolume(volume); notifyListeners(); }

  // 對外暴露音訊事件流
  Stream<String> get audioEvents => ReaderAudioHandler.eventStream;
}

