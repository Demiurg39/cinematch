import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';
import 'package:cinematch/features/movies/presentation/providers/movies_provider.dart';
import 'package:cinematch/features/movies/presentation/movie_detail_screen.dart';
import 'package:cinematch/core/theme/app_theme.dart';

class MovieCardContent extends ConsumerStatefulWidget {
  final MovieModel movie;
  final bool showDetails;
  final bool isMlRecommendation;
  final bool partnerLiked;

  const MovieCardContent({
    super.key,
    required this.movie,
    this.showDetails = true,
    this.isMlRecommendation = false,
    this.partnerLiked = false,
  });

  @override
  ConsumerState<MovieCardContent> createState() => _MovieCardContentState();
}

class _MovieCardContentState extends ConsumerState<MovieCardContent> {
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

  Future<void> _onPosterTap(BuildContext context) async {
    if (_trailerKey != null && _trailerKey!.isNotEmpty) {
      try {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: _trailerKey!,
          autoPlay: true,
          params: const YoutubePlayerParams(
            mute: false,
            showControls: true,
            showFullscreenButton: false,
          ),
        );
        setState(() => _showTrailer = true);
      } catch (_) {
        // WebView not available — open in external browser
        final uri = Uri.parse('https://www.youtube.com/watch?v=$_trailerKey');
        if (mounted) await launchUrl(uri);
      }
    } else {
      // No trailer available — navigate to details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MovieDetailScreen(movie: widget.movie),
        ),
      );
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: widget.movie),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to List'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lists feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Watch Later'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Watch Later coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster or Trailer
              if (_showTrailer && _youtubeController != null)
                YoutubePlayer(
                  controller: _youtubeController!,
                  aspectRatio: 16 / 9,
                )
              else
                _buildPoster(),

              // Close button when trailer playing
              if (_showTrailer)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      _youtubeController?.pauseVideo();
                      setState(() => _showTrailer = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              
              // ML recommendation badge
              if (widget.isMlRecommendation && !_showTrailer)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ML',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Partner liked badge
              if (widget.partnerLiked && !_showTrailer)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Partner liked',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient overlay (hidden during trailer)
              if (!_showTrailer)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

              // Content (hidden during trailer)
              if (widget.showDetails && !_showTrailer)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Year, runtime, and rating
                      Row(
                        children: [
                          if (widget.movie.year != null) ...[
                            _InfoChip(text: '${widget.movie.year}'),
                          ],
                          if (widget.movie.runtime != null) ...[
                            const SizedBox(width: 8),
                            _InfoChip(text: '${widget.movie.runtime} min'),
                          ],
                          if (widget.movie.voteAverage != null) ...[
                            const SizedBox(width: 8),
                            _InfoChip(
                              text: widget.movie.voteAverage!.toStringAsFixed(1),
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                            ),
                          ],
                        ],
                      ),

                      // Genres
                      if (widget.movie.genres.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: widget.movie.genres.take(3).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPink.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                genre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Description
                      if (widget.movie.overview != null && widget.movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.movie.overview!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          maxLines: widget.showDetails ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (widget.movie.posterUrl != null && widget.movie.posterUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _onPosterTap(context),
        child: Image.network(
          widget.movie.posterUrl!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            if (loadingProgress.expectedTotalBytes == null) return child;
            return _ShimmerPlaceholder(
              progress: loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!,
            );
          },
          errorBuilder: (_, _, _) => Container(
            color: AppColors.surfaceDark,
            child: const Center(
              child: Icon(Icons.broken_image, size: 60, color: Colors.white38),
            ),
          ),
        ),
      );
    }
    return Container(
      color: AppColors.surfaceDark,
      child: GestureDetector(
        onTap: () => _onPosterTap(context),
        child: const Icon(Icons.movie, size: 80, color: Colors.white54),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;

  const _InfoChip({
    required this.text,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? Colors.white70),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final double progress;
  const _ShimmerPlaceholder({required this.progress});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
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
    return Container(
      color: AppColors.surfaceDark,
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
              color: Colors.white.withValues(alpha: 0.1),
            ),
          );
        },
      ),
    );
  }
}