import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';

/// ReaderProvider 的自動翻頁擴展
/// 對標 Android AutoPager：定時器驅動的自動翻頁 + 掃描線效果
mixin ReaderAutoPageMixin on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin {
  // --- 自動翻頁穩定版 (對標 Android AutoPager) ---
  bool isAutoPaging = false;
  double autoPageSpeed = 30.0; // 單位：秒/頁
  Timer? autoPageTimer;
  bool _isAutoPagePaused = false;

  bool get isAutoPagePaused => _isAutoPagePaused;
  double scrollDeltaPerFrame(Size viewSize, double dtSeconds) {
    return (viewSize.height / autoPageSpeed.clamp(1.0, 600.0)) * dtSeconds;
  }

  void toggleAutoPage() {
    isAutoPaging = !isAutoPaging;
    if (isAutoPaging) {
      // 自動翻頁與 TTS 互斥
      if (TTSService().isPlaying) TTSService().stop();
      _isAutoPagePaused = false;
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
      _isAutoPagePaused = true;
      notifyListeners();
    }
  }

  /// 手動操作結束後恢復
  void resumeAutoPage() {
    if (isAutoPaging && _isAutoPagePaused) {
      _isAutoPagePaused = false;
      notifyListeners();
    }
  }

  void _startAutoPage() {
    autoPageTimer?.cancel();
    autoPageProgressNotifier.value = 0.0;

    // 採用 16ms (約 60fps) 的高頻 tick 以支援像素級平滑捲動，同時兼容分頁模式
    autoPageTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isAutoPagePaused || !isAutoPaging) return;
      if (TTSService().isPlaying) return; // TTS 播放中不自動翻頁

      // 如果是分頁模式 (pageTurnMode != PageAnim.scroll)，則按時間進度翻頁
      if (pageTurnMode != PageAnim.scroll) {
        final double delta = 0.016 / autoPageSpeed.clamp(1.0, 600.0);
        autoPageProgressNotifier.value += delta;

        if (autoPageProgressNotifier.value >= 1.0) {
          autoPageProgressNotifier.value = 0.0;
          nextPage();
        }
      } else {
        final viewSize = this.viewSize;
        if (viewSize == null) return;
        final deltaPixels = scrollDeltaPerFrame(viewSize, 0.016);
        final pageBasis = viewSize.height <= 0 ? 1.0 : viewSize.height;
        autoPageProgressNotifier.value =
            ((autoPageProgressNotifier.value * pageBasis) + deltaPixels) % pageBasis / pageBasis;
      }
    });
  }

  void setAutoPageSpeed(double speed) {
    autoPageSpeed = speed;
    if (isAutoPaging) _startAutoPage();
    notifyListeners();
  }

  void stopAutoPage() {
    isAutoPaging = false;
    _isAutoPagePaused = false;
    autoPageTimer?.cancel();
    autoPageTimer = null;
    autoPageProgressNotifier.value = 0.0;
    notifyListeners();
  }
}
