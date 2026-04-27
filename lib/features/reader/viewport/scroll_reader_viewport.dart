import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/page_window.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';

import 'reader_tile_layer.dart';

class ScrollReaderViewport extends StatefulWidget {
  const ScrollReaderViewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onTapUp;

  @override
  State<ScrollReaderViewport> createState() => _ScrollReaderViewportState();
}

class _ScrollReaderViewportState extends State<ScrollReaderViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flingController;
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  double _scrollOffset = 0;
  double _lastFlingPosition = 0;
  String? _lastCurrentPageKey;
  bool _suppressExternalPageReset = false;

  @override
  void initState() {
    super.initState();
    _lastCurrentPageKey = _pageKey(widget.runtime.state.pageWindow?.current);
    _flingController =
        AnimationController.unbounded(vsync: this)
          ..addListener(_onFlingTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              _commitVisibleLocation();
            }
          });
    widget.runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didUpdateWidget(covariant ScrollReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      _scrollOffset = 0;
      _offset.value = 0;
      _lastCurrentPageKey = _pageKey(widget.runtime.state.pageWindow?.current);
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    _flingController.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final currentPageKey = _pageKey(widget.runtime.state.pageWindow?.current);
    final currentPageChanged = currentPageKey != _lastCurrentPageKey;
    if (widget.runtime.state.phase == ReaderPhase.layingOut ||
        widget.runtime.state.phase == ReaderPhase.switchingMode) {
      _scrollOffset = 0;
      _offset.value = 0;
    } else if (currentPageChanged && !_suppressExternalPageReset) {
      _scrollOffset = 0;
      _offset.value = 0;
    }
    _lastCurrentPageKey = currentPageKey;
    setState(() {});
  }

  void _onFlingTick() {
    final position = _flingController.value;
    final delta = position - _lastFlingPosition;
    _lastFlingPosition = position;
    _applyDelta(delta);
  }

  void _applyDelta(double delta) {
    final window = widget.runtime.state.pageWindow;
    if (window == null) return;
    _scrollOffset += delta;
    _maybePrefetch(delta);
    _normalizeWindowIfNeeded();
    _offset.value = _scrollOffset;
  }

  void _normalizeWindowIfNeeded() {
    PageWindow? window = widget.runtime.state.pageWindow;
    if (window == null) return;

    while (true) {
      final currentWindow = window;
      if (currentWindow == null ||
          _scrollOffset > -currentWindow.current.height) {
        break;
      }
      final oldHeight = currentWindow.current.height;
      final moved = _runViewportPageShift(widget.runtime.moveToNextTile);
      if (!moved) {
        _scrollOffset = _scrollOffset.clamp(-oldHeight * 0.25, 0.0).toDouble();
        return;
      }
      _scrollOffset += oldHeight;
      window = widget.runtime.state.pageWindow;
      if (window == null) return;
    }

    while (true) {
      final currentWindow = window;
      if (currentWindow == null || _scrollOffset <= 0) {
        break;
      }
      final prev = currentWindow.prev;
      if (prev == null) {
        _scrollOffset = 0;
        return;
      }
      final moved = _runViewportPageShift(widget.runtime.moveToPrevTile);
      if (!moved) {
        _scrollOffset = 0;
        return;
      }
      _scrollOffset -= prev.height;
      window = widget.runtime.state.pageWindow;
      if (window == null) return;
    }
  }

  void _maybePrefetch(double delta) {
    if (delta < 0) {
      unawaited(widget.runtime.prefetchForward());
    } else if (delta > 0) {
      unawaited(widget.runtime.prefetchBackward());
    }
  }

  bool _runViewportPageShift(bool Function() action) {
    _suppressExternalPageReset = true;
    try {
      final moved = action();
      if (moved) {
        _lastCurrentPageKey = _pageKey(
          widget.runtime.state.pageWindow?.current,
        );
      }
      return moved;
    } finally {
      _suppressExternalPageReset = false;
    }
  }

  String? _pageKey(TextPage? page) {
    if (page == null) return null;
    return '${page.chapterIndex}:${page.pageIndex}';
  }

  TileKey _tileKey(TextPage tile) {
    return TileKey(
      chapterIndex: tile.chapterIndex,
      tileIndex: tile.pageIndex,
      startOffset: tile.startCharOffset,
      endOffset: tile.endCharOffset,
      layoutRevision: widget.runtime.state.layoutGeneration,
    );
  }

  void _startFling(double velocity) {
    if (velocity.abs() < 80) {
      _commitVisibleLocation();
      return;
    }
    _lastFlingPosition = 0;
    _flingController.value = 0;
    unawaited(
      _flingController.animateWith(
        ClampingScrollSimulation(
          position: 0,
          velocity: velocity,
          friction: 0.018,
        ),
      ),
    );
  }

  void _commitVisibleLocation() {
    if (!mounted) return;
    final height = context.size?.height ?? 0;
    if (height <= 0) return;
    final location = widget.runtime.resolveVisibleLocation(
      pageOffset: _scrollOffset,
      viewportHeight: height,
    );
    widget.runtime.updateVisibleLocation(location);
  }

  Widget _buildTile(TextPage tile) {
    return ReaderTileLayer(
      tile: tile,
      tileKey: _tileKey(tile),
      style: widget.style,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final window = state.pageWindow;
    if (state.phase != ReaderPhase.ready || window == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onTapUp,
        child: ColoredBox(
          color: widget.backgroundColor,
          child: Center(
            child:
                state.phase == ReaderPhase.error
                    ? Text(
                      state.errorMessage ?? 'Reader error',
                      style: TextStyle(color: widget.textColor),
                    )
                    : CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.textColor.withValues(alpha: 0.35),
                    ),
          ),
        ),
      );
    }

    final prevTile = window.prev == null ? null : _buildTile(window.prev!);
    final currentTile = _buildTile(window.current);
    final nextTile = window.next == null ? null : _buildTile(window.next!);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      onVerticalDragStart: (_) {
        _flingController.stop();
      },
      onVerticalDragUpdate: (details) {
        _applyDelta(details.delta.dy);
      },
      onVerticalDragEnd: (details) {
        _startFling(details.primaryVelocity ?? 0);
      },
      onVerticalDragCancel: _commitVisibleLocation,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (prevTile != null)
                AnimatedBuilder(
                  animation: _offset,
                  child: prevTile,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        _offset.value - (window.prev?.height ?? 0),
                      ),
                      child: child,
                    );
                  },
                ),
              AnimatedBuilder(
                animation: _offset,
                child: currentTile,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _offset.value),
                    child: child,
                  );
                },
              ),
              if (nextTile != null)
                AnimatedBuilder(
                  animation: _offset,
                  child: nextTile,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _offset.value + window.current.height),
                      child: child,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
