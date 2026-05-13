-- =============================================================================
-- USER PREFERENCE VECTOR COMPUTATION
-- =============================================================================

-- Function to compute a user's genre preference vector from their liked movies
-- Returns array where index corresponds to genre index and value is weight
CREATE OR REPLACE FUNCTION public.compute_user_preference_vector(user_id_param UUID)
RETURNS FLOAT[] AS $$
DECLARE
  -- Genre ordering must match application logic (first 20 TMDB genres)
  genre_order TEXT[] := ARRAY[
    'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 'Documentary',
    'Drama', 'Family', 'Fantasy', 'History', 'Horror', 'Music', 'Mystery',
    'Romance', 'Science Fiction', 'TV Movie', 'Thriller', 'War', 'Western'
  ];
  preference_vector FLOAT[] := ARRAY[]::FLOAT[];
  liked_movies_genres TEXT[];
  genre_weights JSONB := '{"total": 0}'::JSONB;
  i INTEGER;
  genre_name TEXT;
  weight FLOAT;
  total_liked INTEGER;
BEGIN
  -- Get all genres from movies user has liked (excluding current user if self-referencing)
  SELECT ARRAY_AGG(m.genres)
  INTO liked_movies_genres
  FROM public.swipes s
  JOIN public.movies m ON s.movie_id = m.id
  WHERE s.user_id = user_id_param
    AND s.direction = 'like'
    AND s.room_id IS NULL;

  -- Count total liked movies for normalization
  SELECT COUNT(*)
  INTO total_liked
  FROM public.swipes
  WHERE user_id = user_id_param
    AND direction = 'like'
    AND room_id IS NULL;

  -- Build genre weights from liked movies
  genre_weights := '{"total": 0}'::JSONB;

  FOR i IN SELECT generate_subscripts(liked_movies_genres, 1) LOOP
    IF liked_movies_genres[i] IS NOT NULL THEN
      FOREACH genre_name IN SELECT UNNEST(liked_movies_genres[i]) LOOP
        IF genre_weights ? genre_name THEN
          genre_weights := jsonb_set(genre_weights, ARRAY[genre_name], (genre_weights->genre_name->>'count')::JSONB || '{"count": 1}'::JSONB || ',"total": 0'::JSONB);
          -- Actually just increment
          genre_weights := jsonb_set(genre_weights, ARRAY[genre_name, 'count'], ((genre_weights->genre_name->>'count')::INT + 1)::TEXT::JSONB);
        ELSE
          genre_weights := jsonb_set(genre_weights, ARRAY[genre_name], '{"count": 1}'::JSONB);
        END IF;
      END LOOP;
    END IF;
  END LOOP;

  -- Build normalized preference vector (all 19 genres)
  preference_vector := ARRAY[]::FLOAT[];
  genre_weights := genre_weights - 'total';

  FOREACH genre_name IN SELECT UNNEST(genre_order) LOOP
    IF genre_weights ? genre_name THEN
      -- Normalize by total liked movies
      weight := (genre_weights->genre_name->>'count')::FLOAT / NULLIF(total_liked, 0);
      preference_vector := array_append(preference_vector, weight);
    ELSE
      preference_vector := array_append(preference_vector, 0.0);
    END IF;
  END LOOP;

  RETURN preference_vector;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Simplified version that returns genre name to weight mapping
