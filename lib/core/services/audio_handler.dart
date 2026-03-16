import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ReaderAudioHandler - 處理系統媒體控制與 TTS 狀態
/// 深度還原 Android 版的背景播放與媒體通知中心功能
class ReaderAudioHandler extends BaseAudioHandler {
  final FlutterTts _tts = FlutterTts();
  
  // 用於通知 ReaderProvider 跳轉章節
  static final StreamController<String> _eventController = StreamController<String>.broadcast();
  static Stream<String> get eventStream => _eventController.stream;

  ReaderAudioHandler() {
    _initTts();
    
    // 初始化播放狀態
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
    ));
  }

  void _initTts() {
    _tts.setCompletionHandler(() {
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.completed,
      ));
      // 廣播「播放完成」，讓 Provider 自動下一頁
      _eventController.add('onComplete');
    });

    _tts.setStartHandler(() {
      playbackState.add(playbackState.value.copyWith(
        playing: true,
        processingState: AudioProcessingState.ready,
      ));
    });
  }

  @override
  Future<void> skipToNext() async {
    _eventController.add('onSkipToNext');
  }

  @override
  Future<void> skipToPrevious() async {
    _eventController.add('onSkipToPrevious');
  }

  void updateMetadata({required String title, required String author, String? artUri}) {
    mediaItem.add(MediaItem(
      id: 'legado_tts',
      album: title,
      title: author,
      artist: title,
      // 如果有封面圖 URL 則顯示，否則可以使用佔位圖
      artUri: artUri != null && artUri.startsWith('http') ? Uri.parse(artUri) : null,
    ));
  }

  @override
  Future<void> play() async {
    _eventController.add('onPlay');
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
    playbackState.add(playbackState.value.copyWith(playing: false));
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }
}

