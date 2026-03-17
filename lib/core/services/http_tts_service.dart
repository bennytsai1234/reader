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
/// 優化：流水線下載播放，第一段下載完即開始播放，後續段落背景追加
class HttpTtsService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;
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

  /// 檢查回應位元組是否為錯誤訊息（JSON/HTML）而非音檔
  bool _isErrorContent(List<int> bytes) {
    if (bytes.length >= 1000) return false;
    try {
      final str = utf8.decode(bytes);
      return str.contains('{') || str.contains('<html') || str.contains('error');
    } catch (_) {
      return false; // 非有效 UTF-8 → 視為二進位音檔
    }
  }

  /// 下載單一段落音檔，命中磁碟快取則直接回傳
  Future<File?> _getOrDownloadAudioFile(HttpTTS config, String text, int speed, Directory cacheDir) async {
    final fileName = _getFileName(config, text, speed);
    final file = File(p.join(cacheDir.path, '$fileName.mp3'));
    if (await file.exists()) return file;

    final analyzeUrl = AnalyzeUrl(config.url, speakText: text, speakSpeed: speed, source: config);
    final bytes = await analyzeUrl.getByteArray();
    if (bytes.isEmpty) return null;
    if (_isErrorContent(bytes)) {
      debugPrint('HttpTtsService: Received error instead of audio');
      return null;
    }
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 朗讀文本清單 (段落列表) — 流水線模式：第一段就緒即播放，後續段落持續追加
  Future<void> speakList(HttpTTS config, List<String> paragraphs, {int speed = 5, int startIndex = 0}) async {
    try {
      await _player.stop();
      _playlist = ConcatenatingAudioSource(children: []);
      final cacheDir = await _getCacheDir();
      bool started = false;

      for (var i = startIndex; i < paragraphs.length; i++) {
        final text = paragraphs[i].trim();
        if (text.isEmpty) continue;

        final file = await _getOrDownloadAudioFile(config, text, speed, cacheDir);
        if (file == null) continue;

        final source = AudioSource.uri(Uri.file(file.path));

        if (!started) {
          // 第一段就緒：建立 playlist 並立即開始播放
          await _playlist!.add(source);
          await _player.setAudioSource(_playlist!);
          _player.play();
          started = true;
        } else {
          // 後續段落動態追加，播放不中斷
          await _playlist!.add(source);
        }
      }
    } catch (e) {
      debugPrint('HttpTtsService Error: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playlist = null;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

