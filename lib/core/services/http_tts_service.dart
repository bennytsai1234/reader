import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:legado_reader/core/models/http_tts.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';

/// HttpTtsService - 在線 HTTP TTS 朗讀服務
/// 仿照 Android: service/HttpReadAloudService.kt 實作段落緩存與連續播放
class HttpTtsService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  
  bool get isPlaying => _isPlaying;

  HttpTtsService() {
    _initSession();
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  /// 獲取緩存目錄
  Future<Directory> _getCacheDir() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory(p.join(temp.path, 'httpTTS_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 根據文本與配置生成 MD5 文件名
  String _getFileName(HttpTTS config, String text, int speed) {
    final raw = '${config.url}-|-$speed-|-$text';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// 朗讀文本清單 (段落列表)
  Future<void> speakList(HttpTTS config, List<String> paragraphs, {int speed = 5, int startIndex = 0}) async {
    try {
      final cacheDir = await _getCacheDir();
      final sources = <AudioSource>[];

      for (var i = startIndex; i < paragraphs.length; i++) {
        final text = paragraphs[i].trim();
        if (text.isEmpty) continue;

        final fileName = _getFileName(config, text, speed);
        final file = File(p.join(cacheDir.path, '$fileName.mp3'));

        if (!await file.exists()) {
          // 下載音頻
          final analyzeUrl = AnalyzeUrl(
            config.url,
            speakText: text,
            speakSpeed: speed,
            source: config,
          );

          final bytes = await analyzeUrl.getByteArray();
          if (bytes.isNotEmpty) {
            // 檢查是否為錯誤訊息 (如 JSON 或 HTML) 而非音檔
            var isErrorText = false;
            if (bytes.length < 1000) {
              try {
                final str = utf8.decode(bytes);
                if (str.contains('{') || str.contains('<html') || str.contains('error')) {
                  isErrorText = true;
                }
              } catch (_) {
                // Not valid UTF-8, likely binary audio data
              }
            }

            if (isErrorText) {
              debugPrint('HttpTtsService: Received error instead of audio: ${utf8.decode(bytes)}');
              continue;
            }

            await file.writeAsBytes(bytes);
          } else {
            continue; // 下載失敗則跳過此段
          }
        }

        sources.add(AudioSource.uri(Uri.file(file.path)));
      }

      if (sources.isNotEmpty) {
        await _player.setAudioSources(sources);
        _player.play();
      }
    } catch (e) {
      debugPrint('HttpTtsService Error: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

