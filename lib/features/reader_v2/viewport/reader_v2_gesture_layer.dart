import 'package:flutter/material.dart';

class ReaderV2GestureLayer extends StatelessWidget {
  const ReaderV2GestureLayer({
    super.key,
    required this.child,
    this.onTapUp,
    this.gesturesEnabled = true,
  });

  final Widget child;
  final GestureTapUpCallback? onTapUp;
  final bool gesturesEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: gesturesEnabled ? onTapUp : null,
      onLongPress: gesturesEnabled ? () {} : null,
      child: child,
    );
  }
}
