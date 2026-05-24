import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';
import 'package:cinematch/core/theme/app_theme.dart';
import 'providers/movies_provider.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final MovieModel movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  String? _trailerKey;
  bool _showTrailer = false;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _prefetchTrailer();
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  Future<void> _prefetchTrailer() async {
    final repo = ref.read(moviesRepositoryProvider);
    final key = await repo.getMovieTrailerKey(widget.movie.tmdbId);
    if (mounted) {
      setState(() => _trailerKey = key);
    }
  }

  Future<void> _playTrailer() async {
    if (_trailerKey == null || _trailerKey!.isEmpty) return;
    try {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: _trailerKey!,
        autoPlay: true,
        params: const YoutubePlayerParams(
          mute: false,
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      setState(() => _showTrailer = true);
    } catch (_) {
      // WebView not available — open in external browser
      final uri = Uri.parse('https://www.youtube.com/watch?v=$_trailerKey');
      if (mounted) await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchProvidersAsync = ref.watch(watchProvidersNotifierProvider(widget.movie.tmdbId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Hero poster with trailer support
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.surfaceDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Poster or Trailer
                  if (_showTrailer && _youtubeController != null)
                    YoutubePlayer(
                      controller: _youtubeController!,
                      aspectRatio: 16 / 9,
                    )
                  else ...[
                    // Poster
                    if (widget.movie.posterUrl != null)
                      Image.network(
                        widget.movie.posterUrl!.replaceAll('/w500/', '/w1280/'),
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: AppColors.cardDark,
                        child: const Icon(
                          Icons.movie,
                          size: 100,
                          color: Colors.white54,
                        ),
                      ),

                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.backgroundDark.withValues(alpha: 0.5),
                              AppColors.backgroundDark,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Close button when trailer playing
                  if (_showTrailer)
                    Positioned(
                      top: 48,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          _youtubeController?.pauseVideo();
                          setState(() => _showTrailer = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  // Play button when poster shown and trailer available
                  if (!_showTrailer && _trailerKey != null && _trailerKey!.isNotEmpty)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _playTrailer,
                        child: Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.primaryPink,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (widget.movie.year != null)
                        _MetaChip(
                          icon: Icons.calendar_today,
                          label: '${widget.movie.year}',
                        ),
                      if (widget.movie.runtime != null)
                        _MetaChip(
                          icon: Icons.schedule,
                          label: '${widget.movie.runtime} min',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Genres
                  if (widget.movie.genres.isNotEmpty) ...[
                    const Text(
                      'Genres',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.movie.genres.take(5).map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  if (widget.movie.overview != null && widget.movie.overview!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primaryPink,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'About',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.movie.overview!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Where to watch
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: AppColors.primaryPink,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Where to Watch',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        watchProvidersAsync.when(
                          loading: () => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, __) => const Text(
                            'Streaming info unavailable',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          data: (providers) {
                            if (providers == null) {
                              return const Text(
                                'No streaming info available for your region',
                                style: TextStyle(color: AppColors.textMuted),
                              );
                            }
                            final results = providers['results'] as Map<String, dynamic>?;
                            if (results == null || results.isEmpty) {
                              return const Text(
                                'No streaming info available',
                                style: TextStyle(color: AppColors.textMuted),
                              );
                            }
                            // Get US providers or first available region
                            final usProviders = results['US'] as Map<String, dynamic>?;
                            final regionProviders = usProviders ?? results.values.first as Map<String, dynamic>?;
                            if (regionProviders == null) {
                              return const Text(
                                'No streaming info available',
                                style: TextStyle(color: AppColors.textMuted),
                              );
                            }
                            final flatrate = regionProviders['flatrate'] as List<dynamic>?;
                            final link = regionProviders['link'] as String?;
                            if (flatrate == null || flatrate.isEmpty) {
                              if (link != null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'No streaming options available',
                                      style: TextStyle(color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _launchUrl(link),
                                      icon: const Icon(Icons.open_in_new, size: 16),
                                      label: const Text('View on TMDB'),
                                    ),
                                  ],
                                );
                              }
                              return const Text(
                                'No streaming options available',
                                style: TextStyle(color: AppColors.textMuted),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: flatrate.map((provider) {
                                    final p = provider as Map<String, dynamic>;
                                    final logoPath = p['logo_path'] as String?;
                                    final name = p['provider_name'] as String? ?? 'Unknown';
                                    return GestureDetector(
                                      onTap: link != null ? () => _launchUrl(link) : null,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: AppColors.cardDark,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                'https://image.tmdb.org/t/p/w92$logoPath',
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(
                                                  Icons.tv,
                                                  color: AppColors.textMuted,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (link != null) ...[
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => _launchUrl(link),
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('View on TMDB'),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.thumb_down),
                          label: const Text('Not for me'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade300,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.thumb_up),
                          label: const Text('Like'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}