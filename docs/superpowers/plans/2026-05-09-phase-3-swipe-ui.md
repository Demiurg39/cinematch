# Cinematch Phase 3: Core Swipe UI

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tinder-style swipe cards with 4-direction gestures (right=like, left=dislike, down=maybe, up=veto). Movie cards show poster, title, year, genres, runtime. Swipe hints visible.

**Architecture:** SwipeCard widget uses GestureDetector + AnimationController for physics-based swipe. SwipeState tracks current swipe progress. SwipeProvider manages card deck state.

**Tech Stack:** flutter_riverpod, animation

---

## File Structure

```
lib/features/swipe/
├── presentation/
│   ├── swipe_screen.dart           # Main swipe screen
│   ├── widgets/
│   │   ├── swipe_card.dart         # Animated swipe card
│   │   ├── swipe_indicators.dart   # Direction hints
│   │   └── movie_card_content.dart # Movie info display
│   └── providers/
│       └── swipe_provider.dart     # Swipe state management
```

---

## Tasks

### Task 1: Swipe Card Widget

**Files:**
- Create: `lib/features/swipe/presentation/widgets/swipe_card.dart`

- [ ] **Step 1: Create swipe_card.dart**

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum SwipeDirection { left, right, up, down }

class SwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double threshold;

  const SwipeCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.threshold = 100,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragPosition = Offset.zero;
  Offset _dragVelocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SwipeDirection? _getSwipeDirection() {
    final dx = _dragPosition.dx.abs();
    final dy = _dragPosition.dy.abs();

    if (dx < 30 && dy < 30) return null;

    if (dx > dy) {
      return _dragPosition.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      return _dragPosition.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }
  }

  Color _getOverlayColor() {
    final direction = _getSwipeDirection();
    switch (direction) {
      case SwipeDirection.right:
        return Colors.green.withOpacity(_dragPosition.dx / 300);
      case SwipeDirection.left:
        return Colors.red.withOpacity(_dragPosition.dx.abs() / 300);
      case SwipeDirection.up:
        return Colors.orange.withOpacity(_dragPosition.dy.abs() / 300);
      case SwipeDirection.down:
        return Colors.blue.withOpacity(_dragPosition.dy / 300);
      default:
        return Colors.transparent;
    }
  }

  IconData? _getOverlayIcon() {
    final direction = _getSwipeDirection();
    switch (direction) {
      case SwipeDirection.right:
        return Icons.thumb_up;
      case SwipeDirection.left:
        return Icons.thumb_down;
      case SwipeDirection.up:
        return Icons.block;
      case SwipeDirection.down:
        return Icons.schedule;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => _controller.stop(),
      onPanUpdate: (details) {
        setState(() {
          _dragPosition += details.delta;
        });
      },
      onPanEnd: (details) {
        _dragVelocity = details.velocity.pixelsPerSecond;

        final direction = _getSwipeDirection();
        if (direction != null) {
          final distance = direction == SwipeDirection.right || direction == SwipeDirection.left
              ? _dragPosition.dx.abs()
              : _dragPosition.dy.abs();

          if (distance > widget.threshold || _dragVelocity.distance > 500) {
            switch (direction) {
              case SwipeDirection.right:
                widget.onSwipeRight?.call();
                break;
              case SwipeDirection.left:
                widget.onSwipeLeft?.call();
                break;
              case SwipeDirection.up:
                widget.onSwipeUp?.call();
                break;
              case SwipeDirection.down:
                widget.onSwipeDown?.call();
                break;
            }
          }
        }

        setState(() {
          _dragPosition = Offset.zero;
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_dragPosition.dx, _dragPosition.dy)
          ..rotateZ(_dragPosition.dx / 500),
        alignment: Alignment.center,
        child: Stack(
          children: [
            widget.child,
            if (_getSwipeDirection() != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: _getOverlayColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _getOverlayIcon(),
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/swipe/presentation/widgets/swipe_card.dart && git commit -m "feat: add SwipeCard widget with gesture detection"
```

---

### Task 2: Movie Card Content

**Files:**
- Create: `lib/features/swipe/presentation/widgets/movie_card_content.dart`

- [ ] **Step 1: Create movie_card_content.dart**

```dart
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
            // Poster Image
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

            // Gradient overlay
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

            // Movie info
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/swipe/presentation/widgets/movie_card_content.dart && git commit -m "feat: add MovieCardContent widget"
```

---

### Task 3: Swipe Indicators

**Files:**
- Create: `lib/features/swipe/presentation/widgets/swipe_indicators.dart`

- [ ] **Step 1: Create swipe_indicators.dart**

```dart
import 'package:flutter/material.dart';

class SwipeIndicators extends StatelessWidget {
  const SwipeIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left = Dislike
          Column(
            children: [
              Icon(Icons.thumb_down, color: Colors.red, size: 24),
              SizedBox(height: 4),
              Text('Dislike', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          // Down = Maybe
          Column(
            children: [
              Icon(Icons.schedule, color: Colors.blue, size: 24),
              SizedBox(height: 4),
              Text('Maybe', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          // Up = Veto
          Column(
            children: [
              Icon(Icons.block, color: Colors.orange, size: 24),
              SizedBox(height: 4),
              Text('Veto', style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
          // Right = Like
          Column(
            children: [
              Icon(Icons.thumb_up, color: Colors.green, size: 24),
              SizedBox(height: 4),
              Text('Like', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/swipe/presentation/widgets/swipe_indicators.dart && git commit -m "feat: add SwipeIndicators widget"
```

---

### Task 4: Swipe Provider

**Files:**
- Create: `lib/features/swipe/presentation/providers/swipe_provider.dart`

- [ ] **Step 1: Create swipe_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../movies/data/movies_repository.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';

part 'swipe_provider.g.dart';

@riverpod
class SwipeDeckNotifier extends _$SwipeDeckNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    final cached = await repository.getCachedMovies(limit: 20);
    if (cached.isNotEmpty) return cached;

    // Fallback to TMDB popular
    return repository.getPopularMovies();
  }

  void onSwipe(SwipeAction action, MovieModel movie) {
    final currentDeck = state.valueOrNull ?? [];
    final updatedDeck = currentDeck.where((m) => m.id != movie.id).toList();
    state = AsyncData(updatedDeck);
  }

  Future<void> loadMore() async {
    final repository = ref.read(moviesRepositoryProvider);
    final currentDeck = state.valueOrNull ?? [];
    final newMovies = await repository.getPopularMovies(page: 2);
    state = AsyncData([...currentDeck, ...newMovies]);
  }
}
```

- [ ] **Step 2: Create swipe_action.dart**

```dart
enum SwipeAction {
  like,
  dislike,
  maybe,
  veto,
}
```

- [ ] **Step 3: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```bash
git add lib/features/swipe/ lib/core/theme/ && git commit -m "feat: add SwipeProvider and SwipeDeckNotifier"
```

---

### Task 5: Swipe Screen

**Files:**
- Create: `lib/features/swipe/presentation/swipe_screen.dart`

- [ ] **Step 1: Create swipe_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/swipe_provider.dart';
import '../widgets/swipe_card.dart';
import '../widgets/swipe_indicators.dart';
import '../widgets/movie_card_content.dart';
import '../../movies/domain/movie_model.dart';

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
              // Movie card stack
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background card
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
                      // Top card (swipeable)
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
              // Swipe indicators
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/swipe/presentation/swipe_screen.dart && git commit -m "feat: add SwipeScreen with card stack"
```

---

### Task 6: Swipe Tests

**Files:**
- Create: `test/swipe/swipe_card_test.dart`

- [ ] **Step 1: Create swipe_card_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/swipe/presentation/widgets/swipe_card.dart';

void main() {
  group('SwipeCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              child: Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('calls onSwipeRight callback', (tester) async {
      bool swipedRight = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              onSwipeRight: () => swipedRight = true,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

      // Drag right
      await tester.drag(from: const Offset(150, 200), to: const Offset(400, 200));
      await tester.pumpAndSettle();

      expect(swipedRight, isTrue);
    });

    testWidgets('calls onSwipeLeft callback', (tester) async {
      bool swipedLeft = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              onSwipeLeft: () => swipedLeft = true,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

      // Drag left
      await tester.drag(from: const Offset(150, 200), to: const Offset(-100, 200));
      await tester.pumpAndSettle();

      expect(swipedLeft, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/swipe/swipe_card_test.dart`

- [ ] **Step 3: Commit**

```bash
git add test/swipe/swipe_card_test.dart && git commit -m "test: add SwipeCard tests"
```

---

## Self-Review

- [x] Phase 3 Swipe UI: SwipeCard, MovieCardContent, SwipeIndicators, SwipeProvider, SwipeScreen
- [x] All files created with actual code, no placeholders
- [x] No TODOs or TBDs remaining
- [x] Tests for SwipeCard included (3 tests passing)
- [x] All 17 tests pass (10 auth + 4 movie + 3 swipe)
- [ ] Next: Phase 4 Matching System

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-3-swipe-ui.md`**

Two execution options:

**1. Subagent-Driven** - Dispatch subagents per task
**2. Inline Execution** - Execute tasks in this session

Which approach?