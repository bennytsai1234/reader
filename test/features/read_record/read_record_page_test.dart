import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/read_record_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/read_record.dart';
import 'package:inkpage_reader/features/read_record/read_record_page.dart';

class _FakeReadRecordDao extends Fake implements ReadRecordDao {
  _FakeReadRecordDao(this._records);

  final List<ReadRecord> _records;

  @override
  Future<List<ReadRecord>> getAllTime() async =>
      List<ReadRecord>.from(_records);

  @override
  Future<List<ReadRecord>> getAllShow() async =>
      List<ReadRecord>.from(_records);

  @override
  Future<List<ReadRecord>> search(String key) async {
    return _records
        .where((record) => record.bookName.contains(key))
        .toList(growable: false);
  }

  @override
  Future<void> clearAll() async => _records.clear();

  @override
  Future<void> deleteByName(String bookName) async {
    _records.removeWhere((record) => record.bookName == bookName);
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerLazySingleton<ReadRecordDao>(
      () => _FakeReadRecordDao(<ReadRecord>[
        ReadRecord(
          id: 1,
          bookName: 'Long Book',
          readTime: 3661,
          lastRead: DateTime(2026, 4, 20, 9).millisecondsSinceEpoch,
        ),
        ReadRecord(
          id: 2,
          bookName: 'Quick Book',
          readTime: 59,
          lastRead: DateTime(2026, 4, 19, 8).millisecondsSinceEpoch,
        ),
      ]),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('ReadRecordPage formats stored durations as seconds-based time', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReadRecordPage()));
    await tester.pumpAndSettle();

    expect(find.text('閱讀紀錄'), findsOneWidget);
    expect(find.text('共閱讀了 2 本書'), findsOneWidget);
    expect(find.text('累計時長: 1 小時 2 分鐘'), findsOneWidget);
    expect(find.text('累計時長: 1 小時 1 分鐘 1 秒'), findsOneWidget);
    expect(find.text('累計時長: 59 秒'), findsOneWidget);
  });
}
