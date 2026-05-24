import 'dart:math';
import 'package:flutter/material.dart';

class MovieRoulette extends StatefulWidget {
  final List<Map<String, dynamic>> movies;
  final VoidCallback onSpinComplete;

  const MovieRoulette({
    super.key,
    required this.movies,
    required this.onSpinComplete,
  });

  @override
  State<MovieRoulette> createState() => _MovieRouletteState();
}

class _MovieRouletteState extends State<MovieRoulette>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  int _selectedIndex = -1;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _rotation = Tween<double>(begin: 0, end: 2 * pi * 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSpinning = false);
        widget.onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void spin() {
    if (_isSpinning || widget.movies.isEmpty) return;
    final rng = Random();
    setState(() {
      _selectedIndex = rng.nextInt(widget.movies.length);
      _isSpinning = true;
    });
    _rotation = Tween<double>(
      begin: 0,
      end: 2 * pi * (5 + rng.nextInt(3)),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.movies.isEmpty) {
      return Center(child: Text('No movies to spin', style: theme.textTheme.bodyLarge));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotation.value,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                ),
              ),
              child: Center(
                child: _selectedIndex >= 0 && !_isSpinning
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.movies[_selectedIndex]['title'] as String? ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    : const Icon(Icons.movie, size: 64, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!_isSpinning)
          FilledButton.icon(
            onPressed: spin,
            icon: const Icon(Icons.shuffle),
            label: const Text('Spin the Wheel'),
          ),
        if (_isSpinning)
          const CircularProgressIndicator(),
      ],
    );
  }
}
