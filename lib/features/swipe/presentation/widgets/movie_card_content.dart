import 'package:flutter/material.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';
import 'package:cinematch/core/theme/app_theme.dart';

class MovieCardContent extends StatelessWidget {
  final MovieModel movie;
  final bool showDetails;

  const MovieCardContent({
    super.key,
    required this.movie,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (movie.posterUrl != null)
              Image.network(
                movie.posterUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.movie, size: 80, color: Colors.white54),
                ),
              )
            else
              Container(
                color: AppTheme.surfaceDark,
                child: const Icon(Icons.movie, size: 80, color: Colors.white54),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            if (showDetails)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (movie.year != null)
                          Text(
                            '${movie.year}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        if (movie.runtime != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${movie.runtime} min',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                    if (movie.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: movie.genres.take(3).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
