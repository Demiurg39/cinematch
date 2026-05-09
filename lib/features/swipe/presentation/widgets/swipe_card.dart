import 'package:flutter/material.dart';

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
    this.threshold = 80,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _overlayController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _overlayAnimation;
  Offset _dragPosition = Offset.zero;
  bool _isAnimating = false;
  SwipeDirection? _currentDirection;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _overlayAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _runResetAnimation() {
    final startOffset = _dragPosition;
    final startRotation = _dragPosition.dx / 500;

    _offsetAnimation = Tween<Offset>(begin: startOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _rotationAnimation = Tween<double>(begin: startRotation, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _overlayAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );

    _isAnimating = true;
    _currentDirection = null;
    _animController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _dragPosition = Offset.zero;
        });
      }
    });
    _overlayController.forward(from: 0);
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

  Color _getColorForDirection(SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.right:
        return Colors.green.withValues(alpha: 0.75);
      case SwipeDirection.left:
        return Colors.red.withValues(alpha: 0.75);
      case SwipeDirection.up:
        return Colors.orange.withValues(alpha: 0.75);
      case SwipeDirection.down:
        return Colors.blue.withValues(alpha: 0.75);
      default:
        return Colors.transparent;
    }
  }

  IconData? _getIconForDirection(SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.right:
        return Icons.thumb_up;
      case SwipeDirection.left:
        return Icons.thumb_down;
      case SwipeDirection.up:
        return Icons.block;
      case SwipeDirection.down:
        return Icons.schedule;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {
        if (_isAnimating) {
          _animController.stop();
          _overlayController.stop();
        }
      },
      onPanUpdate: (details) {
        setState(() {
          _dragPosition += details.delta;
        });
      },
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        final direction = _getSwipeDirection();

        if (direction != null) {
          final distance = direction == SwipeDirection.right || direction == SwipeDirection.left
              ? _dragPosition.dx.abs()
              : _dragPosition.dy.abs();

          if (distance > widget.threshold || velocity.distance > 800) {
            _currentDirection = direction;
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
            setState(() {
              _dragPosition = Offset.zero;
              _currentDirection = null;
            });
            return;
          }
        }

        _runResetAnimation();
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final offset = _isAnimating ? _offsetAnimation.value : _dragPosition;
          final rotation = _isAnimating ? _rotationAnimation.value : _dragPosition.dx / 500;

          return Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(offset.dx, offset.dy, 0)
              ..rotateZ(rotation),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Stack(
          children: [
            widget.child,
            if (_currentDirection != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _overlayController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _overlayAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorForDirection(_currentDirection),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForDirection(_currentDirection),
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}