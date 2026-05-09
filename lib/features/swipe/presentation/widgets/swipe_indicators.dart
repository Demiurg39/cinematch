import 'package:flutter/material.dart';

class SwipeIndicators extends StatelessWidget {
  const SwipeIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IndicatorItem(
            icon: Icons.thumb_down_rounded,
            label: 'Dislike',
            color: Colors.red.shade400,
            onTap: () {},
          ),
          _IndicatorItem(
            icon: Icons.schedule_rounded,
            label: 'Maybe',
            color: Colors.blue.shade400,
            onTap: () {},
          ),
          _IndicatorItem(
            icon: Icons.block_rounded,
            label: 'Veto',
            color: Colors.orange.shade400,
            onTap: () {},
          ),
          _IndicatorItem(
            icon: Icons.thumb_up_rounded,
            label: 'Like',
            color: Colors.green.shade400,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IndicatorItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _IndicatorItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
