# Cinematch MVP Spec

**Date:** 2026-05-08
**Status:** Draft

---

## 1. Overview

**Cinematch** — cross-platform social movie matching ecosystem. Solves "Paradox of Choice" via Tinder-style swipe mechanic with real-time matching.

**Core loop:** Swipe movies → mutual likes = match → watch together

**Target users:** Individuals, couples, friend groups.

---

## 2. Tech Stack

| Layer             | Technology                              |
| ----------------- | --------------------------------------- |
| Frontend          | Flutter (Dart)                          |
| State Management  | Riverpod (with code generation)         |
| Backend/DB        | Supabase (PostgreSQL)                   |
| Auth              | Supabase Auth (email/password + Google) |
| Data Source       | TMDB API v4                             |
| Server-side Logic | Supabase Edge Functions + pg_cron       |
| Environment       | NixOS (Flakes) + .env secrets           |

---

## 3. Features & Build Order

### Phase 1: Auth

- Email/password + Google social login
- User profile (username, avatar, preferences)
- Supabase Auth integration
- `preferred_language` (e.g., 'en', 'ru') and `region` (e.g., 'US', 'RU') for localized TMDB results

### Phase 2: Movie Cache DB

- Store essential movie data locally: `id`, `tmdb_id`, `title`, `year`, `genres`, `poster_url`, `popularity`, `runtime`
- Pre-fetch 50-100 movies for matching (background refresh)
- `last_synced_at` to avoid TMDB rate limits
- Full details (cast, trailers) on-demand on movie detail screen
- ML-ready genre vector structure
- **Background sync via Supabase Edge Functions + pg_cron** (server-side, not mobile)

### Phase 3: Core Swipe UI

- Swipe card interface with 4 directions:
  - **Right** = like
  - **Left** = dislike
  - **Down** = maybe (reappears after 7 days or moves to back of deck)
  - **Up** = veto
- Veto per-session (not permanent, can pay later)
- Movie poster, title, year, genres, runtime displayed
- Streaming provider badges via TMDB Watch Providers
- Swipe hints shown

### Phase 4: Matching System

- Mutual like detection via Supabase DB trigger
- Match notification (confetti animation)
- Match detail screen: movie info + where to watch + streaming links
- Match history

### Phase 5: Rooms (Group Sessions)

- Create/join rooms
- `match_threshold` per room: 'unanimous', 'majority', 'half'
- `status` per room: 'active', 'archived', 'completed'
- Invite friends to room
- Group swipe sessions with shared movie pool
- Group veto: one veto removes one movie from pool (unlimited per user, tracked per room)
- Real-time sync via Supabase Broadcast/Presence
- Room Presence: show who is currently swiping
- Swiping indicators ("Partner is swiping...")

### Phase 6: Room Pool Mechanics

