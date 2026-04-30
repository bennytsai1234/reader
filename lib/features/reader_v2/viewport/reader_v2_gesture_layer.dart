import 'package:flutter/material.dart';

class ReaderV2GestureLayer extends StatefulWidget {
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
  State<ReaderV2GestureLayer> createState() => _ReaderV2GestureLayerState();
}

class _ReaderV2GestureLayerState extends State<ReaderV2GestureLayer> {
  static const double _tapSlop = 18.0;
  static const double _tapSlopSquared = _tapSlop * _tapSlop;

  int? _pointer;
  Offset? _downLocalPosition;
  bool _movedBeyondTapSlop = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.gesturesEnabled || widget.onTapUp == null) return;
    if (_pointer != null) {
      _resetTracking();
      return;
    }
    _pointer = event.pointer;
    _downLocalPosition = event.localPosition;
    _movedBeyondTapSlop = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _downLocalPosition == null) return;
    final delta = event.localPosition - _downLocalPosition!;
    if (delta.distanceSquared > _tapSlopSquared) {
      _movedBeyondTapSlop = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final shouldTap = !_movedBeyondTapSlop;
    _resetTracking();
    if (!shouldTap || !widget.gesturesEnabled) return;
    widget.onTapUp?.call(
      TapUpDetails(
        kind: event.kind,
        globalPosition: event.position,
        localPosition: event.localPosition,
      ),
    );
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) {
      _resetTracking();
    }
  }

  void _resetTracking() {
    _pointer = null;
    _downLocalPosition = null;
    _movedBeyondTapSlop = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.gesturesEnabled && widget.onTapUp != null;
    return Listener(
      behavior: enabled ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      onPointerDown: enabled ? _handlePointerDown : null,
      onPointerMove: enabled ? _handlePointerMove : null,
      onPointerUp: enabled ? _handlePointerUp : null,
      onPointerCancel: enabled ? _handlePointerCancel : null,
      child: widget.child,
    );
  }
}
