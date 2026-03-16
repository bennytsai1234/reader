import 'package:flutter/material.dart';

/// CoverPageView - 覆蓋翻頁效果
/// 當前頁向左滑出，露出底下的下一頁
class CoverPageView extends StatefulWidget {
  final Widget currentChild;
  final Widget? nextChild;
  final VoidCallback onTurnNext;
  final VoidCallback onTurnPrev;

  const CoverPageView({
    super.key,
    required this.currentChild,
    this.nextChild,
    required this.onTurnNext,
    required this.onTurnPrev,
  });

  @override
  State<CoverPageView> createState() => _CoverPageViewState();
}

class _CoverPageViewState extends State<CoverPageView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final width = MediaQuery.of(context).size.width;
    
    if (_dragOffset < -width * 0.15) {
      // 向左滑動超過 15%，觸發翻頁
      _controller.forward(from: (-_dragOffset / width)).then((_) {
        widget.onTurnNext();
        setState(() => _dragOffset = 0);
      });
    } else if (_dragOffset > width * 0.25) {
      // 向右滑動超過 25%，翻回上一頁
      widget.onTurnPrev();
      setState(() => _dragOffset = 0);
    } else {
      // 否則彈回原位
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 底層：下一頁內容 (靜止不動)
          if (widget.nextChild != null)
            widget.nextChild!,

          // 上層：當前頁內容 (跟隨手指滑動)
          Transform.translate(
            offset: Offset(_dragOffset.clamp(-width, 0), 0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (_dragOffset < 0)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(5, 0),
                    ),
                ],
              ),
              child: widget.currentChild,
            ),
          ),
        ],
      ),
    );
  }
}

