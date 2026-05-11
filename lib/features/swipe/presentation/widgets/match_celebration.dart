import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../../core/theme/app_theme.dart';

class MatchCelebration extends StatefulWidget {
  final MovieModel movie;
  final VoidCallback onDismiss;

  const MatchCelebration({
    super.key,
    required this.movie,
    required this.onDismiss,
  });

  @override
  State<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<MatchCelebration>
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

    // Start animations
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
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          // Confetti
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

          // Content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Match text
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

                    // Movie poster in heart shape
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

                    // Movie title
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
                    const SizedBox(height: 48),

                    // Continue button
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPink.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Keep Swiping',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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