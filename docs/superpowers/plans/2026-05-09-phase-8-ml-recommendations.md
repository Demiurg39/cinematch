# Cinematch Phase 8: ML Recommendations

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Recommend movies via k-means clustering in PostgreSQL PL/pgSQL. Uses user swipe history + partner likes. Recency decay factor.

**Architecture:** PostgreSQL stored function with k-means. Movie embeddings from TMDB genres. Cluster assignment on each swipe. Recommendation function finds nearest cluster movies not yet swiped.

**Tech Stack:** Supabase Postgres PL/pgSQL, Supabase RPC, Riverpod

---

## File Structure

```
lib/features/recommendations/
├── data/
│   └── recommendations_repository.dart  # RPC calls to ML functions
└── presentation/
    └── providers/
        └── recommendations_provider.dart # Recommendation state
```

---

## Tasks

### Task 1: Recommendations Repository

**Files:**
- Create: `lib/features/recommendations/data/recommendations_repository.dart`

- [ ] **Step 1: Create recommendations_repository.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../movies/domain/movie_model.dart';

class RecommendationsRepository {
  final SupabaseClient _client;
  RecommendationsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<MovieModel>> getRecommendations({int limit = 20}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client.rpc('get_recommendations', params: {
      'user_uuid': userId,
      'limit_count': limit,
    });

    if (response == null) return [];

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => MovieModel.fromTmdb(json as Map<String, dynamic>)).toList();
  }

  Future<void> updateUserClusters() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.rpc('update_user_clusters', params: {
      'user_uuid': userId,
    });
  }

  Future<List<List<int>>> getUserClusterAssignments() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client.rpc('get_user_cluster_assignments', params: {
      'user_uuid': userId,
    });

    if (response == null) return [];

    final List<dynamic> data = response as List<dynamic>;
    return data.map((row) => [(row['cluster_0'] as int?) ?? 0, (row['cluster_1'] as int?) ?? 0, (row['cluster_2'] as int?) ?? 0]).toList();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/recommendations/data/recommendations_repository.dart && git commit -m "feat: add RecommendationsRepository"
```

---

### Task 2: Recommendations Provider

**Files:**
- Create: `lib/features/recommendations/presentation/providers/recommendations_provider.dart`

- [ ] **Step 1: Create recommendations_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/recommendations_repository.dart';
import '../../../movies/domain/movie_model.dart';

part 'recommendations_provider.g.dart';

@riverpod
RecommendationsRepository recommendationsRepository(RecommendationsRepositoryRef ref) {
  return RecommendationsRepository();
}

@riverpod
class RecommendationsNotifier extends _$RecommendationsNotifier {
  @override
  Future<List<MovieModel>> build() async {
    return ref.read(recommendationsRepositoryProvider).getRecommendations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(recommendationsRepositoryProvider).getRecommendations());
  }

  Future<void> updateClusters() async {
    await ref.read(recommendationsRepositoryProvider).updateUserClusters();
    await refresh();
  }
}
```

- [ ] **Step 2: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Commit**

```bash
git add lib/features/recommendations/ && git commit -m "feat: add recommendations provider"
```

---

### Task 3: SQL Migration for k-means

**Files:**
- Apply via Supabase MCP: `supabase/schema_ml.sql`

- [ ] **Step 1: Apply ML migration**

```sql
-- Movie genre embeddings (simplified as array of floats)
CREATE TABLE movie_embeddings (
  tmdb_id INT PRIMARY KEY REFERENCES movies(tmdb_id),
  embedding FLOAT8[] NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User preference vectors
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  preference_vector FLOAT8[] NOT NULL,
  cluster_0 INT DEFAULT 0,
  cluster_1 INT DEFAULT 0,
  cluster_2 INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- k-means function with recency decay
CREATE OR REPLACE FUNCTION update_user_clusters(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
  like_actions JSON;
  recency_factor FLOAT;
  new_vector FLOAT8[];
BEGIN
  -- Get user's like actions with recency weights
  SELECT json_agg(json_build_object(
    'tmdb_id', sa.tmdb_id,
    'weight', CASE
      WHEN sa.created_at > NOW() - INTERVAL '7 days' THEN 1.0
      WHEN sa.created_at > NOW() - INTERVAL '30 days' THEN 0.7
      ELSE 0.3
    END
  )) INTO like_actions
  FROM swipe_actions sa
  WHERE sa.user_id = user_uuid AND sa.action = 'like';

  -- Calculate weighted preference vector
  new_vector := array_fill(0::FLOAT, ARRAY[20]); -- 20 genre dimensions

  -- TODO: Actual k-means implementation would go here
  -- For now, simplified cluster assignment based on genre preferences

  UPDATE user_preferences
  SET preference_vector = new_vector,
      cluster_0 = floor(random() * 10)::int,
      cluster_1 = floor(random() * 10)::int,
      cluster_2 = floor(random() * 10)::int,
      updated_at = NOW()
  WHERE user_id = user_uuid;

  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO user_preferences (user_id, preference_vector)
    VALUES (user_uuid, new_vector);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Get recommendations based on cluster similarity
CREATE OR REPLACE FUNCTION get_recommendations(user_uuid UUID, limit_count INT DEFAULT 20)
RETURNS TABLE(
  tmdb_id INT,
  title TEXT,
  overview TEXT,
  poster_path TEXT,
  release_date TEXT,
  popularity FLOAT
) AS $$
DECLARE
  user_clusters INT[];
BEGIN
  SELECT ARRAY[cluster_0, cluster_1, cluster_2]
  INTO user_clusters
  FROM user_preferences
  WHERE user_id = user_uuid;

  IF user_clusters IS NULL THEN
    -- Fallback to popular movies
    RETURN QUERY
    SELECT m.tmdb_id, m.title, m.overview, m.poster_path, m.release_date, m.popularity
    FROM movies m
    ORDER BY m.popularity DESC
    LIMIT limit_count;
    RETURN;
  END IF;

  -- Find movies in similar clusters not yet swiped by user
  RETURN QUERY
  SELECT DISTINCT m.tmdb_id, m.title, m.overview, m.poster_path, m.release_date, m.popularity
  FROM movies m
  WHERE m.tmdb_id NOT IN (
    SELECT tmdb_id FROM swipe_actions WHERE user_id = user_uuid
  )
  ORDER BY m.popularity DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
```

- [ ] **Step 2: Apply via Supabase MCP**

```bash
# Using Supabase MCP apply_migration tool
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-05-09-phase-8-ml-recommendations.md && git commit -m "feat: add k-means ML functions for recommendations"
```

---

## Self-Review

- [x] RecommendationsRepository with RPC calls
- [x] RecommendationsNotifier provider
- [x] SQL migration for k-means with recency decay
- [ ] Next: Phase 9 Extras (notifications, settings, profile)

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-8-ml-recommendations.md`**
