import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/swipe_card.dart';
import 'widgets/swipe_indicators.dart';
import 'widgets/movie_card_content.dart';
import 'providers/swipe_provider.dart';
import '../../partners/presentation/providers/active_partner_provider.dart';
import '../domain/swipe_action.dart';

class PartnerSwipeScreen extends ConsumerWidget {
  const PartnerSwipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(swipeDeckNotifierProvider);
    final partnerAsync = ref.watch(activePartnerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Mode'),
        actions: [
          partnerAsync.whenOrNull(
            data: (partner) => partner != null
                ? Chip(
                    avatar: const Icon(Icons.link, size: 16),
                    label: Text(partner.partnerUsername),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: deckState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : deckState.movies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No more movies!', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                )
              : _PartnerSwipeDeck(movies: deckState.movies),
    );
  }
}

class _PartnerSwipeDeck extends ConsumerWidget {
  final List movies;
  const _PartnerSwipeDeck({required this.movies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  }

  void _onSwipe(WidgetRef ref, movie, SwipeAction action) {
    ref.read(swipeDeckNotifierProvider.notifier).onSwipe(action, movie);
  }
}
