import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/swipe_provider.dart';
import 'widgets/swipe_card.dart';
import 'widgets/swipe_indicators.dart';
import 'widgets/movie_card_content.dart';
import '../../movies/domain/movie_model.dart';
import '../../swipe/domain/swipe_action.dart';
import '../../../core/theme/app_theme.dart';

class SwipeScreen extends ConsumerWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(swipeDeckNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: deckAsync.when(
          loading: () => const _LoadingState(),
          error: (e, _) => _ErrorState(message: e.toString()),
          data: (movies) => movies.isEmpty
              ? const _EmptyState()
              : _SwipeDeck(movies: movies),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading movies...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.2),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Check back later for more movie suggestions',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeck extends ConsumerWidget {
  final List<MovieModel> movies;
  const _SwipeDeck({required this.movies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'CINEMATCH',
                      style: TextStyle(
                        color: AppColors.primaryPink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${movies.length} left',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Card stack
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background card (next in deck)
                if (movies.length > 1)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Transform.scale(
                      scale: 0.94,
                      child: Opacity(
                        opacity: 0.6,
                        child: MovieCardContent(
                          movie: movies[1],
                          showDetails: false,
                        ),
                      ),
                    ),
                  ),

                // Top card (swipeable)
                Positioned.fill(
                  child: SwipeCard(
                    onSwipeRight: () => _onSwipe(ref, movies[0], SwipeAction.like),
                    onSwipeLeft: () => _onSwipe(ref, movies[0], SwipeAction.dislike),
                    onSwipeUp: () => _onSwipe(ref, movies[0], SwipeAction.veto),
                    onSwipeDown: () => _onSwipe(ref, movies[0], SwipeAction.maybe),
                    child: MovieCardContent(movie: movies[0]),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Swipe indicators
        const Padding(
          padding: EdgeInsets.only(bottom: 32),
          child: SwipeIndicators(),
        ),
      ],
    );
  }

  void _onSwipe(WidgetRef ref, MovieModel movie, SwipeAction action) {
    ref.read(swipeDeckNotifierProvider.notifier).onSwipe(action, movie);
  }
}
