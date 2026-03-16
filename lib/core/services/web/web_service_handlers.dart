import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/api_response.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'web_service_base.dart';
import 'web_service_controllers.dart';
import 'web_service_utils.dart';

/// WebService 的請求處理邏輯擴展
extension WebServiceHandlers on WebServiceBase {
  Future<void> handleRequest(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      handleWebSocket(request);
      return;
    }

    final path = request.uri.path;
    final method = request.method;

    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      dynamic result;
      if (method == 'GET') {
        if (path == '/' || path == '/index.html') {
          result = await handleStaticFile('index.html');
        } else {
          result = await handleGet(path, request.uri.queryParameters);
        }
      } else if (method == 'POST') {
        if (path == '/addLocalBook') {
          result = await handleAddLocalBook(request);
        } else {
          final content = await utf8.decodeStream(request);
          result = await handlePost(path, content);
        }
      }

      if (result != null) {
        request.response.headers.contentType = ContentType.json;
        final response = ApiResponse.success(result);
        request.response.write(response.toJsonString());
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('API Not Found or Not Implemented yet.');
      }
    } catch (e) {
      debugPrint('WebService Error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      final response = ApiResponse.error(e.toString());
      request.response.write(response.toJsonString());
    } finally {
      await request.response.close();
    }
  }

  Future<dynamic> handleGet(String path, Map<String, String> params) async {
    switch (path) {
      case '/getBookSources':
        final sources = await sourceDao.getAllPart();
        return sources.map((s) => s.toJson()).toList();
      case '/getBookSource':
        final url = params['url'];
        if (url == null) return null;
        final source = await sourceDao.getByUrl(url);
        return source?.toJson();
      case '/getBookshelf':
        final books = await bookDao.getInBookshelf();
        return books.map((b) => b.toJson()).toList();
      case '/getChapterList':
        final url = params['url'];
        if (url == null) return null;
        final chapters = await chapterDao.getChapters(url);
        if (chapters.isEmpty) return await refreshToc(url);
        return chapters.map((c) => c.toJson()).toList();
      case '/refreshToc':
        final url = params['url'];
        if (url == null) return null;
        return await refreshToc(url);
      case '/getBookContent':
        final url = params['url'];
        final indexStr = params['index'];
        if (url == null || indexStr == null) return null;
        return await getBookContent(url, int.parse(indexStr));
      case '/getReplaceRules':
        final rules = await replaceDao.getAll();
        return rules.map((r) => r.toJson()).toList();
      case '/getRssSources':
        final sources = await rssDao.getAll();
        return sources.map((s) => s.toJson()).toList();
      case '/getRssSource':
        final url = params['url'];
        if (url == null) return null;
        final sources = await rssDao.getAll();
        final match = sources.where((s) => s.sourceUrl == url).firstOrNull;
        return match?.toJson();
      default:
        return null;
    }
  }

  Future<dynamic> handlePost(String path, String body) async {
    switch (path) {
      case '/renameGroup':
        final Map<String, dynamic> map = jsonDecode(body);
        if (map['oldName'] != null && map['newName'] != null) {
          await sourceDao.renameGroup(map['oldName'], map['newName']);
          return true;
        }
        return false;
      case '/deleteGroup':
        final Map<String, dynamic> map = jsonDecode(body);
        if (map['name'] != null) {
          await sourceDao.removeGroupLabel(map['name']);
          return true;
        }
        return false;
      case '/saveBookSource':
        final source = BookSource.fromJson(jsonDecode(body));
        await sourceDao.upsert(source);
        return true;
      case '/saveBookSources':
        final List<dynamic> list = jsonDecode(body);
        await sourceDao.insertOrUpdateAll(list.map((e) => BookSource.fromJson(e)).toList());
        return true;
      case '/deleteBookSources':
        final List<dynamic> urls = jsonDecode(body);
        for (var url in urls) {
          await sourceDao.deleteByUrl(url as String);
        }
        return true;
      case '/saveBook':
        final book = Book.fromJson(jsonDecode(body));
        await bookDao.upsert(book);
        return '';
      case '/deleteBook':
        final book = Book.fromJson(jsonDecode(body));
        await bookDao.deleteByUrl(book.bookUrl);
        await chapterDao.deleteByBook(book.bookUrl);
        return '';
      default:
        return (this as dynamic).handlePostExtended(path, body);
    }
  }
}

