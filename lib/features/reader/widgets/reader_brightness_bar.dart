import 'package:flutter/material.dart';
import '../reader_provider.dart';

class ReaderBrightnessBar extends StatelessWidget {
  final ReaderProvider provider;

  const ReaderBrightnessBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: provider.showControls ? 16 : -80,
      top: 120, bottom: 250, // 避開頂部與底部選單
      child: Container(
        width: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.brightness_auto, color: Colors.white, size: 20),
              onPressed: () {}, // 暫未實作自動亮度邏輯
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: provider.brightness,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => provider.setBrightness(v),
                    activeColor: Colors.blue,
                    inactiveColor: Colors.white24,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
              onPressed: () {}, // 對位 Android 位置調整
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
