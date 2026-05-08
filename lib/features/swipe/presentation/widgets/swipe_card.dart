import 'package:flutter/material.dart';
import 'dart:math' as math;

enum SwipeDirection { left, right, up, down }

class SwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double threshold;

  const SwipeCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.threshold = 100,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragPosition = Offset.zero;
  Offset _dragVelocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SwipeDirection? _getSwipeDirection() {
    final dx = _dragPosition.dx.abs();
    final dy = _dragPosition.dy.abs();

    if (dx < 30 && dy < 30) return null;

    if (dx > dy) {
      return _dragPosition.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      return _dragPosition.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }
  }

  Color _getOverlayColor() {
    final direction = _getSwipeDirection();
    switch (direction) {
      case SwipeDirection.right:
        return Colors.green.withOpacity(math.min(_dragPosition.dx / 300, 0.8));
      case SwipeDirection.left:
        return Colors.red.withOpacity(math.min(_dragPosition.dx.abs() / 300, 0.8));
      case SwipeDirection.up:
        return Colors.orange.withOpacity(math.min(_dragPosition.dy.abs() / 300, 0.8));
      case SwipeDirection.down:
        return Colors.blue.withOpacity(math.min(_dragPosition.dy / 300, 0.8));
      default:
        return Colors.transparent;
    }
  }

  IconData? _getOverlayIcon() {
    final direction = _getSwipeDirection();
    switch (direction) {
      case SwipeDirection.right:
        return Icons.thumb_up;
      case SwipeDirection.left:
        return Icons.thumb_down;
      case SwipeDirection.up:
        return Icons.block;
      case SwipeDirection.down:
        return Icons.schedule;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => _controller.stop(),
      onPanUpdate: (details) {
        setState(() {
          _dragPosition += details.delta;
        });
      },
      onPanEnd: (details) {
        _dragVelocity = details.velocity.pixelsPerSecond;

        final direction = _getSwipeDirection();
        if (direction != null) {
          final distance = direction == SwipeDirection.right || direction == SwipeDirection.left
              ? _dragPosition.dx.abs()
              : _dragPosition.dy.abs();

          if (distance > widget.threshold || _dragVelocity.distance > 500) {
            switch (direction) {
              case SwipeDirection.right:
                widget.onSwipeRight?.call();
                break;
              case SwipeDirection.left:
                widget.onSwipeLeft?.call();
                break;
              case SwipeDirection.up:
                widget.onSwipeUp?.call();
                break;
              case SwipeDirection.down:
                widget.onSwipeDown?.call();
                break;
            }
          }
        }

        setState(() {
          _dragPosition = Offset.zero;
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_dragPosition.dx, _dragPosition.dy)
          ..rotateZ(_dragPosition.dx / 500),
        alignment: Alignment.center,
        child: Stack(
          children: [
            widget.child,
            if (_getSwipeDirection() != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: _getOverlayColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _getOverlayIcon(),
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
