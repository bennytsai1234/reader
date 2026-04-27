import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';

import 'reader_tile_layer.dart';

class SlideReaderViewport extends StatefulWidget {
  const SlideReaderViewport({
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
  State<SlideReaderViewport> createState() => _SlideReaderViewportState();
}

class _SlideReaderViewportState extends State<SlideReaderViewport> {
  late PageController _controller;
  bool _recentering = false;
  late int _lastLayoutGeneration;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1);
    _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
    widget.runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didUpdateWidget(covariant SlideReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _resetController();
    } else if (oldWidget.style.pageMode != widget.style.pageMode) {
      _resetController();
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final layoutChanged =
        _lastLayoutGeneration != widget.runtime.state.layoutGeneration;
    if (layoutChanged) {
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _resetController();
    }
    setState(() {});
  }

  void _resetController() {
    _controller.dispose();
    _controller = PageController(initialPage: 1);
  }

  void _handlePageChanged(int index) {
    if (_recentering || index == 1) return;
    final forward = index > 1;
    _recentering = true;

    if (_controller.hasClients) {
      _controller.jumpToPage(1);
    }
    final moved =
        forward
            ? widget.runtime.moveToNextTile()
            : widget.runtime.moveToPrevTile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recentering = false;
      if (!moved && _controller.hasClients) {
        _controller.jumpToPage(1);
      }
    });
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

  Widget _buildTile(TextPage tile) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: ReaderTileLayer(
        tile: tile,
        tileKey: _tileKey(tile),
        style: widget.style,
        backgroundColor: widget.backgroundColor,
        textColor: widget.textColor,
        expand: true,
      ),
    );
  }

  Widget _buildEdgePlaceholder({required String message}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: widget.textColor.withValues(alpha: 0.7),
              fontSize: widget.style.fontSize,
            ),
          ),
        ),
      ),
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.textColor.withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }

    final pages = <Widget>[
      window.prev == null
          ? _buildEdgePlaceholder(message: '已經是第一頁')
          : _buildTile(window.prev!),
      _buildTile(window.current),
      window.next == null
          ? _buildEdgePlaceholder(message: '已經是最後一頁')
          : _buildTile(window.next!),
    ];

    return PageView(
      controller: _controller,
      physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
      onPageChanged: _handlePageChanged,
      children: pages,
    );
  }
}
