import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/models/read_record.dart';
import 'package:inkpage_reader/core/database/dao/read_record_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';

class ReadRecordProvider extends ChangeNotifier {
  final ReadRecordDao _dao = getIt<ReadRecordDao>();

  List<ReadRecord> _records = [];
  List<ReadRecord> get records => _records;

  int _totalTime = 0;
  int get totalTime => _totalTime;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchKey = '';

  ReadRecordProvider() {
    loadRecords();
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allRecords = await _dao.getAllTime();
      _totalTime = allRecords.fold<int>(0, (sum, item) => sum + item.readTime);
      if (_searchKey.isEmpty) {
        _records = await _dao.getAllShow();
      } else {
        _records = await _dao.search(_searchKey);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String key) {
    _searchKey = key;
    loadRecords();
  }

  Future<void> deleteRecord(String bookName) async {
    await _dao.deleteByName(bookName);
    await loadRecords();
  }

  Future<void> clearAll() async {
    await _dao.clearAll();
    await loadRecords();
  }

  String formatDuration(int seconds) {
    if (seconds <= 0) return '0 秒';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    final parts = <String>[];

    if (hours > 0) {
      parts.add('$hours 小時');
    }
    if (minutes > 0) {
      parts.add('$minutes 分鐘');
    }
    if (remainingSeconds > 0 || parts.isEmpty) {
      parts.add('$remainingSeconds 秒');
    }

    return parts.join(' ');
  }
}
