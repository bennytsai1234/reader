import 'dart:convert';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'return_data.dart';

class SourceController {
  final BookSourceDao _dao = getIt<BookSourceDao>();

  Future<ReturnData> getSources() async {
    final sources = await _dao.getAllPart();
    return ReturnData(data: sources.map((e) => e.toJson()).toList());
  }

  Future<ReturnData> saveSource(String json) async {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      final source = BookSource.fromJson(data);
      await _dao.upsert(source);
      return ReturnData(msg: '保存成功');
    } catch (e) {
      return ReturnData(code: 500, msg: '保存失敗: $e');
    }
  }

  Future<ReturnData> deleteSources(String json) async {
    try {
      final List<dynamic> urls = jsonDecode(json);
      for (var url in urls) {
        await _dao.deleteByUrl(url.toString());
      }
      return ReturnData(msg: '刪除成功');
    } catch (e) {
      return ReturnData(code: 500, msg: '刪除失敗: $e');
    }
  }
}

