import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';

import 'reader_gesture_layer.dart';
import 'reader_viewport_controller.dart';
import 'scroll_reader_viewport.dart';
import 'slide_reader_viewport.dart';

class EngineReaderScreen extends StatefulWidget {
  const EngineReaderScreen({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onContentTapUp,
    this.viewportController,
    this.ttsHighlight,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onContentTapUp;
  final ReaderViewportController? viewportController;
  final ReaderTtsHighlight? ttsHighlight;

  @override
  State<EngineReaderScreen> createState() => _EngineReaderScreenState();
}

class _EngineReaderScreenState extends State<EngineReaderScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.runtime.addListener(_handleRuntimeChanged);
  }

  @override
  void didUpdateWidget(covariant EngineReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_handleRuntimeChanged);
      widget.runtime.addListener(_handleRuntimeChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.runtime.removeListener(_handleRuntimeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      unawaited(widget.runtime.flushProgress());
    }
  }

  void _handleRuntimeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final viewport =
        state.mode == ReaderMode.scroll
            ? ScrollReaderViewport(
              runtime: widget.runtime,
              backgroundColor: widget.backgroundColor,
              textColor: widget.textColor,
              style: widget.style,
              controller: widget.viewportController,
              ttsHighlight: widget.ttsHighlight,
            )
            : SlideReaderViewport(
              runtime: widget.runtime,
              backgroundColor: widget.backgroundColor,
              textColor: widget.textColor,
              style: widget.style,
              controller: widget.viewportController,
              ttsHighlight: widget.ttsHighlight,
            );
    return ReaderGestureLayer(
      onTapUp: widget.onContentTapUp,
      gesturesEnabled: widget.onContentTapUp != null,
      child: viewport,
    );
  }
}
