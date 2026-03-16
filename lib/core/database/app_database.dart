import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// AppDatabase - SQLite 全域管理器
/// 負責資料庫初始化、版本遷移 (Migration) 與實例維護
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'legado_reader.db');

    return await openDatabase(
      path,
      version: 1, // 初始版本
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 建立所有核心表格 (對標 Android Room Schema)
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. 書籍表 (books)
    batch.execute('''
      CREATE TABLE books (
        bookUrl TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT,
        coverUrl TEXT,
        intro TEXT,
        customCoverUrl TEXT,
        customIntro TEXT,
        customName TEXT,
        customTag TEXT,
        group INTEGER DEFAULT 0,
        origin TEXT,
        originName TEXT,
        type INTEGER DEFAULT 0,
        isInBookshelf INTEGER DEFAULT 0,
        durChapterIndex INTEGER DEFAULT 0,
        durChapterPos INTEGER DEFAULT 0,
        durChapterTitle TEXT,
        durChapterTime INTEGER DEFAULT 0,
        lastCheckTime INTEGER DEFAULT 0,
        lastCheckCount INTEGER DEFAULT 0,
        totalChapterNum INTEGER DEFAULT 0,
        latestChapterTitle TEXT,
        latestChapterTime INTEGER DEFAULT 0,
        canUpdate INTEGER DEFAULT 1,
        order INTEGER DEFAULT 0,
        variable TEXT
      )
    ''');

    // 2. 章節表 (chapters) - 包含內容以便於管理
    batch.execute('''
      CREATE TABLE chapters (
        url TEXT PRIMARY KEY,
        bookUrl TEXT NOT NULL,
        title TEXT NOT NULL,
        `index` INTEGER NOT NULL,
        content TEXT,
        isVip INTEGER DEFAULT 0,
        tag TEXT,
        startFragmentId TEXT,
        endFragmentId TEXT,
        variable TEXT
      )
    ''');
    batch.execute('CREATE INDEX idx_chapters_bookUrl ON chapters (bookUrl)');

    // 3. 書源表 (book_sources)
    batch.execute('''
      CREATE TABLE book_sources (
        bookSourceUrl TEXT PRIMARY KEY,
        bookSourceName TEXT NOT NULL,
        bookSourceGroup TEXT,
        bookSourceType INTEGER DEFAULT 0,
        bookSourceComment TEXT,
        customOrder INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        enabledExplore INTEGER DEFAULT 1,
        header TEXT,
        loginUrl TEXT,
        ruleBookInfo TEXT,
        ruleContent TEXT,
        ruleExplore TEXT,
        ruleSearch TEXT,
        ruleToc TEXT,
        weight INTEGER DEFAULT 0,
        exploreUrl TEXT,
        lastUpdateTime INTEGER DEFAULT 0,
        respondTime INTEGER DEFAULT 0,
        variable TEXT
      )
    ''');

    // 4. 書籍分組表 (book_groups)
    batch.execute('''
      CREATE TABLE book_groups (
        groupId INTEGER PRIMARY KEY,
        groupName TEXT NOT NULL,
        groupOrder INTEGER DEFAULT 0,
        show INTEGER DEFAULT 1,
        coverPath TEXT,
        enableRefresh INTEGER DEFAULT 1,
        bookSort INTEGER DEFAULT 0
      )
    ''');

    // 5. 搜尋歷史表 (search_history)
    batch.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword TEXT UNIQUE NOT NULL,
        searchTime INTEGER NOT NULL
      )
    ''');

    // 6. 替換規則表 (replace_rules)
    batch.execute('''
      CREATE TABLE replace_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        pattern TEXT NOT NULL,
        replacement TEXT,
        scope TEXT,
        enabled INTEGER DEFAULT 1,
        isRegex INTEGER DEFAULT 1,
        `group` TEXT,
        `order` INTEGER DEFAULT 0
      )
    ''');

    // 7. 書籤表 (bookmarks)
    batch.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time INTEGER NOT NULL,
        bookName TEXT NOT NULL,
        bookAuthor TEXT,
        chapterIndex INTEGER DEFAULT 0,
        chapterPos INTEGER DEFAULT 0,
        chapterName TEXT,
        bookUrl TEXT NOT NULL,
        bookText TEXT,
        content TEXT
      )
    ''');

    // 8. Cookie 表 (cookie)
    batch.execute('''
      CREATE TABLE cookie (
        url TEXT PRIMARY KEY,
        cookie TEXT NOT NULL
      )
    ''');

    // 9. 字典規則表 (dict_rules)
    batch.execute('''
      CREATE TABLE dict_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        urlRule TEXT,
        showRule TEXT,
        enabled INTEGER DEFAULT 1,
        sortNumber INTEGER DEFAULT 0
      )
    ''');

    // 10. HTTP TTS 表 (http_tts)
    batch.execute('''
      CREATE TABLE http_tts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        contentType TEXT,
        concurrentRate TEXT,
        loginUrl TEXT,
        loginUi TEXT,
        header TEXT,
        jsLib TEXT,
        enabledCookieJar INTEGER DEFAULT 0,
        loginCheckJs TEXT,
        lastUpdateTime INTEGER DEFAULT 0
      )
    ''');

    // 11. 閱讀紀錄表 (read_records)
    batch.execute('''
      CREATE TABLE read_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookName TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        readTime INTEGER DEFAULT 0,
        lastRead INTEGER DEFAULT 0
      )
    ''');

    // 12. RSS 文章表 (rss_articles)
    batch.execute('''
      CREATE TABLE rss_articles (
        link TEXT PRIMARY KEY,
        origin TEXT NOT NULL,
        sort TEXT NOT NULL,
        title TEXT NOT NULL,
        `order` INTEGER DEFAULT 0,
        pubDate TEXT,
        description TEXT,
        content TEXT,
        image TEXT,
        `group` TEXT DEFAULT '預設分組',
        read INTEGER DEFAULT 0,
        variable TEXT
      )
    ''');

    // 13. RSS 源表 (rss_sources)
    batch.execute('''
      CREATE TABLE rss_sources (
        sourceUrl TEXT PRIMARY KEY,
        sourceName TEXT NOT NULL,
        sourceIcon TEXT,
        sourceGroup TEXT,
        sourceComment TEXT,
        enabled INTEGER DEFAULT 1,
        variableComment TEXT,
        jsLib TEXT,
        enabledCookieJar INTEGER DEFAULT 1,
        concurrentRate TEXT,
        header TEXT,
        loginUrl TEXT,
        loginUi TEXT,
        loginCheckJs TEXT,
        coverDecodeJs TEXT,
        sortUrl TEXT,
        singleUrl INTEGER DEFAULT 0,
        articleStyle INTEGER DEFAULT 0,
        ruleArticles TEXT,
        ruleNextPage TEXT,
        ruleTitle TEXT,
        rulePubDate TEXT,
        ruleDescription TEXT,
        ruleImage TEXT,
        ruleLink TEXT,
        ruleContent TEXT,
        contentWhitelist TEXT,
        contentBlacklist TEXT,
        shouldOverrideUrlLoading TEXT,
        style TEXT,
        enableJs INTEGER DEFAULT 1,
        loadWithBaseUrl INTEGER DEFAULT 1,
        injectJs TEXT,
        lastUpdateTime INTEGER DEFAULT 0,
        customOrder INTEGER DEFAULT 0
      )
    ''');

    // 14. RSS 收藏表 (rss_stars)
    batch.execute('''
      CREATE TABLE rss_stars (
        link TEXT NOT NULL,
        origin TEXT NOT NULL,
        sort TEXT NOT NULL,
        title TEXT NOT NULL,
        starTime INTEGER DEFAULT 0,
        pubDate TEXT,
        description TEXT,
        content TEXT,
        image TEXT,
        `group` TEXT DEFAULT '默认分组',
        variable TEXT,
        PRIMARY KEY (link, origin)
      )
    ''');

    // 15. 伺服器表 (servers)
    batch.execute('''
      CREATE TABLE servers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        config TEXT,
        sortNumber INTEGER DEFAULT 0
      )
    ''');

    // 16. TXT 目錄規則表 (txt_toc_rules)
    batch.execute('''
      CREATE TABLE txt_toc_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rule TEXT NOT NULL,
        example TEXT,
        serialNumber INTEGER DEFAULT -1,
        enable INTEGER DEFAULT 1
      )
    ''');

    // 17. 快取表 (cache)
    batch.execute('''
      CREATE TABLE cache (
        `key` TEXT PRIMARY KEY,
        `value` TEXT,
        deadline INTEGER DEFAULT 0
      )
    ''');

    // 18. 鍵盤輔助表 (keyboard_assists)
    batch.execute('''
      CREATE TABLE keyboard_assists (
        `key` TEXT PRIMARY KEY,
        type INTEGER DEFAULT 0,
        `value` TEXT,
        serialNo INTEGER DEFAULT 0
      )
    ''');

    // 19. RSS 閱讀紀錄表 (rss_read_records)
    batch.execute('''
      CREATE TABLE rss_read_records (
        record TEXT PRIMARY KEY,
        title TEXT,
        readTime INTEGER DEFAULT 0,
        read INTEGER DEFAULT 0
      )
    ''');

    // 20. 訂閱規則表 (rule_subs)
    batch.execute('''
      CREATE TABLE rule_subs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        type INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        `order` INTEGER DEFAULT 0
      )
    ''');

    // 21. 書源訂閱表 (source_subscriptions)
    batch.execute('''
      CREATE TABLE source_subscriptions (
        url TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        `order` INTEGER DEFAULT 0
      )
    ''');

    // 22. 搜尋書籍快取表 (search_books)
    batch.execute('''
      CREATE TABLE search_books (
        bookUrl TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT,
        kind TEXT,
        coverUrl TEXT,
        intro TEXT,
        wordCount TEXT,
        latestChapterTitle TEXT,
        origin TEXT,
        originName TEXT,
        originOrder INTEGER DEFAULT 0,
        type INTEGER DEFAULT 0,
        addTime INTEGER DEFAULT 0,
        variable TEXT,
        tocUrl TEXT
      )
    ''');

    // 23. 下載任務表 (download_tasks)
    batch.execute('''
      CREATE TABLE download_tasks (
        bookUrl TEXT PRIMARY KEY,
        bookName TEXT NOT NULL,
        currentChapterIndex INTEGER DEFAULT 0,
        totalChapterCount INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        successCount INTEGER DEFAULT 0,
        errorCount INTEGER DEFAULT 0,
        addTime INTEGER DEFAULT 0
      )
    ''');

    // 24. 搜尋關鍵字表 (search_keywords)
    batch.execute('''
      CREATE TABLE search_keywords (
        word TEXT PRIMARY KEY,
        usage INTEGER DEFAULT 0,
        lastUseTime INTEGER DEFAULT 0
      )
    ''');

    await batch.commit();
    debugPrint('Database Tables Created Successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 留待未來升級使用
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}

/// BaseDao - SQLite DAO 基底類別
abstract class BaseDao<T> {
  final AppDatabase appDatabase;
  final String tableName;

  BaseDao(this.appDatabase, this.tableName);

  Future<Database> get db => appDatabase.database;

  /// 通用插入或更新 (UPSERT) 邏輯
  Future<int> insertOrUpdate(Map<String, dynamic> row) async {
    final client = await db;
    return await client.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(String where, [List<dynamic>? whereArgs]) async {
    final client = await db;
    return await client.delete(tableName, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> queryAll({String? orderBy}) async {
    final client = await db;
    return await client.query(tableName, orderBy: orderBy);
  }

  Future<int> clear() async {
    final client = await db;
    return await client.delete(tableName);
  }
}
