-- Cinematch Database Schema
-- Run this in Supabase SQL Editor

-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- Define Enums
CREATE TYPE swipe_direction AS ENUM ('like', 'dislike', 'maybe', 'veto');
CREATE TYPE watchlist_status AS ENUM ('watching', 'plan_to_watch', 'watched', 'dropped');
CREATE TYPE room_status AS ENUM ('active', 'archived', 'completed');
CREATE TYPE match_threshold AS ENUM ('unanimous', 'majority', 'half');
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted');

-- =============================================================================
-- TABLES
-- =============================================================================

-- Users (extends Supabase auth)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    preferred_language TEXT DEFAULT 'en',
    region TEXT DEFAULT 'US',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Movies (cached from TMDB)
CREATE TABLE public.movies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tmdb_id INTEGER UNIQUE NOT NULL,
    title TEXT NOT NULL,
    year INTEGER,
    poster_url TEXT,
    genres TEXT[] DEFAULT '{}',
    popularity FLOAT DEFAULT 0,
    runtime INTEGER,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    last_synced_at TIMESTAMPTZ DEFAULT NOW()
);

-- Watchlists
CREATE TABLE public.watchlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    movie_id UUID REFERENCES public.movies(id) ON DELETE CASCADE,
    status watchlist_status DEFAULT 'plan_to_watch',
    rating INTEGER,
    watched_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rooms
CREATE TABLE public.rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_by UUID REFERENCES public.users(id),
    status room_status DEFAULT 'active',
    match_threshold match_threshold DEFAULT 'unanimous',
    timer_end_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Room Members
CREATE TABLE public.room_members (
    room_id UUID REFERENCES public.rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

-- Room Vetoes
CREATE TABLE public.room_vetoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES public.rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    movie_id UUID REFERENCES public.movies(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (room_id, movie_id)
);

-- Swipes
CREATE TABLE public.swipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    movie_id UUID REFERENCES public.movies(id) ON DELETE CASCADE,
    room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
    direction swipe_direction NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Matches
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movie_id UUID REFERENCES public.movies(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Match Users (junction)
CREATE TABLE public.match_users (
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    PRIMARY KEY (match_id, user_id)
);

-- Partners
CREATE TABLE public.partners (
    user_a_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    user_b_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    linked_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_a_id, user_b_id)
);

-- Friendships
CREATE TABLE public.friendships (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    status friendship_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id)
);

