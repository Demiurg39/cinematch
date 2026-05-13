import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeIndicators extends StatefulWidget {
  final VoidCallback? onDislike;
  final VoidCallback? onMaybe;
  final VoidCallback? onVeto;
  final VoidCallback? onLike;

  const SwipeIndicators({
    super.key,
    this.onDislike,
    this.onMaybe,
    this.onVeto,
    this.onLike,
  });

  @override
  State<SwipeIndicators> createState() => _SwipeIndicatorsState();
}

class _SwipeIndicatorsState extends State<SwipeIndicators> {
  _SwipeIndicator? _pressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IndicatorButton(
            icon: Icons.thumb_down_rounded,
            label: 'Dislike',
            color: Colors.red.shade400,
            isPressed: _pressed == _SwipeIndicator.dislike,
            onTap: widget.onDislike,
            onTapDown: () => setState(() => _pressed = _SwipeIndicator.dislike),
            onTapUp: () => setState(() => _pressed = null),
            onTapCancel: () => setState(() => _pressed = null),
          ),
          _IndicatorButton(
            icon: Icons.schedule_rounded,
            label: 'Maybe',
            color: Colors.blue.shade400,
            isPressed: _pressed == _SwipeIndicator.maybe,
            onTap: widget.onMaybe,
            onTapDown: () => setState(() => _pressed = _SwipeIndicator.maybe),
            onTapUp: () => setState(() => _pressed = null),
            onTapCancel: () => setState(() => _pressed = null),
          ),
          _IndicatorButton(
            icon: Icons.block_rounded,
            label: 'Veto',
            color: Colors.orange.shade400,
            isPressed: _pressed == _SwipeIndicator.veto,
            onTap: widget.onVeto,
            onTapDown: () => setState(() => _pressed = _SwipeIndicator.veto),
            onTapUp: () => setState(() => _pressed = null),
            onTapCancel: () => setState(() => _pressed = null),
          ),
          _IndicatorButton(
            icon: Icons.thumb_up_rounded,
            label: 'Like',
            color: Colors.green.shade400,
            isPressed: _pressed == _SwipeIndicator.like,
            onTap: widget.onLike,
            onTapDown: () => setState(() => _pressed = _SwipeIndicator.like),
            onTapUp: () => setState(() => _pressed = null),
            onTapCancel: () => setState(() => _pressed = null),
          ),
        ],
      ),
    );
  }
}

enum _SwipeIndicator { dislike, maybe, veto, like }

class _IndicatorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPressed;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;

  const _IndicatorButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isPressed,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isPressed ? 0.9 : 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isPressed ? 56 : 48,
              height: isPressed ? 56 : 48,
              decoration: BoxDecoration(
                color: isPressed ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPressed ? color : color.withValues(alpha: 0.5),
                  width: isPressed ? 3 : 2,
                ),
                boxShadow: isPressed
                    ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)]
                    : null,
              ),
              child: Icon(icon, color: color, size: isPressed ? 28 : 22),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                color: isPressed ? color : color.withValues(alpha: 0.8),
                fontSize: isPressed ? 12 : 11,
                fontWeight: isPressed ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}