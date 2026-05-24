import 'package:flutter/material.dart';
import '../../domain/room_match_model.dart';

class UnanimousMatchOverlay extends StatelessWidget {
  final RoomMatch match;
  final VoidCallback onContinue;
  final VoidCallback onReview;

  const UnanimousMatchOverlay({
    super.key,
    required this.match,
    required this.onContinue,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text('Instant Match!', style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (match.posterUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(match.posterUrl!, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(match.title, style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white)),
              const SizedBox(height: 8),
              Text('Everyone liked this movie!', style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70)),
              const SizedBox(height: 32),
              FilledButton(onPressed: onContinue, child: const Text('Keep Swiping')),
              const SizedBox(height: 12),
              TextButton(onPressed: onReview, child: const Text('Review All Matches')),
            ],
          ),
        ),
      ),
    );
  }
}