CREATE OR REPLACE FUNCTION public.get_user_genre_preferences(user_id_param UUID)
RETURNS TABLE(genre TEXT, weight FLOAT, like_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  WITH user_likes AS (
    SELECT m.genres
    FROM public.swipes s
    JOIN public.movies m ON s.movie_id = m.id
    WHERE s.user_id = user_id_param
      AND s.direction = 'like'
      AND s.room_id IS NULL
  ),
  genre_counts AS (
    SELECT UNNEST(genres) as genre, COUNT(*) as cnt
    FROM user_likes
    GROUP BY UNNEST(genres)
  ),
  total_likes AS (
    SELECT COUNT(*) as total FROM user_likes
  )
  SELECT gc.genre, (gc.cnt::FLOAT / NULLIF(t.total, 0))::FLOAT as weight, gc.cnt
  FROM genre_counts gc
  CROSS JOIN total_likes t
  ORDER BY weight DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- MOVIE RECOMMENDATION FUNCTION
-- =============================================================================

-- Function to get personalized movie recommendations based on user's preference vector
-- and what similar users have liked
CREATE OR REPLACE FUNCTION public.get_recommended_movies(
  user_id_param UUID,
  exclude_swiped BOOLEAN DEFAULT true,
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE(
  movie_id UUID,
  tmdb_id INTEGER,
  title TEXT,
  year INTEGER,
  poster_url TEXT,
  genres TEXT[],
  popularity FLOAT,
  match_score FLOAT,
  match_reason TEXT
) AS $$
DECLARE
  user_genres JSONB;
  rec_movies JSONB;
BEGIN
  -- Step 1: Get user's top genres from their likes
  user_genres := (
    SELECT jsonb_object_agg(genre, weight)
    FROM public.get_user_genre_preferences(user_id_param)
    WHERE weight > 0
  );

  -- Step 2: If no history, return popular movies
  IF user_genres IS NULL OR jsonb_object_keys(user_genres) IS NULL THEN
    RETURN QUERY
    SELECT
      m.id as movie_id,
      m.tmdb_id,
      m.title,
      m.year,
      m.poster_url,
      m.genres,
      m.popularity,
      m.popularity as match_score,
      'Popular choice' as match_reason
    FROM public.movies m
    WHERE m.popularity > 0
    ORDER BY m.popularity DESC
    LIMIT limit_count;
    RETURN;
  END IF;

  -- Step 3: Find movies that match user's genre preferences
  -- Score = sum of (movie's genre weights * user's preference weights)
  RETURN QUERY
  WITH user_liked AS (
    SELECT movie_id FROM public.swipes
    WHERE user_id = user_id_param AND direction = 'like'
  ),
  scorable_movies AS (
    SELECT
      m.id,
      m.tmdb_id,
      m.title,
      m.year,
      m.poster_url,
      m.genres,
      m.popularity,
      COALESCE(m.popularity, 0) as pop_score,
      (
        SELECT SUM(COALESCE((user_genres->>g.genre)::FLOAT, 0))
        FROM UNNEST(m.genres) as g(genre)
      ) as genre_score,
      CASE WHEN ul.movie_id IS NOT NULL THEN true ELSE false END as already_liked
    FROM public.movies m
    LEFT JOIN user_liked ul ON m.id = ul.movie_id
    WHERE m.popularity IS NOT NULL
  )
  SELECT
    sm.id as movie_id,
    sm.tmdb_id,
    sm.title,
    sm.year,
    sm.poster_url,
    sm.genres,
    sm.popularity,
    (sm.genre_score + sm.pop_score / 1000) as match_score,
    CASE
      WHEN sm.genre_score > 2 THEN 'Matches your favorite genres'
      WHEN sm.genre_score > 1 THEN 'Aligns with your preferences'
      ELSE 'Popular in your network'
    END as match_reason
  FROM scorable_movies sm
  WHERE NOT sm.already_liked OR NOT exclude_swiped
  ORDER BY match_score DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- SIMILAR USERS & CROSS-RECOMMENDATIONS
-- =============================================================================

-- Function to find users with similar preferences (based on genre overlap)
CREATE OR REPLACE FUNCTION public.find_similar_users(user_id_param UUID, limit_count INTEGER DEFAULT 10)
RETURNS TABLE(user_id UUID, similarity_score FLOAT, common_genres TEXT[]) AS $$
BEGIN
  RETURN QUERY
  WITH user_prefs AS (
    SELECT genre, weight
    FROM public.get_user_genre_preferences(user_id_param)
    WHERE weight > 0.1
  ),
  other_users AS (
    SELECT DISTINCT s.user_id
    FROM public.swipes s
    WHERE s.user_id != user_id_param
      AND s.direction = 'like'
      AND s.room_id IS NULL
  ),
  other_user_prefs AS (
    SELECT up.user_id, up.genre, up.weight
    FROM other_users ou
    JOIN LATERAL (
      SELECT genre, weight
      FROM public.get_user_genre_preferences(ou.user_id)
      WHERE weight > 0.1
    ) up ON true
  ),
  similarity AS (
    SELECT
      oup.user_id,
      SUM(u.weight * oup.weight) as dot_product
    FROM user_prefs u
    JOIN other_user_prefs oup ON u.genre = oup.genre
    GROUP BY oup.user_id
  )
  SELECT
    s.user_id,
    s.dot_product as similarity_score,
    ARRAY(
      SELECT u.genre
      FROM user_prefs u
      JOIN other_user_prefs oup ON u.genre = oup.genre AND oup.user_id = s.user_id
      WHERE u.weight > 0.2 AND oup.weight > 0.2
    ) as common_genres
  FROM similarity s
  WHERE s.dot_product > 0
  ORDER BY s.dot_product DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recommendations based on what similar users liked
CREATE OR REPLACE FUNCTION public.get_similar_users_recommendations(
  user_id_param UUID,
  exclude_swiped BOOLEAN DEFAULT true,
  limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
  movie_id UUID,
  tmdb_id INTEGER,
  title TEXT,
  year INTEGER,
  poster_url TEXT,
  genres TEXT[],
  popularity FLOAT,
  from_user_id UUID,
  similarity_score FLOAT,
  match_reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH similar_users AS (
    SELECT * FROM public.find_similar_users(user_id_param, 20)
  ),
  recommended_movies AS (
    SELECT
      s.movie_id,
      s.user_id as from_user_id,
      su.similarity_score,
      ROW_NUMBER() OVER (PARTITION BY s.movie_id ORDER BY su.similarity_score DESC) as rn
    FROM public.swipes s
    JOIN similar_users su ON s.user_id = su.user_id
    WHERE s.direction = 'like' AND s.room_id IS NULL
  )
  SELECT
    m.id as movie_id,
    m.tmdb_id,
    m.title,
    m.year,
    m.poster_url,
    m.genres,
    m.popularity,
    rm.from_user_id,
    rm.similarity_score,
    'Liked by similar user' as match_reason
  FROM recommended_movies rm
  JOIN public.movies m ON rm.movie_id = m.id
  WHERE rm.rn = 1
  ORDER BY rm.similarity_score DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- CLUSTER ASSIGNMENT
-- =============================================================================

-- Insert predefined genre clusters
INSERT INTO public.clusters (name, genre_weights_vector, updated_at) VALUES
  ('Action & Adventure', ARRAY[0.8, 0.9, 0.1, 0.2, 0.3, 0.0, 0.3, 0.1, 0.5, 0.0, 0.1, 0.0, 0.1, 0.1, 0.6, 0.0, 0.5, 0.3, 0.4]::FLOAT[], NOW()),
  ('Comedy & Romance', ARRAY[0.1, 0.1, 0.2, 0.9, 0.1, 0.0, 0.3, 0.3, 0.2, 0.0, 0.0, 0.2, 0.0, 0.8, 0.1, 0.1, 0.2, 0.0, 0.1]::FLOAT[], NOW()),
  ('Horror & Thriller', ARRAY[0.4, 0.2, 0.0, 0.1, 0.4, 0.0, 0.2, 0.0, 0.3, 0.0, 0.9, 0.0, 0.5, 0.1, 0.3, 0.0, 0.8, 0.1, 0.2]::FLOAT[], NOW()),
  ('Drama & Documentary', ARRAY[0.2, 0.1, 0.2, 0.3, 0.3, 0.8, 0.9, 0.2, 0.1, 0.6, 0.1, 0.3, 0.4, 0.5, 0.2, 0.3, 0.3, 0.2, 0.1]::FLOAT[], NOW()),
  ('Family & Animation', ARRAY[0.3, 0.5, 0.9, 0.6, 0.1, 0.2, 0.4, 0.9, 0.7, 0.1, 0.0, 0.4, 0.1, 0.3, 0.4, 0.2, 0.1, 0.1, 0.2]::FLOAT[], NOW()),
  ('Sci-Fi & Fantasy', ARRAY[0.5, 0.6, 0.4, 0.2, 0.2, 0.1, 0.3, 0.4, 0.9, 0.2, 0.2, 0.2, 0.4, 0.3, 0.9, 0.1, 0.4, 0.2, 0.3]::FLOAT[], NOW())
ON CONFLICT DO NOTHING;

-- Function to assign user to cluster based on their preference vector
CREATE OR REPLACE FUNCTION public.assign_user_to_cluster(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
  user_vector FLOAT[];
  best_cluster_id INTEGER;
  best_similarity FLOAT := -1;
  cluster_record RECORD;
  similarity FLOAT;
BEGIN
  -- Get user's preference vector
  user_vector := public.compute_user_preference_vector(user_id_param);

  -- If no vector (no likes), return NULL
  IF user_vector IS NULL OR array_length(user_vector, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  -- Find best matching cluster using cosine similarity
  FOR cluster_record IN
    SELECT c.id, c.genre_weights_vector FROM public.clusters c
  LOOP
    similarity := vector_cosine_similarity(user_vector, cluster_record.genre_weights_vector);

    IF similarity > best_similarity THEN
      best_similarity := similarity;
      best_cluster_id := cluster_record.id;
    END IF;
  END LOOP;

  -- Insert or update user's cluster assignment
  INSERT INTO public.user_cluster_assignments (user_id, cluster_id, assigned_at)
  VALUES (user_id_param, best_cluster_id, NOW())
  ON CONFLICT (user_id, cluster_id) DO UPDATE
    SET assigned_at = NOW();

  RETURN best_cluster_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cosine similarity helper function
CREATE OR REPLACE FUNCTION public.vector_cosine_similarity(a FLOAT[], b FLOAT[])
RETURNS FLOAT AS $$
DECLARE
  dot_product FLOAT := 0;
  norm_a FLOAT := 0;
  norm_b FLOAT := 0;
  i INTEGER;
BEGIN
  -- Calculate dot product and norms
  FOR i IN 1..array_length(a, 1) LOOP
    dot_product := dot_product + COALESCE(a[i], 0) * COALESCE(b[i], 0);
    norm_a := norm_a + COALESCE(a[i], 0)^2;
    norm_b := norm_b + COALESCE(b[i], 0)^2;
  END LOOP;

  norm_a := sqrt(norm_a);
  norm_b := sqrt(norm_b);

  IF norm_a = 0 OR norm_b = 0 THEN
    RETURN 0;
  END IF;

  RETURN dot_product / (norm_a * norm_b);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger to auto-assign cluster when user accumulates likes
CREATE OR REPLACE FUNCTION public.auto_assign_cluster_on_threshold()
RETURNS TRIGGER AS $$
DECLARE
  user_like_count INTEGER;
  last_assignment_at TIMESTAMPTZ;
  days_since_assign INTEGER;
BEGIN
  -- Only trigger on 'like' direction
  IF NEW.direction != 'like' THEN
    RETURN NEW;
  END IF;

  -- Check if user has enough new likes since last cluster assignment
  SELECT COUNT(*), MAX(assigned_at)
  INTO user_like_count, last_assignment_at
  FROM public.swipes s
  LEFT JOIN public.user_cluster_assignments uca ON s.user_id = uca.user_id
  WHERE s.user_id = NEW.user_id
    AND s.direction = 'like'
    AND (last_assignment_at IS NULL OR s.created_at > last_assignment_at)
  GROUP BY s.user_id;

  -- Reassign cluster if user has 10+ new likes since last assignment
  -- and last assignment was more than 1 day ago
  IF user_like_count >= 10 THEN
    -- Check if we should reassign (more than 1 day since last)
    IF last_assignment_at IS NULL OR (NOW() - last_assignment_at) > INTERVAL '1 day' THEN
      PERFORM public.assign_user_to_cluster(NEW.user_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_swipe_like_cluster_check
    AFTER INSERT ON public.swipes
    FOR EACH ROW EXECUTE FUNCTION public.auto_assign_cluster_on_threshold();

-- =============================================================================
-- TEST DATA GENERATION
-- =============================================================================

-- Function to seed test data for a user (for development)
CREATE OR REPLACE FUNCTION public.seed_user_preferences(
  user_id_param UUID,
  genre_preferences JSONB
)
RETURNS void AS $$
DECLARE
  genre TEXT;
  movie_record RECORD;
BEGIN
  -- This would seed a user's preferences based on genre map
  -- In production, this comes from actual swipes
  RAISE NOTICE 'User % preferences seeded: %', user_id_param, genre_preferences;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.compute_user_preference_vector(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_genre_preferences(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_recommended_movies(UUID, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.find_similar_users(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_similar_users_recommendations(UUID, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_user_to_cluster(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.vector_cosine_similarity(FLOAT[], FLOAT[]) TO authenticated;