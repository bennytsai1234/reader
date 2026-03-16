import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

class ReaderMenuBottom extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onOpenDrawer;
  final VoidCallback onTts;
  final VoidCallback onInterface;
  final VoidCallback onSettings;
  
  // 新功能回調
  final VoidCallback onSearch;
  final VoidCallback onAutoPage;
  final VoidCallback onCache; // 新增：離線緩存
  final VoidCallback onReplace;
  final VoidCallback onToggleDayNight;

  const ReaderMenuBottom({
    super.key,
    required this.provider,
    required this.onOpenDrawer,
    required this.onTts,
    required this.onInterface,
    required this.onSettings,
    required this.onSearch,
    required this.onAutoPage,
    required this.onCache,
    required this.onReplace,
    required this.onToggleDayNight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 0 : -220, // 稍微增加高度以容納新功能列
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Column(
          children: [
            // 1. 章節進度條
            _buildChapterSlider(),
            
            // 2. 新增的快捷功能列 (搜尋、自動翻頁、替換、日夜)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(Icons.search, '搜尋', onSearch),
                  _buildQuickAction(Icons.download_for_offline, '緩存', onCache),
                  _buildQuickAction(Icons.cleaning_services, '替換', onReplace),
                  _buildQuickAction(
                    provider.themeIndex == 1 ? Icons.wb_sunny : Icons.nightlight_round, 
                    provider.themeIndex == 1 ? '白天' : '夜晚', 
                    onToggleDayNight
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white10, height: 1),

            // 3. 核心功能按鈕 (目錄、朗讀、界面、設定)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMainAction(Icons.list, '目錄', onOpenDrawer),
                  _buildMainAction(
                    provider.tts.isPlaying ? Icons.stop_circle : Icons.record_voice_over, 
                    '朗讀', 
                    onTts, 
                    active: provider.tts.isPlaying
                  ),
                  _buildMainAction(Icons.auto_awesome_mosaic, '界面', onInterface),
                  _buildMainAction(Icons.settings, '設定', onSettings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterSlider() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20), onPressed: provider.prevChapter),
        Expanded(
          child: Slider(
            value: provider.currentChapterIndex.toDouble().clamp(0, (provider.chapters.isEmpty ? 0 : provider.chapters.length - 1).toDouble()),
            min: 0,
            max: (provider.chapters.isEmpty ? 0 : provider.chapters.length - 1).toDouble(),
            divisions: provider.chapters.length > 1 ? provider.chapters.length - 1 : 1,
            onChanged: (v) => provider.onScrubbing(v.toInt()),
            onChangeEnd: (v) => provider.onScrubEnd(v.toInt()),
          ),
        ),
        IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 20), onPressed: provider.nextChapter),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap, {bool active = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: active ? Colors.blue : Colors.white70, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? Colors.blue : Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMainAction(IconData icon, String label, VoidCallback onTap, {bool active = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.blue : Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? Colors.blue : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

