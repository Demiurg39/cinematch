import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/swipe_provider.dart';
import 'providers/genre_filter_provider.dart';
import 'widgets/swipe_card.dart';
import 'widgets/swipe_indicators.dart';
import 'widgets/movie_card_content.dart';
import 'widgets/match_celebration.dart';
import 'widgets/genre_filter_sheet.dart';
import '../../movies/domain/movie_model.dart';
import '../../movies/presentation/movie_detail_screen.dart';
import '../../swipe/domain/swipe_action.dart';
import '../../../core/theme/app_theme.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final genreFilter = ref.watch(genreFilterNotifierProvider);
    final selectedGenres = genreFilter['selectedGenres'] as List<int>;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Shared header with logo and filter
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CINEMATCH',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showGenreFilterSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedGenres.isNotEmpty
                              ? AppColors.primaryPink
                              : AppColors.textMuted.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 16,
                            color: selectedGenres.isNotEmpty
                                ? AppColors.primaryPink
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            selectedGenres.isEmpty
                                ? 'Filter'
                                : '${selectedGenres.length} selected',
                            style: TextStyle(
                              color: selectedGenres.isNotEmpty
                                  ? AppColors.primaryPink
                                  : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  tabs: const [
                    Tab(text: 'Personalized'),
                    Tab(text: 'Popular'),
                  ],
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PersonalizedTab(),
                  _PopularTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalizedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(swipeDeckNotifierProvider);

    if (deckState.isLoading) return const _LoadingState();
    if (deckState.movies.isEmpty) return const _EmptyState();

    // Pre-cache poster images for smoother card transitions
    for (final movie in deckState.movies) {
      if (movie.posterUrl != null) {
        precacheImage(NetworkImage(movie.posterUrl!), context);
      }
    }

    return _SwipeDeck(
      movies: deckState.movies,
      mlRecommendedTmdbIds: deckState.mlRecommendedTmdbIds,
      onSwipe: (action, movie) {
        if (action == SwipeAction.like) {
          showMatchCelebration(context, movie);
        }
        ref.read(swipeDeckNotifierProvider.notifier).onSwipe(action, movie);
      },
    );
  }
}

class _PopularTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(popularDeckNotifierProvider);

    if (deckState.isLoading) return const _LoadingState();
    if (deckState.movies.isEmpty) return const _EmptyState();

    // Pre-cache poster images for smoother card transitions
    for (final movie in deckState.movies) {
      if (movie.posterUrl != null) {
        precacheImage(NetworkImage(movie.posterUrl!), context);
      }
    }

    return _SwipeDeck(
      movies: deckState.movies,
      mlRecommendedTmdbIds: deckState.mlRecommendedTmdbIds,
      onSwipe: (action, movie) {
        if (action == SwipeAction.like) {
          showMatchCelebration(context, movie);
        }
        ref.read(popularDeckNotifierProvider.notifier).onSwipe(action, movie);
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      child: Column(
        children: [
          _ShimmerCard(),
          const SizedBox(height: 24),
          _ShimmerCard(),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 + 2 * _shimmerController.value, 0),
                end: Alignment(-0.5 + 2 * _shimmerController.value, 0),
                colors: const [
                  AppColors.surfaceDark,
                  Color(0xFF2A2A3E),
                  AppColors.surfaceDark,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            child: Container(
              width: double.infinity,
              height: size.height * 0.55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
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

class _SwipeDeck extends StatelessWidget {
  final List<MovieModel> movies;
  final Set<int> mlRecommendedTmdbIds;
  final void Function(SwipeAction action, MovieModel movie) onSwipe;

  const _SwipeDeck({
    required this.movies,
    required this.mlRecommendedTmdbIds,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (movies.length > 1)
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.60,
                    child: Transform.scale(
                      scale: 0.94,
                      child: Opacity(
                        opacity: 0.5,
                        child: GestureDetector(
                          onTap: () => _openDetail(context, movies[1]),
                          child: MovieCardContent(
                            movie: movies[1],
                            showDetails: false,
                            isMlRecommendation: mlRecommendedTmdbIds.contains(movies[1].tmdbId),
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.60,
                  child: GestureDetector(
                    onTap: () => _openDetail(context, movies[0]),
                    child: SwipeCard(
                      onSwipeRight: () => _handleSwipe(movies[0], SwipeAction.like),
                      onSwipeLeft: () => _handleSwipe(movies[0], SwipeAction.dislike),
                      onSwipeUp: () => _handleSwipe(movies[0], SwipeAction.veto),
                      onSwipeDown: () => _handleSwipe(movies[0], SwipeAction.maybe),
                      child: MovieCardContent(
                        movie: movies[0],
                        isMlRecommendation: mlRecommendedTmdbIds.contains(movies[0].tmdbId),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SwipeIndicators(
            onDislike: movies.isEmpty ? null : () => _handleSwipe(movies[0], SwipeAction.dislike),
            onMaybe: movies.isEmpty ? null : () => _handleSwipe(movies[0], SwipeAction.maybe),
            onVeto: movies.isEmpty ? null : () => _handleSwipe(movies[0], SwipeAction.veto),
            onLike: movies.isEmpty ? null : () => _handleSwipe(movies[0], SwipeAction.like),
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, MovieModel movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  void _handleSwipe(MovieModel movie, SwipeAction action) {
    onSwipe(action, movie);
  }
}