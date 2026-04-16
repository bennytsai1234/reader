import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/audio_play_service.dart';
import 'change_chapter_source_sheet.dart';
import 'widgets/audio/audio_player_main.dart';
import 'widgets/audio/audio_player_slider.dart';
import 'widgets/audio/audio_player_utils.dart';

class AudioPlayerPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  const AudioPlayerPage({super.key, required this.book, this.chapterIndex = 0});
  @override State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late int _currentIndex;
  List<BookChapter> _chapters = [];
  BookSource? _source;
  final AudioPlayService _audio = AudioPlayService();
  final BookSourceService _service = BookSourceService();

  @override
  void initState() { super.initState(); _currentIndex = widget.chapterIndex; _init(); }

  Future<void> _init() async {
    _chapters = await BookSourceService().getBookChapters(widget.book.bookUrl);
    _source = await BookSourceService().getSourceByUrl(widget.book.origin);
    _loadChapter(_currentIndex);
  }

  Future<void> _loadChapter(int index) async {
    if (_source == null) return;
    setState(() => _currentIndex = index);
    try {
      final url = await _service.getContent(_source!, widget.book, _chapters[index]);
      await _audio.playUrl(url, title: _chapters[index].title, artist: widget.book.author, album: widget.book.name, artUri: widget.book.coverUrl);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _audio, builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('有聲播放'), actions: [
        IconButton(icon: const Icon(Icons.swap_horiz), onPressed: _showChangeSource),
        IconButton(icon: const Icon(Icons.timer_outlined), onPressed: _showTimer),
        IconButton(icon: const Icon(Icons.list), onPressed: _showToc),
      ]),
      body: Column(children: [
        Expanded(child: ListView(children: [
          const SizedBox(height: 40),
          AudioPlayerMain(book: widget.book, chapters: _chapters, currentIndex: _currentIndex, audioService: _audio, onLoadChapter: _loadChapter, onShowSpeed: _showSpeed),
          AudioPlayerSlider(audioService: _audio),
        ])),
        _buildBottomInfo(),
      ]),
    ));
  }

  Widget _buildBottomInfo() => Container(padding: const EdgeInsets.symmetric(vertical: 20), color: Colors.grey[100], child: Center(child: _audio.remainingSleepTime != null 
    ? Text('定時關閉：${AudioPlayerUtils.formatDuration(_audio.remainingSleepTime!)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
    : const Text('定時關閉已禁用', style: TextStyle(color: Colors.grey, fontSize: 12))));

  void _showToc() => showModalBottomSheet(context: context, builder: (ctx) => ListView.builder(itemCount: _chapters.length, itemBuilder: (c, i) => ListTile(title: Text(_chapters[i].title, style: TextStyle(color: i == _currentIndex ? Colors.blue : null)), onTap: () { Navigator.pop(ctx); _loadChapter(i); })));

  void _showChangeSource() => showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => ChangeChapterSourceSheet(book: widget.book, chapterIndex: _currentIndex, chapterTitle: _chapters.isNotEmpty ? _chapters[_currentIndex].title : ''));

  void _showTimer() => showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [const ListTile(title: Text('定時睡眠')), ...[0, 15, 30, 60].map((m) => ListTile(title: Text(m == 0 ? '關閉' : '$m 分鐘'), onTap: () { _audio.setSleepTimer(m); Navigator.pop(ctx); })), const SizedBox(height: 20)]));

  void _showSpeed() => showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [const ListTile(title: Text('播放速度')), ...[0.8, 1.0, 1.2, 1.5, 2.0].map((s) => ListTile(title: Text('${s}x'), onTap: () { _audio.player.setSpeed(s); Navigator.pop(ctx); })), const SizedBox(height: 20)]));
}


