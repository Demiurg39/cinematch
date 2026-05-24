# Cinematch

**Stop scrolling, start watching.** Cinematch is a cross-platform social movie discovery ecosystem that replaces tedious solo browsing with real-time, shared multiplayer matching. Think Tinder for movies — for individuals, couples, and groups.

---

## Project Overview

Cinematch tackles the "Paradox of Choice" in movie night decisions. Instead of aimlessly scrolling through catalogs, users swipe through personalized decks of movie cards, like or pass on titles, and instantly match when mutual interest is detected. The platform extends beyond individual matching into:

- **Partner Mode** — Couples get shared analytics, genre harmony visualization, and a private watch history.
- **Dynamic Rooms** — Groups of friends join time-boxed swiping sessions with customizable timers, capacity limits, and democratic outcome resolution via roulette or unanimous match.
- **Social Hub** — Live friend/partner presence tracking, request management, and a reactive social grid.

The entire backend — authentication, database, realtime broadcasts, and row-level security — runs on Supabase (PostgreSQL). The frontend is built with Flutter using Riverpod for state management, TMDB for movie metadata, and YouTube iframe players for inline trailer streaming.

---

## Tech Stack

| Layer                | Technology                                                |
| :------------------- | :-------------------------------------------------------- |
| **Frontend**         | Flutter 3.x, Dart 3.x                                     |
| **State Management** | Riverpod 2.x (with `riverpod_annotation` code generation) |
| **Serialization**    | Freezed + `json_serializable`                             |
| **Backend / DB**     | Supabase (PostgreSQL 15, Realtime Broadcast, Auth)        |
| **Movie Data**       | TMDB API v3 (`dio` HTTP client)                           |
| **Video Playback**   | `youtube_player_iframe` (WebKitGTK-based WebView)         |
| **Auth Storage**     | `flutter_secure_storage` (session persistence)            |
| **Theme**            | Material 3 + `dynamic_color`                              |
| **Testing**          | `flutter_test`, `mocktail`, `integration_test`            |
| **Environment**      | NixOS (Flakes), `.env` secrets                            |

### Dependencies (key packages)

```yaml
flutter_riverpod: ^2.6.1 # State management
riverpod_annotation: ^2.6.1 # @riverpod code generation
supabase_flutter: ^2.8.0 # Auth, DB, Realtime
dio: ^5.7.0 # TMDB HTTP client
freezed_annotation: ^2.4.4 # Immutable models
json_annotation: ^4.9.0 # JSON serialization
youtube_player_iframe: ^6.0.0 # Inline trailer playback
confetti: ^0.8.0 # Match celebration effects
url_launcher: ^6.3.1 # External browser fallback
flutter_secure_storage: ^10.2.0 # Auth session persistence
dynamic_color: ^1.8.1 # Material You dynamic theming
```

---

## Architecture & Design Patterns

### Feature-First Layered Structure

The codebase organizes by feature domain, with each feature containing its own data, domain, and presentation layers:

```
lib/
  core/                         # Shared infrastructure
    constants/                  # App-wide constants (API keys, etc.)
    localization/               # UserLocale model + provider
    presentation/widgets/       # Reusable UI components (confirm dialog)
    theme/                      # Material 3 theme tokens + AMOLED colors
    tmdb/                       # TMDB API client + endpoints
  features/
    auth/                       # Authentication (email, Google OAuth)
      data/                     #   AuthRepository, AuthSessionService
      domain/                   #   AuthState, UserModel
      presentation/             #   AuthScreen, providers, widgets
    friends/                    # Friendship management
      data/                     #   FriendsRepository
      domain/                   #   FriendshipModel
      presentation/             #   SocialHubScreen, AddFriendScreen
    matches/                    # Match detection and history
    movies/                     # Movie caching, TMDB integration
    partners/                   # Partner linking + analytics
    recommendations/            # ML-based recommendations (RPC)
    rooms/                      # Multiplayer swiping rooms
    settings/                   # User settings + profile editing
    swipe/                      # Swipe deck engine
    users/                      # Presence tracking
  app.dart                      # Material 3 app root
  app_shell.dart                # Bottom navigation shell
  main.dart                     # Entry point + Supabase init
```

### Riverpod State Management

All state is managed through Riverpod with code generation (`@riverpod` annotation). Providers form a reactive dependency graph:

```
authNotifierProvider
    └─ userLocaleProvider            (derives language/region from auth state)
         └─ SwipeDeckNotifier        (watched by Personalized tab)
         └─ PopularDeckNotifier      (watched by Popular tab)
         └─ PopularMoviesNotifier    (popular movie list screen)
         └─ WatchProvidersNotifier   (streaming info per movie)
         └─ MovieSearchNotifier      (search screen)
```

Key patterns:

- **Notifier classes** (`@riverpod class`) for mutable state with async initialization.
- **Family providers** (`@riverpod`) parameterized by `tmdbId` or `roomId`.
- **Stream providers** for Supabase Realtime subscriptions (match events, presence).
- **Provider invalidation cascade** — changing language/region in profile triggers `authNotifierProvider.refresh()`, which propagates through `userLocaleProvider` to all TMDB data providers, causing automatic content re-fetch with new locale parameters.

