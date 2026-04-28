import 'text_page.dart';

class ChapterLayout {
  const ChapterLayout({
    required this.chapterIndex,
    required this.contentHash,
    required this.layoutSignature,
    required this.lines,
    required this.pages,
  });

  final int chapterIndex;
  final String contentHash;
  final String layoutSignature;
  final List<TextLine> lines;
  final List<TextPage> pages;

  TextPage pageForCharOffset(int charOffset) {
    if (pages.isEmpty) {
      return TextPage(
        pageIndex: 0,
        chapterIndex: chapterIndex,
        lines: const <TextLine>[],
        height: 1,
      );
    }
    final bodyPages = pages.where((page) => page.hasBodyContent).toList();
    if (bodyPages.isEmpty) return pages.first;
    for (final page in bodyPages) {
      if (page.containsCharOffset(charOffset)) {
        return page;
      }
    }
    if (charOffset <= bodyPages.first.startCharOffset) {
      return bodyPages.first;
    }
    var best = bodyPages.first;
    for (final page in bodyPages) {
      if (page.startCharOffset <= charOffset) {
        best = page;
        continue;
      }
      break;
    }
    return best;
  }
}
