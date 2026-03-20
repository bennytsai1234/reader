import 'package:flutter/material.dart';

import '../reader_provider.dart';
import '../view/read_view_runtime.dart';

class ReaderViewBuilder extends StatefulWidget {
  final ReaderProvider provider;
  final PageController pageController;

  const ReaderViewBuilder({
    super.key,
    required this.provider,
    required this.pageController,
  });

  @override
  State<ReaderViewBuilder> createState() => _ReaderViewBuilderState();
}

class _ReaderViewBuilderState extends State<ReaderViewBuilder> {
  @override
  Widget build(BuildContext context) {
    return ReadViewRuntime(
      provider: widget.provider,
      pageController: widget.pageController,
    );
  }
}