### TMDB Localization

Every TMDB API call accepts `language` (e.g., `ru-RU`) and `region` (e.g., `RU`) parameters derived from the authenticated user's preferences. Trailer video fetching implements a fallback pipeline: query localized first, retry `en-US` on empty results.

---

## Implemented Feature Specification

### Authentic Auth Loop

| Capability                       | Implementation                                                                       |
| -------------------------------- | ------------------------------------------------------------------------------------ |
| Email/password sign-up & sign-in | Supabase Auth + custom `users` table via AuthRepository                              |
| Google OAuth                     | Supabase OAuth with PKCE flow                                                        |
| Session persistence              | `flutter_secure_storage` with auto-restore on app launch                             |
| Error validation                 | Material 3 inline error banners for weak passwords, invalid email, wrong credentials |
| State machine                    | Sealed `AuthState` (Initial, Loading, Authenticated, Unauthenticated, Error)         |
| Cached session restore           | `AuthNotifier.restoreSession()` checks secure storage on cold start                  |

### Contextual Swipe Deck

The core interaction surface — a Tinder-style card stack with four swipe directions:

| Direction | Action  | Behavior                                           |
| --------- | ------- | -------------------------------------------------- |
| Right (→) | Like    | Records like, checks for mutual match              |
| Left (←)  | Dislike | Removes from deck, never shown again               |
| Up (↑)    | Veto    | Permanently excludes movie from future suggestions |
| Down (↓)  | Maybe   | Soft pass — may reappear later                     |

Card features:

- **Rating badge** — Vote average from TMDB displayed as a star chip.
- **Inline trailer** — Tap the poster to play the YouTube trailer directly in the card via `youtube_player_iframe`. Falls back to external browser if WebView unavailable.
- **Long-press context menu** — View Details, Add to List, Watch Later.
- **ML recommendation badge** — Purple gradient "ML" chip on vector-returned movies.
- **Partner sparkle indicator** — Red heart badge when partner has liked the same movie.
- **Shimmer loading** — Animated gradient placeholders during deck initialization.
- **Empty state** — "All caught up!" message when deck exhausted.

Two parallel decks:

- **Personalized tab** — Sources from vector recommendations → RPC recommendations → TMDB discover → TMDB popular.
- **Popular tab** — Sources from TMDB popular → TMDB discover by genre.

Both decks share the identical `MovieCardContent` widget — same layout, same features.

### Real-Time Social Hub

| Feature           | Implementation                                                 |
| ----------------- | -------------------------------------------------------------- |
| Friend requests   | Send/accept/reject with duplicate-request prevention           |
| Partner linking   | Invite-code-based or direct link with mutual acceptance        |
| Presence tracking | Supabase `user_presence` table, lifecycle-based online/offline |
| Live friend grid  | Reactive dashboard with online status dots                     |
| Genre Harmony Map | Radar chart plotting genre overlap between partner accounts    |
| Shared analytics  | Cross-reference individual likes + partner watch history       |

### Single Adaptive Room Board

Multiplayer swiping sessions with full lifecycle management:

| Phase        | States                  | Behavior                                                                      |
| ------------ | ----------------------- | ----------------------------------------------------------------------------- |
| **Lobby**    | `lobby`                 | Create/join room, set timer (2/3/5/10/20 min), toggle privacy, invite friends |
| **Voting**   | `voting`                | Members swipe through shared movie deck independently                         |
| **Resolved** | `matched`, `revealed`   | Unanimous match → instant win overlay; Timer expiry → shared pool review      |
| **Cleanup**  | `archived`, `completed` | Trigger deletes all room swipes, vetoes, and members via DB trigger           |

Room features:

- **Capacity limits** — Enforced maximum participant count.
- **Clipboard-ready invite codes** — Share room code outside the app.
- **Admin transfer** — Ownership can be reassigned to another member.
- **Timer picker** — ChoiceChips for session duration.
- **Democratic selection** — After timer expires, mutual likes are surfaced in a shared pool review screen.
- **Movie Roulette** — Spin animation randomly picks a winner from the shared pool.
- **Unanimous match overlay** — Full-screen celebration when all members like the same movie.
- **Self-destroying lifecycle** — Cleanup trigger purges transient data (swipes, vetoes, memberships) on room completion.

### In-Database Machine Learning

Personalized recommendations run entirely inside PostgreSQL via PL/pgSQL:

- **k-Means clustering** — Users are grouped into taste profiles based on genre preference vectors.
- **Vector similarity** — Cosine similarity between user preference vectors for fine-grained recommendations.
- **Cold start** — New users without swipe history receive popular movies until ML data accumulates.
- **Cluster maintenance** — `updateUserClusters()` RPC re-assigns users periodically as taste data grows.

### Settings & Profile

