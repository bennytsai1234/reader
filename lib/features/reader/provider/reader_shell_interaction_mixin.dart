import 'reader_auto_page_mixin.dart';
import 'reader_provider_base.dart';

mixin ReaderShellInteractionMixin on ReaderProviderBase, ReaderAutoPageMixin {
  double backgroundBlur = 0.0;

  void guardTransientViewportChangesForShell();
  void updateCurrentThemeBackgroundImage(String? path);

  void toggleControls() {
    guardTransientViewportChangesForShell();
    showControls = !showControls;
    if (showControls) {
      pauseAutoPage();
    } else {
      resumeAutoPage();
    }
    notifyListeners();
  }

  void setBackgroundBlur(double value) {
    backgroundBlur = value;
    notifyListeners();
  }

  void dismissControls() {
    if (!showControls) return;
    toggleControls();
  }

  void setBackgroundImage(String? path) {
    updateCurrentThemeBackgroundImage(path);
    notifyListeners();
  }
}
