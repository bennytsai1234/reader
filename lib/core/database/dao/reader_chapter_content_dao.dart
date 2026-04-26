import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'reader_chapter_content_dao.g.dart';

@DriftAccessor(tables: [ReaderChapterContents])
class ReaderChapterContentDao extends DatabaseAccessor<AppDatabase>
    with _$ReaderChapterContentDaoMixin {
  ReaderChapterContentDao(super.db);

  static String cacheKey({
    required String origin,
    required String bookUrl,
    required String chapterUrl,
  }) {
    final material = '$origin\n$bookUrl\n$chapterUrl';
    return sha1.convert(utf8.encode(material)).toString();
  }

  Future<String?> getContent({
    required String cacheKey,
    int? minUpdatedAt,
  }) async {
    final query = select(readerChapterContents)
      ..where((t) => t.cacheKey.equals(cacheKey));
    if (minUpdatedAt != null) {
      query.where(
        (t) =>
            t.isPersistent.equals(true) |
            t.updatedAt.isBiggerOrEqualValue(minUpdatedAt),
      );
    }
    final row = await query.getSingleOrNull();
    final content = row?.content;
    return content == null || content.isEmpty ? null : content;
  }

  Future<bool> hasContent({required String cacheKey, int? minUpdatedAt}) async {
    final content = await getContent(
      cacheKey: cacheKey,
      minUpdatedAt: minUpdatedAt,
    );
    return content != null && content.isNotEmpty;
  }

  Future<Set<int>> getCachedChapterIndices({
    required String origin,
    required String bookUrl,
    bool persistentOnly = false,
  }) async {
    final query = select(readerChapterContents)..where(
      (t) =>
          t.origin.equals(origin) &
          t.bookUrl.equals(bookUrl) &
          t.content.isNotNull() &
          t.content.isNotValue(''),
    );
    if (persistentOnly) {
      query.where((t) => t.isPersistent.equals(true));
    }
    final rows = await query.get();
    return rows.map((row) => row.chapterIndex).toSet();
  }

  Future<int> getFailureCount(String cacheKey) async {
    final row =
        await (select(readerChapterContents)
          ..where((t) => t.cacheKey.equals(cacheKey))).getSingleOrNull();
    return row?.failureCount ?? 0;
  }

  Future<void> saveContent({
    required String cacheKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String content,
    required int updatedAt,
    bool isPersistent = false,
  }) {
    return into(readerChapterContents).insertOnConflictUpdate(
      ReaderChapterContentsCompanion.insert(
        cacheKey: cacheKey,
        origin: origin,
        bookUrl: bookUrl,
        chapterUrl: chapterUrl,
        chapterIndex: chapterIndex,
        content: Value(content),
        updatedAt: updatedAt,
        isPersistent: Value(isPersistent),
        failureCount: const Value(0),
      ),
    );
  }

  Future<void> recordFailure({
    required String cacheKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required int updatedAt,
  }) async {
    final current = await getFailureCount(cacheKey);
    await into(readerChapterContents).insertOnConflictUpdate(
      ReaderChapterContentsCompanion.insert(
        cacheKey: cacheKey,
        origin: origin,
        bookUrl: bookUrl,
        chapterUrl: chapterUrl,
        chapterIndex: chapterIndex,
        updatedAt: updatedAt,
        failureCount: Value(current + 1),
      ),
    );
  }

  Future<void> deleteByBook(String origin, String bookUrl) {
    return (delete(readerChapterContents)
      ..where((t) => t.origin.equals(origin) & t.bookUrl.equals(bookUrl))).go();
  }

  Future<void> deleteContentByBook(String origin, String bookUrl) {
    return (update(readerChapterContents)..where(
      (t) => t.origin.equals(origin) & t.bookUrl.equals(bookUrl),
    )).write(const ReaderChapterContentsCompanion(content: Value(null)));
  }

  Future<void> clearAllContent() {
    return update(
      readerChapterContents,
    ).write(const ReaderChapterContentsCompanion(content: Value(null)));
  }

  Future<int> getTotalContentSize() async {
    final rows =
        await customSelect(
          'SELECT COALESCE(SUM(LENGTH(content)), 0) AS total FROM reader_chapter_contents WHERE content IS NOT NULL AND content != ""',
          readsFrom: {readerChapterContents},
        ).get();
    if (rows.isEmpty) return 0;
    return rows.first.read<int>('total');
  }

  Future<int> cleanupOlderThan(int cutoffMillis) {
    return (delete(readerChapterContents)..where(
      (t) =>
          t.isPersistent.equals(false) &
          t.updatedAt.isSmallerThanValue(cutoffMillis),
    )).go();
  }
}
