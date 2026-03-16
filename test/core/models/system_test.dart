import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/cookie.dart';
import 'package:legado_reader/core/models/search_keyword.dart';
import 'package:legado_reader/core/models/server.dart';
import 'package:legado_reader/core/models/keyboard_assist.dart';
import 'package:legado_reader/core/models/cache.dart';
import 'dart:convert';

void main() {
  group('System and Utility Models Tests', () {
    test('Cookie serialization', () {
      final cookie = Cookie(url: 'https://example.com', cookie: 'key=val');
      final json = cookie.toJson();
      final fromJson = Cookie.fromJson(json);
      expect(fromJson.url, 'https://example.com');
      expect(fromJson.cookie, 'key=val');
    });

    test('SearchKeyword serialization', () {
      final sk = SearchKeyword(word: 'flutter', usage: 10);
      final json = sk.toJson();
      final fromJson = SearchKeyword.fromJson(json);
      expect(fromJson.word, 'flutter');
      expect(fromJson.usage, 10);
    });

    test('Server and WebDavConfig serialization', () {
      final webdav = WebDavConfig(url: 'http://dav.com', username: 'user', password: 'pwd');
      final server = Server(id: 1, name: 'MyCloud', config: jsonEncode(webdav.toJson()));
      
      final json = server.toJson();
      final fromJson = Server.fromJson(json);
      expect(fromJson.name, 'MyCloud');
      expect(fromJson.webDavConfig?.username, 'user');
    });

    test('KeyboardAssist serialization', () {
      final assist = KeyboardAssist(key: 'A', value: 'Alpha');
      final json = assist.toJson();
      final fromJson = KeyboardAssist.fromJson(json);
      expect(fromJson.key, 'A');
      expect(fromJson.value, 'Alpha');
    });

    test('Cache serialization', () {
      final cache = Cache(key: 'key1', value: 'data', deadline: 12345);
      final json = cache.toJson();
      final fromJson = Cache.fromJson(json);
      expect(fromJson.key, 'key1');
      expect(fromJson.deadline, 12345);
    });
  });
}
