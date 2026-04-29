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
    if (!gesturesEnabled) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: onTapUp,
      onLongPress: () {},
      child: child,
    );
  }
}
