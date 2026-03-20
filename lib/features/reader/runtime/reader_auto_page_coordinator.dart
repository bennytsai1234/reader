import 'dart:async';

class ReaderAutoPageCoordinator {
  bool isActive = false;
  bool isPaused = false;
  double speed = 30.0;

  Timer? _timer;

  void start({
    required bool Function() shouldTick,
    required void Function() onTick,
    required void Function(double progress) onProgress,
  }) {
    _timer?.cancel();
    onProgress(0.0);
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!isActive || isPaused || !shouldTick()) return;
      final delta = 0.016 / speed.clamp(1.0, 600.0);
      onTick();
      onProgress(delta);
    });
  }

  void stop(void Function(double progress) onProgress) {
    isActive = false;
    isPaused = false;
    _timer?.cancel();
    _timer = null;
    onProgress(0.0);
  }

  void restart({
    required bool Function() shouldTick,
    required void Function() onTick,
    required void Function(double progress) onProgress,
  }) {
    if (!isActive) return;
    start(
      shouldTick: shouldTick,
      onTick: onTick,
      onProgress: onProgress,
    );
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
