import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/shared_matches_provider.dart';

class SharedPoolReviewScreen extends ConsumerStatefulWidget {
  final String roomId;

  const SharedPoolReviewScreen({super.key, required this.roomId});

  @override
  ConsumerState<SharedPoolReviewScreen> createState() => _SharedPoolReviewScreenState();
}

class _SharedPoolReviewScreenState extends ConsumerState<SharedPoolReviewScreen>
    with TickerProviderStateMixin {
  final Set<String> _upvoted = {};
  final Set<String> _downvoted = {};
  final Set<String> _selected = {};
  List<Map<String, dynamic>> _movies = [];
  bool _loadingMovies = true;

  // Roulette
  bool _spinning = false;
  int _rouletteIndex = 0;
  AnimationController? _spinController;
  Animation<double>? _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _spinAnimation = CurvedAnimation(parent: _spinController!, curve: Curves.easeOutCubic);
    _spinController!.addListener(() {
      if (_movies.isEmpty) return;
      final progress = _spinAnimation!.value;
      final idx = (progress * _movies.length * 3).round() % _movies.length;
      if (idx != _rouletteIndex) {
        setState(() => _rouletteIndex = idx);
      }
    });
  }

  @override
  void dispose() {
    _spinController?.dispose();
    super.dispose();
  }

  void _startRoulette() {
    if (_movies.isEmpty || _spinning) return;
    setState(() {
      _spinning = true;
      _selected.clear();
    });
    _spinController!.forward(from: 0).then((_) {
      if (!mounted) return;
      // Pick the final winner
      final winner = _movies[_rouletteIndex];
      setState(() {
        _selected.add(winner['id'] as String);
        _spinning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchesAsync = ref.watch(sharedMatchesNotifierProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Matches'),
        actions: [
          if (_movies.length >= 2)
            IconButton(
              icon: const Icon(Icons.casino),
              tooltip: 'Movie Roulette',
              onPressed: _startRoulette,
            ),
        ],
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (movieIds) {
          if (movieIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No shared matches yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Swipe more to find common ground', style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }

          if (_loadingMovies) {
            _fetchMovies(movieIds.toList());
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Roulette winner banner
              if (_selected.isNotEmpty)
                _RouletteWinnerCard(
                  movie: _movies.firstWhere((m) => _selected.contains(m['id'])),
                  onViewDetails: () => _openMovieDetail(_movies.firstWhere((m) => _selected.contains(m['id']))),
                  onDismiss: () => setState(() => _selected.clear()),
                ),

              // Roulette highlight during spin
              if (_spinning && _movies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.casino, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _movies[_rouletteIndex]['title'] as String? ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Vote summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('${_movies.length} movies', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text('${_upvoted.length} interested', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Text('${_downvoted.length} skip', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),

              // Movie grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.67,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    final movieId = movie['id'] as String;
                    final isUpvoted = _upvoted.contains(movieId);
                    final isDownvoted = _downvoted.contains(movieId);
                    final isWinner = _selected.contains(movieId);

                    return _MovieVoteCard(
                      movie: movie,
                      isUpvoted: isUpvoted,
                      isDownvoted: isDownvoted,
                      isWinner: isWinner,
                      isSpinning: _spinning && index == _rouletteIndex,
                      onTap: () => _openMovieDetail(movie),
                      onUpvote: () {
                        setState(() {
                          _upvoted.add(movieId);
                          _downvoted.remove(movieId);
                        });
                      },
                      onDownvote: () {
                        setState(() {
                          _downvoted.add(movieId);
                          _upvoted.remove(movieId);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _fetchMovies(List<String> movieIds) async {
    if (movieIds.isEmpty) return;
    final client = Supabase.instance.client;
    final movies = await client.from('movies').select('id, tmdb_id, title, poster_url').inFilter('id', movieIds);
    if (mounted) {
      setState(() {
        _movies = movies;
        _loadingMovies = false;
      });
    }
  }

  void _openMovieDetail(Map<String, dynamic> movie) {
    // We don't have a full MovieModel here, navigate with tmdb_id
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(movie['title'] as String? ?? '')),
          body: Center(child: Text('Movie ID: ${movie['tmdb_id']}')),
        ),
      ),
    );
  }
}

// ============================================================================
// Roulette Winner Banner
// ============================================================================

class _RouletteWinnerCard extends StatelessWidget {
  final Map<String, dynamic> movie;
  final VoidCallback onViewDetails;
  final VoidCallback onDismiss;

  const _RouletteWinnerCard({
    required this.movie,
    required this.onViewDetails,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.casino, size: 20, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Roulette Pick!', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie['title'] as String? ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
                    onPressed: onViewDetails,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Movie Vote Card
// ============================================================================

class _MovieVoteCard extends StatelessWidget {
  final Map<String, dynamic> movie;
  final bool isUpvoted;
  final bool isDownvoted;
  final bool isWinner;
  final bool isSpinning;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  const _MovieVoteCard({
    required this.movie,
    required this.isUpvoted,
    required this.isDownvoted,
    required this.isWinner,
    required this.isSpinning,
    required this.onTap,
    required this.onUpvote,
    required this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (movie['poster_url'] != null)
                    Image.network(movie['poster_url'], fit: BoxFit.cover, width: double.infinity)
                  else
                    Container(color: theme.colorScheme.surfaceContainerHighest),
                  if (isWinner)
                    Positioned.fill(
                      child: Container(
                        color: Colors.green.withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                        ),
                      ),
                    ),
                  if (isSpinning)
                    Positioned.fill(
                      child: Container(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        child: const Center(
                          child: Icon(Icons.casino, size: 32),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              movie['title'] as String? ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Vote buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: isUpvoted ? Colors.green : null,
                  ),
                  onPressed: onUpvote,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(
                    isDownvoted ? Icons.thumb_down : Icons.thumb_down_outlined,
                    size: 18,
                    color: isDownvoted ? Colors.red : null,
                  ),
                  onPressed: onDownvote,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}