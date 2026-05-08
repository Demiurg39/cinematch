import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/swipe_provider.dart';
import 'widgets/swipe_card.dart';
import 'widgets/swipe_indicators.dart';
import 'widgets/movie_card_content.dart';
import '../../movies/domain/movie_model.dart';
import '../../swipe/domain/swipe_action.dart';

class SwipeScreen extends ConsumerWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(swipeDeckNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinematch'),
        centerTitle: true,
      ),
      body: deckAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No more movies!',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text('Check back later for more suggestions'),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (movies.length > 1)
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Transform.scale(
                            scale: 0.95,
                            child: MovieCardContent(
                              movie: movies[1],
                              showDetails: false,
                            ),
                          ),
                        ),
                      SwipeCard(
                        onSwipeRight: () => _onSwipe(ref, movies[0], SwipeAction.like),
                        onSwipeLeft: () => _onSwipe(ref, movies[0], SwipeAction.dislike),
                        onSwipeUp: () => _onSwipe(ref, movies[0], SwipeAction.veto),
                        onSwipeDown: () => _onSwipe(ref, movies[0], SwipeAction.maybe),
                        child: MovieCardContent(movie: movies[0]),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: SwipeIndicators(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSwipe(WidgetRef ref, MovieModel movie, SwipeAction action) {
    ref.read(swipeDeckNotifierProvider.notifier).onSwipe(action, movie);
  }
}