- All likes from room members → shared pool
- Veto removes movie from pool
- Random selection triggers:
  - **Timer**: configurable (e.g., 24h after last swipe)
  - **Vote**: majority or unanimous agreement (based on room's `match_threshold`)
- Selected movie: confetti animation + movie info + streaming links

### Phase 7: Partner Mode

- Link two user accounts as partners
- Shared watchlist
- "Together History" — everything watched as pair
- Genre Harmony Map — visual radar chart of overlapping genres
- Time spent statistics (requires `runtime` from movies table)

### Phase 8: Friends System

- Add users as friends
- View public watchlists
- Invite to spontaneous matching sessions

### Phase 9: ML Clustering

- k-means clustering implemented in PL/pgSQL
- Recalculation triggered via pg_cron (nightly or on-demand)
- Genre preference vectors per user (normalized 0.0 to 1.0)
- Recency decay: $W_t = W_0 \cdot e^{-\lambda t}$ — recent likes weigh more than older likes
- Maybe swipes weighted at 0.2, Likes at 1.0
- Taste profile groups → personalized recommendations
- `clusters` table stores centroids (genre_weights_vector)

### Phase 10: Extras

- Movie Roulette — random winner from mutual matches pool
- Streaming integration — provider badges/links on all movie views
- Notifications — match alerts, room updates, timer warnings
- Radar chart for genre harmony

---

## 4. Database Schema (MVP Scope)

### Users (extends Supabase auth)

- `id` (uuid, PK)
- `username` (text)
- `avatar_url` (text) → references Supabase Storage bucket
- `preferred_language` (text, default 'en')
- `region` (text, default 'US')
- `created_at` (timestamp)

### Movies (cached from TMDB)

- `id` (uuid, PK)
- `tmdb_id` (int, unique) — **Index**
- `title` (text)
- `year` (int)
- `poster_url` (text) → Supabase Storage
- `genres` (text[]) — **GIN Index**
- `popularity` (float)
- `runtime` (int, minutes)
- `cached_at` (timestamp)
- `last_synced_at` (timestamp)

### Watchlists

- `id` (uuid, PK)
- `user_id` (uuid, FK → users)
- `movie_id` (uuid, FK → movies)
- `status` (enum: watching, plan_to_watch, watched, dropped)
- `rating` (int, nullable)
- `watched_at` (timestamp, nullable)
- `deleted_at` (timestamp, nullable) — soft delete
- `created_at` (timestamp)

### Swipes

- `id` (uuid, PK)
- `user_id` (uuid, FK → users)
- `movie_id` (uuid, FK → movies)
- `direction` (enum: like, dislike, maybe, veto)
- `room_id` (uuid, nullable, FK → rooms)
- `created_at` (timestamp)
- **Composite index on (user_id, movie_id)** — prevents duplicates, speeds up filters

### Matches

- `id` (uuid, PK)
- `movie_id` (uuid, FK → movies)
- `created_at` (timestamp)

### MatchUsers (junction)

- `match_id` (uuid, FK → matches)
- `user_id` (uuid, FK → users)

### Rooms

- `id` (uuid, PK)
- `name` (text)
- `created_by` (uuid, FK → users) — **Index**
- `match_threshold` (enum: unanimous, majority, half)
- `status` (enum: active, archived, completed) — default 'active'
- `timer_end_at` (timestamp, nullable)
- `created_at` (timestamp)

### RoomMembers

- `room_id` (uuid, FK → rooms)
- `user_id` (uuid, FK → users)
- `joined_at` (timestamp)

### RoomVetoes (tracks vetoes per room)

- `id` (uuid, PK)
- `room_id` (uuid, FK → rooms)
- `user_id` (uuid, FK → users)
- `movie_id` (uuid, FK → movies)
- `created_at` (timestamp)

### Partners (user linking)

- `user_a_id` (uuid, FK → users)
- `user_b_id` (uuid, FK → users)
- `linked_at` (timestamp)

### Friendships

- `user_id` (uuid, FK → users)
- `friend_id` (uuid, FK → users)
- `status` (enum: pending, accepted)
- `created_at` (timestamp)

### Clusters (ML centroids)

- `id` (int, PK)
- `name` (text, e.g., 'Action Lovers', 'Drama Fans')
- `genre_weights_vector` (float[]) — normalized 0.0 to 1.0
- `updated_at` (timestamp)

### UserClusterAssignments

- `user_id` (uuid, FK → users)
- `cluster_id` (int, FK → clusters)
- `assigned_at` (timestamp)

---

## 5. Indexes

| Table       | Index                                            | Purpose                                   |
| ----------- | ------------------------------------------------ | ----------------------------------------- |
| movies      | `idx_movies_tmdb_id` on `tmdb_id`                | Fast TMDB lookups                         |
| movies      | `idx_movies_genres` USING GIN on `genres`        | Fast genre array search                   |
| swipes      | `idx_swipes_user_movie` on `(user_id, movie_id)` | Prevent duplicates, filter "already seen" |
| rooms       | `idx_rooms_created_by` on `created_by`           | User's rooms lookup                       |
| friendships | `idx_friendships_user` on `(user_id, status)`    | Pending requests                          |

---

## 6. Swipe Interaction Details

| Direction | Action  | Storage                                                    |
| --------- | ------- | ---------------------------------------------------------- |
| Right     | Like    | `swipes` table, direction='like'                           |
| Left      | Dislike | `swipes` table, direction='dislike'                        |
| Down      | Maybe   | `swipes` table, direction='maybe' — reappears after 7 days |
| Up        | Veto    | `swipes` table, direction='veto'                           |

**Discovery Feed Query (RPC):**

```sql
SELECT * FROM movies m
WHERE m.id NOT IN (
  SELECT movie_id FROM swipes WHERE user_id = auth.uid() AND direction != 'maybe'
)
OR (
  m.id IN (
    SELECT movie_id FROM swipes
    WHERE user_id = auth.uid()
      AND direction = 'maybe'
      AND created_at < NOW() - INTERVAL '7 days'
  )
)
ORDER BY m.popularity DESC
LIMIT 50;
```

Veto behavior:

- Per-session (not permanent)
- In rooms: one veto = one movie removed from pool
- In 1:1 matching: vetoes don't affect partner's pool

---

## 7. Match Detection Logic

Only matches for `active` rooms or 1:1 matching (no room_id).

```
DB Trigger on INSERT to swipes:
  IF direction = 'like' AND room_id IS NULL THEN
    SELECT * FROM swipes
    WHERE movie_id = NEW.movie_id
      AND direction = 'like'
      AND user_id != NEW.user_id
      AND room_id IS NULL

    IF match found THEN
      CREATE match record
      INSERT into match_users for both users
      BROADCAST payload: { movie_id, poster_url, title } via Supabase Realtime

  IF direction = 'like' AND room_id IS NOT NULL THEN
    -- Room matching: check against match_threshold
    -- Broadcast to room channel
```

**Realtime broadcast payload includes:** `movie_id`, `poster_url`, `title` — no additional DB query needed.

---

## 8. Room Pool Mechanics

1. User joins room → sees shared movie pool (room status must be 'active')
2. All users swipe independently
3. Likes → pool (visible to all)
4. Vetoes → remove from pool (tracked in `room_vetoes`)
5. Timer or vote triggers random selection (room status must be 'active')
6. Selected movie → confetti animation + streaming info
7. Movie added to "watch together" list for room

**Presence:** Show online members, swiping indicators.

**Ghost Session Prevention:** Inactive rooms (no activity for 30 days) should be auto-archived via pg_cron.

---

## 9. TMDB API Rate Limiting

- Use `last_synced_at` to skip fresh data
- Background sync via **Supabase Edge Functions** (server-side, not mobile)
- Sync scheduled via **pg_cron** (off-peak hours, e.g., 3 AM UTC)
- Batch fetch movie details (50 at a time)
- Cache posters in Supabase Storage

---

## 10. ML Specifications

**Input Vector:** Genre preference vector per user

- Normalized: weights between 0.0 and 1.0

**Swipe Weights:**

- Like: 1.0
- Maybe: 0.2
- Dislike/Veto: ignored or -0.5

**Recency Decay Formula:**
$$W_t = W_0 \cdot e^{-\lambda t}$$

Where:

- $W_t$ = final weight
- $W_0$ = initial weight (1.0 for Like)
- $\lambda$ = decay constant (e.g., 0.05 for slow fade)
- $t$ = days since swipe

**Clustering:** k-means in PL/pgSQL

- Recalculation via pg_cron (nightly)
- Clusters stored in `clusters` table
- Users assigned via `user_cluster_assignments`

---

## 11. Security Policies (RLS)

### Swipes

- `INSERT`: only if `auth.uid() = user_id`
- `SELECT`: only if user is room member or own swipes

### Rooms

- `DELETE`/`UPDATE`: only `created_by` user
- `SELECT`: only room members

### Partners

- Access to shared stats: only if `auth.uid()` in (`user_a_id`, `user_b_id`)

### Movies

- Public read for all authenticated users

### Storage (Supabase Storage)

- Avatar bucket: users can only upload own avatar (RLS policy)
- Poster bucket: public read

---

## 12. Design Direction

From Figma slices:

- Dark theme (dark background, light text)
- Pink (#E91E63) + purple accent colors
- Swipe cards with gesture hints
- Bottom navigation: Home, Search, Add, Notifications, Profile
- Radar chart for genre harmony
- Confetti animation on match
- Streaming provider badges on movie cards

---

## 13. Out of Scope (MVP)

- Payment for permanent veto (future feature)
- Full ML pipeline (Phase 9) — placeholder schema + recalculation only
- Native push notifications (Supabase Realtime for now)
- Offline-first sync with complex conflict resolution
- Full-text search optimization

---

## 14. Verification

Spec complete. Awaiting user approval before creating implementation plan.
