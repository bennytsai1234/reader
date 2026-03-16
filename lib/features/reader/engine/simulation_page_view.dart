import 'package:flutter/material.dart';

/// SimulationPageView - 仿真翻頁視圖
/// 深度還原 Android ui/book/read/page/SimulationPageDelegate.kt
class SimulationPageView extends StatefulWidget {
  final Widget currentChild;
  final Widget? nextChild;
  final VoidCallback onTurnNext;
  final VoidCallback onTurnPrev;

  const SimulationPageView({
    super.key,
    required this.currentChild,
    this.nextChild,
    required this.onTurnNext,
    required this.onTurnPrev,
  });

  @override
  State<SimulationPageView> createState() => _SimulationPageViewState();
}

class _SimulationPageViewState extends State<SimulationPageView> with SingleTickerProviderStateMixin {
  Offset? _dragPoint;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPoint = details.localPosition;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final size = MediaQuery.of(context).size;
    if (_dragPoint == null) return;

    if (_dragPoint!.dx < size.width * 0.5) {
      // 完成翻頁動畫
      _animationController.forward(from: _dragPoint!.dx / size.width).then((_) {
        widget.onTurnNext();
        setState(() => _dragPoint = null);
      });
    } else {
      // 取消翻頁，彈回
      _animationController.reverse(from: _dragPoint!.dx / size.width).then((_) {
        setState(() => _dragPoint = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // 底層：下一頁內容
          if (widget.nextChild != null) widget.nextChild!,
          
          // 上層：當前頁內容 + 捲曲遮罩
          ClipPath(
            clipper: _SimulationPageClipper(_dragPoint, _animationController.value),
            child: widget.currentChild,
          ),
          
          // 繪製捲曲邊緣與陰影
          CustomPaint(
            size: Size.infinite,
            painter: _SimulationPagePainter(_dragPoint, _animationController.value),
          ),
        ],
      ),
    );
  }
}

/// 仿真翻頁剪裁器 (原 Android 貝茲路徑)
class _SimulationPageClipper extends CustomClipper<Path> {
  final Offset? dragPoint;
  final double animValue;

  _SimulationPageClipper(this.dragPoint, this.animValue);

  @override
  Path getClip(Size size) {
    final path = Path();
    if (dragPoint == null) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // 簡化版的仿真剪裁：根據拖拽點劃分顯示區域
    final x = dragPoint!.dx;
    path.lineTo(x, 0);
    path.lineTo(x, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SimulationPageClipper oldClipper) => true;
}

class _SimulationPagePainter extends CustomPainter {
  final Offset? dragPoint;
  final double animValue;

  _SimulationPagePainter(this.dragPoint, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (dragPoint == null) return;

    final x = dragPoint!.dx;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // 繪製翻頁陰影線 (原 Android SimulationPageAnim 陰影)
    final shadowPath = Path();
    shadowPath.moveTo(x, 0);
    shadowPath.lineTo(x + 20, 0);
    shadowPath.lineTo(x + 20, size.height);
    shadowPath.lineTo(x, size.height);
    shadowPath.close();
    canvas.drawPath(shadowPath, paint);

    // 繪製紙張背面光澤
    final edgePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(x - 10, 0, 10, size.height));
    
    canvas.drawRect(Rect.fromLTWH(x - 10, 0, 10, size.height), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _SimulationPagePainter oldDelegate) => true;
}

