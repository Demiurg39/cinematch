import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../../../core/theme/app_theme.dart';

class MatchCelebration extends ConsumerStatefulWidget {
  final MovieModel movie;
  final VoidCallback onDismiss;

  const MatchCelebration({
    super.key,
    required this.movie,
    required this.onDismiss,
  });

  @override
  ConsumerState<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends ConsumerState<MatchCelebration>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _confettiController.play();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchProvidersAsync = ref.watch(watchProvidersNotifierProvider(widget.movie.tmdbId));

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primaryPink,
                AppColors.accentPurple,
                Colors.yellow,
                Colors.orange,
                Colors.green,
                Colors.blue,
              ],
              numberOfParticles: 50,
              maxBlastForce: 100,
              minBlastForce: 50,
              emissionFrequency: 0.05,
              gravity: 0.2,
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        "WE HAVE A MATCH!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 200,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.movie.posterUrl != null
                            ? Image.network(
                                widget.movie.posterUrl!.replaceAll('/w500/', '/w780/'),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.surfaceDark,
                                child: const Icon(
                                  Icons.movie,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.movie.year != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${widget.movie.year}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _WatchProvidersSection(
                      watchProvidersAsync: watchProvidersAsync,
                      tmdbId: widget.movie.tmdbId,
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Text(
                          'Keep Swiping',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchProvidersSection extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> watchProvidersAsync;
  final int tmdbId;

  const _WatchProvidersSection({
    required this.watchProvidersAsync,
    required this.tmdbId,
  });

  @override
  Widget build(BuildContext context) {
    return watchProvidersAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      ),
      error: (_, __) => _WatchNowButton(tmdbId: tmdbId),
      data: (providers) {
        final flatrate = _extractFlatrate(providers);
        if (flatrate.isEmpty) {
          return _WatchNowButton(tmdbId: tmdbId);
        }
        return Column(
          children: [
            const Text(
              'Watch now on',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: flatrate.map((provider) {
                final logoPath = provider['logo_path'] as String?;
                final name = provider['provider_name'] as String? ?? 'Unknown';
                return GestureDetector(
                  onTap: () => _launchLink(providers),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w92$logoPath',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.tv,
                              color: AppColors.primaryPink,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _WatchNowButton(tmdbId: tmdbId),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _extractFlatrate(Map<String, dynamic>? providers) {
    if (providers == null) return [];
    final results = providers['results'] as Map<String, dynamic>?;
    if (results == null || results.isEmpty) return [];
    final usProviders = results['US'] as Map<String, dynamic>?;
    final regionProviders = usProviders ?? results.values.first as Map<String, dynamic>?;
    if (regionProviders == null) return [];
    return (regionProviders['flatrate'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<void> _launchLink(Map<String, dynamic>? providers) async {
    final results = providers?['results'] as Map<String, dynamic>?;
    if (results == null) return;
    final usProviders = results['US'] as Map<String, dynamic>?;
    final regionProviders = usProviders ?? results.values.first as Map<String, dynamic>?;
    final link = regionProviders?['link'] as String?;
    if (link != null) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class _WatchNowButton extends StatelessWidget {
  final int tmdbId;
  const _WatchNowButton({required this.tmdbId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchTmdb(tmdbId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_filled, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Watch on TMDB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchTmdb(int tmdbId) async {
    final url = 'https://www.themoviedb.org/movie/$tmdbId';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

void showMatchCelebration(BuildContext context, MovieModel movie) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => MatchCelebration(
      movie: movie,
      onDismiss: () {
        Navigator.of(context).pop();
      },
    ),
  );
}