import 'dart:typed_data';

/// ResourceService - 應用內資源管理 (圖片、字體快取)
/// 用於處理 memory:// 等自定義協議資源
class ResourceService {
  static final ResourceService _instance = ResourceService._internal();
  factory ResourceService() => _instance;
  ResourceService._internal();

  final Map<String, Uint8Uint8List> _memoryCache = {};

  void setMemoryResource(String key, Uint8List data) {
    _memoryCache[key] = data;
  }

  Uint8List? getMemoryResource(String key) {
    return _memoryCache[key];
  }

  void clearCache() {
    _memoryCache.clear();
  }
}

typedef Uint8Uint8List = Uint8List; // Fix for potential naming conflicts

