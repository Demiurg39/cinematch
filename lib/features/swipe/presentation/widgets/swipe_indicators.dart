import 'package:flutter/material.dart';

class SwipeIndicators extends StatelessWidget {
  const SwipeIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Icon(Icons.thumb_down, color: Colors.red, size: 24),
              SizedBox(height: 4),
              Text('Dislike', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Icon(Icons.schedule, color: Colors.blue, size: 24),
              SizedBox(height: 4),
              Text('Maybe', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Icon(Icons.block, color: Colors.orange, size: 24),
              SizedBox(height: 4),
              Text('Veto', style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Icon(Icons.thumb_up, color: Colors.green, size: 24),
              SizedBox(height: 4),
              Text('Like', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
