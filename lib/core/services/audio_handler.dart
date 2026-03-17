import 'dart:async';
import 'package:audio_service/audio_service.dart';

/// ReaderAudioHandler - 負責系統媒體控制通知 (鎖屏、耳機按鍵等)
/// 實際 TTS 語音由 TTSService._flutterTts 統一管理，避免雙引擎衝突
class ReaderAudioHandler extends BaseAudioHandler {
  static final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  /// 供 TTSService 訂閱的媒體控制事件流
  static Stream<String> get eventStream => _eventController.stream;

  /// TTSService 用此方法發送事件 (onComplete, onPlay, onPause…)
  static void emitEvent(String event) {
    if (!_eventController.isClosed) _eventController.add(event);
  }

  ReaderAudioHandler() {
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

  /// 同步播放狀態到系統通知欄
  void setPlaying(bool playing) {
    playbackState.add(playbackState.value.copyWith(
      playing: playing,
      processingState:
          playing ? AudioProcessingState.ready : AudioProcessingState.idle,
    ));
  }

  /// 更新通知欄書名/作者/封面
  void updateMetadata({required String title, required String author, String? artUri}) {
    mediaItem.add(MediaItem(
      id: 'legado_tts',
      album: title,
      title: author,
      artist: title,
      artUri: artUri != null && artUri.startsWith('http')
          ? Uri.parse(artUri)
          : null,
    ));
  }

  // ---- 媒體按鍵回調：全部轉為事件，由 ReaderProvider 處理 ----

  @override
  Future<void> skipToNext() async => emitEvent('onSkipToNext');

  @override
  Future<void> skipToPrevious() async => emitEvent('onSkipToPrevious');

  @override
  Future<void> play() async => emitEvent('onPlay');

  @override
  Future<void> pause() async => emitEvent('onPause');

  @override
  Future<void> stop() async => emitEvent('onStop');
}
