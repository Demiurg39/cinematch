import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  Offset _dragPosition = Offset.zero;
  bool _isAnimating = false;
  SwipeDirection? _currentDirection;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _runResetAnimation() {
    _animController.reset();

    final startOffset = _dragPosition;
    final startRotation = _dragPosition.dx / 1500;

    final offsetAnim = _animController.drive(
      Tween(begin: startOffset, end: Offset.zero).chain(CurveTween(curve: Curves.elasticOut)),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _dragPosition = offsetAnim.value;
      });
    }

    _animController.addListener(listener);

    void onComplete(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      _animController.removeListener(listener);
      _animController.removeStatusListener(onComplete);
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _dragPosition = Offset.zero;
        });
      }
    }

    _animController.addStatusListener(onComplete);

    _isAnimating = true;
    _currentDirection = null;
    _overlayController.reset();
    _overlayController.forward();

    _animController.forward();
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
        return Colors.green;
      case SwipeDirection.left:
        return Colors.red;
      case SwipeDirection.up:
        return Colors.orange;
      case SwipeDirection.down:
        return Colors.blue;
      default:
        return Colors.grey;
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

  double _getAmbientIntensity() {
    final dx = _dragPosition.dx.abs();
    final dy = _dragPosition.dy.abs();
    final maxDist = MediaQuery.of(context).size.width * 0.4;
    return (dx > dy ? dx : dy / 2).clamp(0.0, maxDist) / maxDist;
  }

  Alignment _getAmbientGradientBegin() {
    if (_dragPosition.dx > 10) return Alignment.centerRight;
    if (_dragPosition.dx < -10) return Alignment.centerLeft;
    if (_dragPosition.dy < -10) return Alignment.topCenter;
    if (_dragPosition.dy > 10) return Alignment.bottomCenter;
    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    // Rotation pivots from bottom - top part leans
    final rotation = _dragPosition.dx / 1500;
    final scale = 1.0 + (_dragPosition.distance / 4000).clamp(0.0, 0.02);
    final ambientIntensity = _getAmbientIntensity();

    return GestureDetector(
      onPanStart: (_) {
        if (_isAnimating) {
          _animController.stop();
        }
      },
      onPanUpdate: (details) {
        setState(() {
          _dragPosition += details.delta;
        });
        HapticFeedback.selectionClick();
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
            HapticFeedback.mediumImpact();

            final callback = () {
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
            };

            _runExitAnimation(direction, callback);
            return;
          }
        }

        _runResetAnimation();
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setTranslationRaw(_dragPosition.dx, _dragPosition.dy, 0)
          ..rotateZ(rotation)
          ..scale(scale),
        alignment: Alignment.bottomCenter, // Pivot from bottom
        child: Stack(
          children: [
            widget.child,
            if (ambientIntensity > 0.05)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: _getAmbientGradientBegin(),
                        end: Alignment.center,
                        colors: [
                          _getColorForDirection(_getSwipeDirection()).withValues(alpha: ambientIntensity * 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentDirection != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _overlayController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _overlayController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorForDirection(_currentDirection).withValues(alpha: 0.4),
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

  void _runExitAnimation(SwipeDirection direction, VoidCallback callback) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Offset endOffset;
    switch (direction) {
      case SwipeDirection.left:
        endOffset = Offset(-screenWidth * 1.5, 0);
        break;
      case SwipeDirection.right:
        endOffset = Offset(screenWidth * 1.5, 0);
        break;
      case SwipeDirection.up:
        endOffset = Offset(0, -screenHeight * 1.5);
        break;
      case SwipeDirection.down:
        endOffset = Offset(0, screenHeight * 1.5);
        break;
    }

    final startOffset = _dragPosition;

    _overlayController.forward(from: 0);

    final anim = _animController.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _dragPosition = Offset.lerp(startOffset, endOffset, anim.value)!;
      });
    }

    _animController.addListener(listener);

    void onComplete(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      _animController.removeListener(listener);
      _animController.removeStatusListener(onComplete);
      callback();
      if (mounted) {
        setState(() {
          _dragPosition = Offset.zero;
          _currentDirection = null;
        });
        _animController.reset();
      }
    }

    _animController.addStatusListener(onComplete);
    _animController.forward(from: 0);
  }
}