import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';

/// AppDatabase 的基礎生命週期管理
abstract class DatabaseBase {
  static const String dbName = 'legado_reader.db';
  static const int dbVersion = 11;
  static Database? databaseInstance;
  static final lock = Lock();

  static Future<Database> getDatabase({
    required Future<void> Function(Database, int) onCreate,
    required Future<void> Function(Database, int, int) onUpgrade,
  }) async {
    final db = databaseInstance;
    if (db != null && db.isOpen) return db;

    return await lock.synchronized(() async {
      if (databaseInstance != null && databaseInstance!.isOpen) return databaseInstance!;
      debugPrint('Database: Starting initialization...');
      try {
        databaseInstance = await _initInternal(onCreate, onUpgrade);
      } catch (e) {
        debugPrint('Database: First initialization attempt failed: $e');
        if (e.toString().contains('no current transaction') || e.toString().contains('database is locked')) {
          await Future.delayed(const Duration(milliseconds: 500));
          databaseInstance = await _initInternal(onCreate, onUpgrade);
        } else {
          rethrow;
        }
      }
      debugPrint('Database: Initialization completed.');
      return databaseInstance!;
    });
  }

  static Future<Database> _initInternal(
    Future<void> Function(Database, int) onCreate,
    Future<void> Function(Database, int, int) onUpgrade,
  ) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return openDatabase(
      path,
      version: dbVersion,
      onCreate: (db, version) async {
        debugPrint('Database: onCreate started (version: $version)');
        await onCreate(db, version);
        debugPrint('Database: onCreate finished');
      },
      onUpgrade: (db, old, newV) async {
        debugPrint('Database: onUpgrade started ($old -> $newV)');
        await onUpgrade(db, old, newV);
        debugPrint('Database: onUpgrade finished');
      },
    );
  }

  static Future<void> closeDatabase() async {
    final db = databaseInstance;
    if (db != null) {
      await db.close();
      databaseInstance = null;
    }
  }
}

