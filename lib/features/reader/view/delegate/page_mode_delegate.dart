import 'package:flutter/widgets.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

abstract class PageModeDelegate {
  const PageModeDelegate();

  Widget build({
    required BuildContext context,
    required ReaderProvider provider,
    required PageController pageController,
  });
}
