import 'package:flutter/material.dart';

/// LetterFastScroller - 字母快速滾動條
/// (原 Android ui/widget/recycler/scroller/FastScroller.kt)
class LetterFastScroller extends StatelessWidget {
  final List<String> letters;
  final Function(String) onLetterTap;
  final ScrollController scrollController;

  const LetterFastScroller({
    super.key,
    required this.letters,
    required this.onLetterTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      alignment: Alignment.center,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onLetterTap(letters[index]),
            onVerticalDragUpdate: (details) {
              // 簡單的滑動追蹤邏輯
              onLetterTap(letters[index]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                letters[index],
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}