-- Clusters (ML centroids)
CREATE TABLE public.clusters (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    genre_weights_vector FLOAT[] NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Cluster Assignments
CREATE TABLE public.user_cluster_assignments (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    cluster_id INTEGER REFERENCES public.clusters(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, cluster_id)
);

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_movies_tmdb_id ON public.movies(tmdb_id);
CREATE INDEX idx_movies_genres ON public.movies USING GIN (genres);
CREATE INDEX idx_swipes_user_movie ON public.swipes(user_id, movie_id);
CREATE INDEX idx_swipes_room ON public.swipes(room_id);
CREATE INDEX idx_rooms_created_by ON public.rooms(created_by);
CREATE INDEX idx_rooms_status ON public.rooms(status);
CREATE INDEX idx_friendships_user ON public.friendships(user_id, status);
CREATE INDEX idx_watchlists_user ON public.watchlists(user_id);
CREATE INDEX idx_watchlists_deleted ON public.watchlists(deleted_at) WHERE deleted_at IS NULL;

-- =============================================================================
-- MATCH DETECTION TRIGGER
-- =============================================================================

CREATE OR REPLACE FUNCTION public.check_for_match()
RETURNS TRIGGER AS $$
DECLARE
    other_user_id UUID;
    match_id UUID;
    movie_title TEXT;
    movie_poster TEXT;
    payload JSON;
BEGIN
    -- Only check for 1:1 matches (not in a room)
    IF NEW.direction = 'like' AND NEW.room_id IS NULL THEN

        SELECT user_id INTO other_user_id
        FROM public.swipes
        WHERE movie_id = NEW.movie_id
          AND direction = 'like'
          AND user_id != NEW.user_id
          AND room_id IS NULL
        LIMIT 1;

        IF other_user_id IS NOT NULL THEN
            -- Create match
            INSERT INTO public.matches (movie_id) VALUES (NEW.movie_id) RETURNING id INTO match_id;

            -- Link users
            INSERT INTO public.match_users (match_id, user_id) VALUES (match_id, NEW.user_id), (match_id, other_user_id);

            -- Fetch movie info for realtime broadcast
            SELECT title, poster_url INTO movie_title, movie_poster FROM public.movies WHERE id = NEW.movie_id;

            -- Broadcast match to both users via Supabase Realtime
            -- Payload includes movie info to avoid extra DB call on client
            payload := json_build_object(
                'match_id', match_id,
                'movie_id', NEW.movie_id,
                'title', movie_title,
                'poster_url', movie_poster,
                'user_ids', ARRAY[NEW.user_id, other_user_id]
            );

            PERFORM pg_notify('match_events', payload::text);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_swipe_like
    AFTER INSERT ON public.swipes
    FOR EACH ROW EXECUTE FUNCTION public.check_for_match();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_vetoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clusters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_cluster_assignments ENABLE ROW LEVEL SECURITY;

-- Users: public read, own write
CREATE POLICY "Users are viewable by everyone" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Movies: public read
CREATE POLICY "Movies are viewable by everyone" ON public.movies FOR SELECT USING (true);

-- Watchlists: own read/write
CREATE POLICY "Users can view own watchlist" ON public.watchlists FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own watchlist" ON public.watchlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own watchlist" ON public.watchlists FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can soft delete own watchlist" ON public.watchlists FOR DELETE USING (auth.uid() = user_id);

-- Rooms: members can view, creator can update/delete
CREATE POLICY "Room members can view room" ON public.rooms FOR SELECT
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_id = public.rooms.id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create rooms" ON public.rooms FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Room creator can update room" ON public.rooms FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Room creator can delete room" ON public.rooms FOR DELETE USING (auth.uid() = created_by);

-- Room Members: members can view, self-join
CREATE POLICY "Room members can view members" ON public.room_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members rm
            JOIN public.rooms r ON rm.room_id = r.id
            WHERE rm.room_id = public.room_members.room_id
            AND (rm.user_id = auth.uid() OR r.created_by = auth.uid())
        )
    );

CREATE POLICY "Users can join room" ON public.room_members FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Room Vetoes: room members can view/insert
CREATE POLICY "Room members can view vetoes" ON public.room_vetoes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_id = public.room_vetoes.room_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Room members can add vetoes" ON public.room_vetoes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Swipes: own read/write
CREATE POLICY "Users can view own swipes" ON public.swipes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own swipes" ON public.swipes FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Matches: participants can view
CREATE POLICY "Match participants can view matches" ON public.matches FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.match_users
            WHERE match_id = public.matches.id AND user_id = auth.uid()
        )
    );

-- Match Users: participants can view
CREATE POLICY "Match participants can view match users" ON public.match_users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.match_users mu
            WHERE mu.match_id = public.match_users.match_id AND mu.user_id = auth.uid()
        )
    );

-- Partners: only linked users
CREATE POLICY "Partners can view each other" ON public.partners FOR SELECT
    USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- Friendships: participants can view
CREATE POLICY "Friends can view each other" ON public.friendships FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can send friend requests" ON public.friendships FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can accept own requests" ON public.friendships FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Clusters: authenticated read
CREATE POLICY "Authenticated users can view clusters" ON public.clusters FOR SELECT USING (true);

-- User Cluster Assignments: self + authenticated read
CREATE POLICY "Users can view own cluster assignments" ON public.user_cluster_assignments FOR SELECT
    USING (auth.uid() = user_id);

-- =============================================================================
-- SUPABASE STORAGE BUCKETS
-- =============================================================================

-- Avatars bucket (users can only upload own avatar)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload own avatar" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own avatar" ON storage.objects
    FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Avatars are publicly readable" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

-- Posters bucket (public read for movie posters)
INSERT INTO storage.buckets (id, name, public)
VALUES ('posters', 'posters', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Posters are publicly readable" ON storage.objects
    FOR SELECT USING (bucket_id = 'posters');

CREATE POLICY "Authenticated users can upload posters" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'posters' AND auth.role() = 'authenticated');

-- =============================================================================
-- REALTIME CONFIG
-- =============================================================================

-- Enable realtime for match notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.swipes;