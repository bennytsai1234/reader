import 'package:flutter/material.dart';

class MangaBottomControls extends StatelessWidget {
  final int readingMode;
  final bool isAutoScrolling;
  final bool isReverseDirection;
  final double brightness;
  final bool hasPrev;
  final bool hasNext;
  final Function(int) onModeChanged;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onToggleDirection;
  final Function(double) onBrightnessChanged;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;

  const MangaBottomControls({
    super.key, required this.readingMode, required this.isAutoScrolling,
    required this.isReverseDirection, required this.brightness,
    required this.hasPrev, required this.hasNext,
    required this.onModeChanged, required this.onToggleAutoScroll,
    required this.onToggleDirection, required this.onBrightnessChanged,
    required this.onPrevChapter, required this.onNextChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      color: Colors.black.withValues(alpha: 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(icon: Icon(isAutoScrolling ? Icons.pause_circle_filled : Icons.play_circle_outline, color: Colors.blue), onPressed: onToggleAutoScroll),
              DropdownButton<int>(
                dropdownColor: Colors.grey[900], value: readingMode,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('垂直', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 1, child: Text('水平', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 2, child: Text('WebToon', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => onModeChanged(v!),
              ),
              if (readingMode == 1)
                IconButton(icon: Icon(isReverseDirection ? Icons.swap_horiz : Icons.trending_flat, color: Colors.white), onPressed: onToggleDirection),
              const Spacer(),
              const Icon(Icons.brightness_6, color: Colors.white70, size: 18),
              SizedBox(width: 80, child: Slider(value: brightness, min: 0.1, max: 1.0, onChanged: onBrightnessChanged)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: hasPrev ? onPrevChapter : null, child: const Text('上一章', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: hasNext ? onNextChapter : null, child: const Text('下一章', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }
}

