import 'line_layout.dart';
import 'text_page.dart';

class ChapterPositionResolver {
  const ChapterPositionResolver._();

  static double pageHeight(TextPage page) {
    return page.lines.isEmpty ? 0.0 : page.lines.last.lineBottom;
  }

  static double chapterHeight(List<TextPage> pages) {
    return LineLayout.fromPages(pages).contentHeight;
  }

  static List<double> pageTopOffsets(List<TextPage> pages) {
    return LineLayout.fromPages(pages).pageTopOffsets;
  }

  static double charOffsetToLocalOffset(List<TextPage> pages, int charOffset) {
    return LineLayout.fromPages(pages).localOffsetForCharOffset(charOffset);
  }

  static double charOffsetToAlignment(List<TextPage> pages, int charOffset) {
    final layout = LineLayout.fromPages(pages);
    final total = layout.contentHeight;
    if (total <= 0) return 0.0;
    return (layout.localOffsetForCharOffset(charOffset) / total).clamp(
      0.0,
      1.0,
    );
  }

  static int localOffsetToCharOffset(List<TextPage> pages, double localOffset) {
    return LineLayout.fromPages(pages).charOffsetFromLocalOffset(localOffset);
  }

  static int? pageLocalOffsetToCharOffset(
    TextPage page,
    double pageLocalOffset,
  ) {
    return LineLayout.fromPages([page]).charOffsetFromPageLocalOffset(
      pageIndex: 0,
      pageLocalOffset: pageLocalOffset,
    );
  }

  static int findPageIndexByCharOffset(List<TextPage> pages, int charOffset) {
    return LineLayout.fromPages(pages).findPageIndexByCharOffset(charOffset);
  }

  static int pageIndexAtLocalOffset(List<TextPage> pages, double localOffset) {
    return LineLayout.fromPages(pages).pageIndexAtLocalOffset(localOffset);
  }

  static int getCharOffsetForPage(List<TextPage> pages, int pageIndex) {
    return LineLayout.fromPages(pages).charOffsetForPageIndex(pageIndex);
  }

  static int pageEndCharOffset(TextPage page) {
    return LineLayout.fromPages([page]).pageEndCharOffset(0);
  }

  static int firstCharOffset(TextPage page) {
    return LineLayout.fromPages([page]).charOffsetForPageIndex(0);
  }
}
