library;

/// Core Layer - 基礎設施層統一出口
/// 包含常數、例外處理、工具類與基礎存儲元件

// Constants
export 'constant/app_const.dart';
export 'constant/app_pattern.dart';
export 'constant/book_type.dart';
export 'constant/page_anim.dart';
export 'constant/prefer_key.dart';

// Exceptions
export 'exception/app_exception.dart';

// Utilities
export 'utils/utils.dart';

// Storage Utilities
export 'storage/app_cache.dart';
export 'storage/file_doc.dart';

// Services (Core ones)
export 'services/app_log_service.dart';
export 'services/chinese_utils.dart';
export 'services/encoding_detect.dart';
export 'services/event_bus.dart';