- **Language/region selection** — Dialog-based picker with 10 languages and 10 regions.
- **Instant UI mutation** — Profile edits call `AuthNotifier.refreshCurrentUser()`, which cascades through the provider graph to reload all TMDB content with new locale parameters.
- **Save feedback** — `LinearProgressIndicator` at screen top during persistence.
- **Notifications** — Toggle push, match, and partner notifications (`user_settings` table).
- **Dark mode** — AMOLED-optimized dark theme with Material 3 dynamic colors.

---

## Database Schema Blueprint

The schema uses 15 tables across 3 domains. All tables enable Row-Level Security (RLS).

### Core User Tables

```sql
users              -- Profiles extending auth.users (id, username, avatar_url,
                   --   preferred_language, region)
user_presence      -- Online/offline tracking (user_id, is_online, last_seen_at)
user_settings      -- App preferences (notifications_enabled, dark_mode, etc.)
```

### Social Domain

```sql
friendships        -- Bidirectional friendship links (user_id, friend_id, status)
partners           -- Couple links (user_a_id, user_b_id, status, invite_code)
partner_watch_history  -- Shared viewing history (partner_link_id, movie_id)
```

### Matching Domain

```sql
movies             -- TMDB metadata cache (tmdb_id, title, year, genres, poster_url, popularity)
swipes             -- User swipe actions (user_id, movie_id, room_id, direction)
matches            -- Mutual like events (movie_id) + match_users junction table
```

### Rooms Domain

```sql
rooms              -- Swiping sessions (name, created_by, status, match_threshold, is_private, timer_end_at)
room_members       -- Participant membership (room_id, user_id)
room_vetoes        -- Per-room movie exclusions (room_id, movie_id)
```

### ML Domain

```sql
clusters              -- k-means centroids (name, genre_weights_vector)
user_cluster_assignments  -- Per-user cluster membership (user_id, cluster_id)
```

### Row-Level Security

RLS policies enforce strict data boundaries:

- **Users** — Public read, self-only write.
- **Movies** — Public read (cached TMDB data).
- **Swipes** — Self-only read/write (cannot see another user's swipes).
- **Rooms** — Members and creator can view; creator updates/deletes.
- **Matches** — Only participants can view match records.
- **Partners** — Only two linked users can view their partner data.
- **Friendships** — Both parties can view/manage.
- **Presence** — Public read for authenticated users, self-only update.

### Realtime Publications

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE swipes;
ALTER PUBLICATION supabase_realtime ADD TABLE partner_watch_history;
ALTER PUBLICATION supabase_realtime ADD TABLE room_members;
ALTER PUBLICATION supabase_realtime ADD TABLE user_presence;
```

### Match Detection Trigger

An `AFTER INSERT` trigger on `swipes` automatically detects mutual likes (1:1 outside rooms) and creates a `matches` record with a `pg_notify` broadcast to both users. Room-based matches use `checkUnanimousMatch()` called from the application layer.

---

## Testing & Reliability

### Test Suites

| Type                 | Count | Location            |
| -------------------- | ----- | ------------------- |
| Unit tests           | 115+  | `test/`             |
| Integration tests    | 19+   | `integration_test/` |
| TMDB API integration | Suite | `test/tmdb/`        |

### Coverage Areas

- **Auth flow** — Email/password login, registration, validation errors, session restore, Google OAuth redirect.
- **Social rooms flow** — Friend requests, partner linking, room creation, invite codes, timer expiry navigation.
- **Domain models** — MovieModel, RoomModel, UserModel, MatchModel, FriendshipModel, PartnerModel (serialization round-trips, edge cases).
- **Swipe deck** — Card rendering, swipe actions, ML recommendation badges, partner indicators.
- **ML functions** — Cosine similarity, vector operations, k-means boundary cases.
- **TMDB API** — Real HTTP calls to verify response structure, field presence, error handling.

### Defensive Patterns

- **Cold start handling** — Empty decks fall back progressively: vector recs → RPC recs → TMDB discover → TMDB popular.
- **Cache fallback** — TMDB caching errors silently ignored; movies still returned from live API.
- **Loading shimmer** — Animated gradient placeholders during all async data loading.
- **Empty states** — Custom "All caught up" and "No streaming info" messaging throughout.
- **Pre-existing test failures** — 3 widget tests have pre-existing `ProviderScope` context issues (non-functional, unrelated to feature code).

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Nix (optional, for environment reproducibility)
- TMDB API Key (v3)
- Supabase project URL + anon key

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/cinematch.git
cd cinematch

# Configure environment
# Create a .env file with:
#   SUPABASE_URL=your_project_url
#   SUPABASE_ANON_KEY=your_anon_key
#   TMDB_API_KEY=your_tmdb_api_key

# Run with Nix (optional)
nix develop

# Install dependencies
flutter pub get

# Generate Riverpod + Freezed code
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Launch the app
flutter run
```

### Supabase Setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the SQL Editor to create all tables, triggers, indexes, and RLS policies.
3. Run `supabase/ml_functions.sql` to deploy the recommendation engine functions.
4. Enable Realtime on the tables listed in the schema.

---

## License

This project is for educational purposes as part of Database Systems and Mobile Development university courses.

---

**Cinematch: Because movie night shouldn't be a chore.**
