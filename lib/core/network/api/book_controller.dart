import 'dart:convert';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'return_data.dart';

class BookController {
  final BookDao _dao = getIt<BookDao>();

  Future<ReturnData> getBookshelf() async {
    final books = await _dao.getAll();
    return ReturnData(data: books.map((e) => e.toJson()).toList());
  }

  Future<ReturnData> deleteBook(String json) async {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      final url = data['bookUrl'];
      await _dao.deleteByUrl(url);
      return ReturnData(msg: '刪除成功');
    } catch (e) {
      return ReturnData(code: 500, msg: '刪除失敗: $e');
    }
  }
}

