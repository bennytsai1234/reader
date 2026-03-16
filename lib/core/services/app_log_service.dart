import 'dart:collection';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../di/injection.dart';

/// AppLog - 全域日誌記錄器 (原 Android constant/AppLog.kt)
class AppLog {
  AppLog._();

  static final _logs = Queue<LogEntry>();
  static const int _maxLogs = 100;

  static final _toastController = StreamController<String>.broadcast();
  static Stream<String> get toastStream => _toastController.stream;

  static List<LogEntry> get logs => _logs.toList();

  /// 記錄日誌 (原 Android AppLog.kt)
  static void put(String message, {Object? error, StackTrace? stackTrace, bool toast = false}) {
    if (_logs.length >= _maxLogs) {
      _logs.removeLast();
    }
    
    final entry = LogEntry(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    
    _logs.addFirst(entry);

    if (kDebugMode) {
      if (error != null) {
        getIt<Logger>().e(message, error: error, stackTrace: stackTrace);
      } else {
        getIt<Logger>().d(message);
      }
    }

    if (toast) {
      _toastController.add(message);
    }
  }

  static void i(String message, {bool toast = false}) => put(message, toast: toast);
  static void d(String message, {bool toast = false}) => put(message, toast: toast);
  static void w(String message, {bool toast = false}) => put(message, toast: toast);
  static void e(String message, {Object? error, StackTrace? stackTrace, bool toast = false}) 
      => put(message, error: error, stackTrace: stackTrace, toast: toast);

  static void clear() {
    _logs.clear();
  }
}

class LogEntry {
  final int timestamp;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.message,
    this.error,
    this.stackTrace,
  });
}

