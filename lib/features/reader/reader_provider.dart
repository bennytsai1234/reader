import 'package:legado_reader/features/reader/runtime/read_book_controller.dart';

export 'package:legado_reader/features/reader/runtime/read_book_controller.dart';

class ReaderProvider extends ReadBookController {
  ReaderProvider({
    required super.book,
    super.chapterIndex = 0,
    super.chapterPos = 0,
  });
}
