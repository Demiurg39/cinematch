import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/swipe/presentation/widgets/movie_card_content.dart';
import 'package:cinematch/features/swipe/presentation/widgets/swipe_indicators.dart';
import 'package:cinematch/features/swipe/domain/swipe_action.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';
import 'package:cinematch/core/theme/app_theme.dart';

void main() {
  group('Tab structure layout', () {
    testWidgets('TabBar renders Personalized and Popular tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.amoledDark(null),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: 'Personalized'),
                          Tab(text: 'Popular'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Personalized'), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
    });

    testWidgets('Tab switching works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.amoledDark(null),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: 'Personalized'),
                          Tab(text: 'Popular'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Center(child: Text('Personalized content')),
                        Center(child: Text('Popular content')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Personalized content'), findsOneWidget);
      expect(find.text('Popular content'), findsNothing);

      await tester.tap(find.text('Popular'));
      await tester.pumpAndSettle();

      expect(find.text('Popular content'), findsOneWidget);
      expect(find.text('Personalized content'), findsNothing);
    });
  });

  group('SwipeIndicators', () {
    testWidgets('renders all four indicator buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeIndicators(),
          ),
        ),
      );

      expect(find.text('Dislike'), findsOneWidget);
      expect(find.text('Maybe'), findsOneWidget);
      expect(find.text('Veto'), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
    });

    testWidgets('calls onLike when pressed', (tester) async {
      bool liked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeIndicators(
              onLike: () => liked = true,
            ),
          ),
        ),
      );

      // Tap the Like button area (the icon + text)
      await tester.tap(find.text('Like'));
      await tester.pump();

      expect(liked, isTrue);
    });
  });

  group('MovieCardContent rendering', () {
    testWidgets('renders movie title', (tester) async {
      final movie = MovieModel(
        id: 'test-1',
        tmdbId: 1,
        title: 'Test Movie Title',
        year: 2024,
        cachedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 500,
              child: MovieCardContent(movie: movie),
            ),
          ),
        ),
      );

      expect(find.text('Test Movie Title'), findsOneWidget);
    });

    testWidgets('shows ML badge when isMlRecommendation is true',
        (tester) async {
      final movie = MovieModel(
        id: 'test-2',
        tmdbId: 2,
        title: 'ML Movie',
        year: 2024,
        cachedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 500,
              child: MovieCardContent(
                movie: movie,
                isMlRecommendation: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ML'), findsOneWidget);
    });

    testWidgets('hides ML badge when isMlRecommendation is false',
        (tester) async {
      final movie = MovieModel(
        id: 'test-3',
        tmdbId: 3,
        title: 'Normal Movie',
        year: 2024,
        cachedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 500,
              child: MovieCardContent(movie: movie),
            ),
          ),
        ),
      );

      expect(find.text('ML'), findsNothing);
    });
  });

  group('SwipeAction', () {
    test('all swipe actions have correct names', () {
      expect(SwipeAction.like.name, 'like');
      expect(SwipeAction.dislike.name, 'dislike');
      expect(SwipeAction.maybe.name, 'maybe');
      expect(SwipeAction.veto.name, 'veto');
    });

    test('swipe actions are unique', () {
      final names = SwipeAction.values.map((e) => e.name).toSet();
      expect(names.length, SwipeAction.values.length);
    });
  });
}