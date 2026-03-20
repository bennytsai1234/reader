import 'reading_window.dart';

class DisplayWindowState {
  final List<int> chapterOrder;
  final ReadingWindow window;

  const DisplayWindowState({
    required this.chapterOrder,
    required this.window,
  });

  static const empty = DisplayWindowState(
    chapterOrder: [],
    window: ReadingWindow.empty,
  );

  bool get isEmpty => window.isEmpty;
  bool get isNotEmpty => window.isNotEmpty;
  int? get firstChapter => chapterOrder.isEmpty ? null : chapterOrder.first;
  int? get lastChapter => chapterOrder.isEmpty ? null : chapterOrder.last;
}
