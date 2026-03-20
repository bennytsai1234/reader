import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/runtime/reader_auto_page_coordinator.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';

/// ReaderProvider 的自動翻頁擴展
/// 對標 Android AutoPager：定時器驅動的自動翻頁 + 掃描線效果
mixin ReaderAutoPageMixin on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin {
  // --- 自動翻頁穩定版 (對標 Android AutoPager) ---
  final ReaderAutoPageCoordinator _autoPageCoordinator =
      ReaderAutoPageCoordinator();

  bool get isAutoPaging => _autoPageCoordinator.isActive;
  double get autoPageSpeed => _autoPageCoordinator.speed; // 單位：秒/頁
  bool get _isAutoPagePaused => _autoPageCoordinator.isPaused;

  bool get isAutoPagePaused => _isAutoPagePaused;
  double scrollDeltaPerFrame(Size viewSize, double dtSeconds) {
    return (viewSize.height / autoPageSpeed.clamp(1.0, 600.0)) * dtSeconds;
  }

  void toggleAutoPage() {
    _autoPageCoordinator.isActive = !_autoPageCoordinator.isActive;
    if (isAutoPaging) {
      // 自動翻頁與 TTS 互斥
      if (TTSService().isPlaying) TTSService().stop();
      _autoPageCoordinator.isPaused = false;
      _startAutoPage();
      // 這裡可以呼叫 WakelockPlus 保持螢幕常亮
    } else {
      stopAutoPage();
    }
    notifyListeners();
  }

  /// 手動操作時暫停 (對標 Android onMenuShow/onTouch)
  void pauseAutoPage() {
    if (isAutoPaging && !_isAutoPagePaused) {
      _autoPageCoordinator.isPaused = true;
      notifyListeners();
    }
  }

  /// 手動操作結束後恢復
  void resumeAutoPage() {
    if (isAutoPaging && _isAutoPagePaused) {
      _autoPageCoordinator.isPaused = false;
      notifyListeners();
    }
  }

  void _startAutoPage() {
    _autoPageCoordinator.start(
      shouldTick: () => !TTSService().isPlaying,
      onTick: () {
        if (pageTurnMode != PageAnim.scroll &&
            autoPageProgressNotifier.value >= 1.0) {
          autoPageProgressNotifier.value = 0.0;
          nextPage(reason: ReaderCommandReason.autoPage);
        }
      },
      onProgress: (delta) {
        if (pageTurnMode != PageAnim.scroll) {
          autoPageProgressNotifier.value += delta;
          return;
        }
        final viewSize = this.viewSize;
        if (viewSize == null) return;
        final deltaPixels = scrollDeltaPerFrame(viewSize, 0.016);
        final pageBasis = viewSize.height <= 0 ? 1.0 : viewSize.height;
        autoPageProgressNotifier.value =
            ((autoPageProgressNotifier.value * pageBasis) + deltaPixels) %
                pageBasis /
                pageBasis;
      },
    );
  }

  void setAutoPageSpeed(double speed) {
    _autoPageCoordinator.speed = speed;
    if (isAutoPaging) _startAutoPage();
    notifyListeners();
  }

  void stopAutoPage() {
    _autoPageCoordinator.stop((progress) {
      autoPageProgressNotifier.value = progress;
    });
    notifyListeners();
  }

  void disposeAutoPageCoordinator() {
    _autoPageCoordinator.dispose();
    autoPageProgressNotifier.value = 0.0;
  }
}
