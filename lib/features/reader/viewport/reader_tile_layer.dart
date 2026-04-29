import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';

import 'reader_tile_painter.dart';

class ReaderTileLayer extends StatelessWidget {
  const ReaderTileLayer({
    super.key,
    required this.tile,
    required this.style,
    required this.backgroundColor,
    required this.textColor,
    required this.tileKey,
    this.expand = false,
    this.debugOverlay = false,
    this.enableJustification = true,
    this.paintBackground = true,
  });

  final PageCache tile;
  final ReadStyle style;
  final Color backgroundColor;
  final Color textColor;
  final TileKey tileKey;
  final bool expand;
  final bool debugOverlay;
  final bool enableJustification;
  final bool paintBackground;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      painter: ReaderTilePainter(
        tile: tile,
        style: style,
        backgroundColor: backgroundColor,
        textColor: textColor,
        debugOverlay: debugOverlay,
        enableJustification: enableJustification,
        paintBackground: paintBackground,
      ),
    );

    return RepaintBoundary(
      key: ValueKey<TileKey>(tileKey),
      child:
          expand
              ? SizedBox.expand(child: paint)
              : SizedBox(
                width: double.infinity,
                height: tile.height,
                child: paint,
              ),
    );
  }
}
