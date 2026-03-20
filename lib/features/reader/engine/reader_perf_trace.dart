import 'dart:async';
import 'package:flutter/foundation.dart';

class ReaderPerfTrace {
  static Future<T> measureAsync<T>(
    String label,
    Future<T> Function() action,
  ) async {
    if (kReleaseMode) {
      return action();
    }

    final stopwatch = Stopwatch()..start();
    final result = await action();
    stopwatch.stop();
    debugPrint('ReaderPerf: $label took ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }
}
