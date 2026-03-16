import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';

/// EpubService - 專業 EPUB 解析與資源服務
/// 提供 Isolate 友善的解析接口與資源管理
class EpubService {
  static final EpubService _instance = EpubService._internal();
  factory EpubService() => _instance;
  EpubService._internal();

  /// 在背景線程解析 EPUB 元數據與章節
  Future<EpubMetadata> parseMetadata(File file) async {
    return await compute((_) async {
      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      
      final chapters = <Map<String, String>>[];
      _processChapters(epubBook.Chapters ?? [], 0, chapters);

      return EpubMetadata(
        title: epubBook.Title ?? 'Unknown Title',
        author: epubBook.Author ?? 'Unknown Author',
        chapters: chapters,
        coverBytes: await _extractCover(epubBook),
      );
    }, null);
  }

  /// 獲取特定章節的 HTML 正文
  Future<String> getChapterContent(File file, String href) async {
    return await compute((arg) async {
      final bytes = await arg.file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      
      final fileName = arg.href.split('#').first;
      final htmlFile = epubBook.Content?.Html?[fileName];
      return htmlFile?.Content ?? '';
    }, (file: file, href: href));
  }

  static void _processChapters(List<EpubChapter> epubChapters, int level, List<Map<String, String>> results) {
    for (final chapter in epubChapters) {
      final prefix = '  ' * level;
      results.add({
        'title': "$prefix${chapter.Title ?? "Unnamed"}",
        'href': chapter.ContentFileName ?? '',
      });
      if (chapter.SubChapters != null) {
        _processChapters(chapter.SubChapters!, level + 1, results);
      }
    }
  }

  static Future<Uint8List?> _extractCover(EpubBook book) async {
    try {
      String? coverId;
      book.Schema?.Package?.Manifest?.Items?.forEach((item) {
        if (item.Properties != null && item.Properties!.contains('cover-image')) {
          coverId = item.Id;
        }
      });

      if (coverId != null) {
        final coverFile = book.Content?.Images?[coverId];
        if (coverFile != null) return Uint8List.fromList(coverFile.Content!);
      }
      
      for (var key in book.Content?.Images?.keys ?? []) {
        if (key.toString().toLowerCase().contains('cover')) {
          return Uint8List.fromList(book.Content!.Images![key]!.Content!);
        }
      }
    } catch (_) {}
    return null;
  }
}

class EpubMetadata {
  final String title;
  final String author;
  final List<Map<String, String>> chapters;
  final Uint8List? coverBytes;

  EpubMetadata({
    required this.title,
    required this.author,
    required this.chapters,
    this.coverBytes,
  });
}

