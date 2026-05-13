# cinematch

**Stop scrolling, start watching.** Cinematch is a cross-platform social ecosystem designed to solve the "Paradox of Choice" in movie discovery. It combines a robust personal tracker with a real-time "matching" mechanic—think Tinder for movies—allowing individuals, couples, and groups to find common ground instantly.

---

## 🚀 Key Features

### 🎞️ Personal Tracker

- **Media Management:** Log movies, TV shows, and anime across custom categories: _Watching, Plan to Watch, Watched, and Dropped_.
- **Propose from Tracker:** Manually "push" a specific title from your personal watchlist into an active matching session for your group or partner to see.

### 👥 Social & Partner System

- **Partner Mode:** A dedicated mode for couples featuring shared analytics:
  - **Together History:** A unified list of everything you've watched as a pair.
  - **Genre Harmony Map:** A visual radar chart showing the overlap of your favorite genres.
  - **Time Spent:** Cumulative statistics of time spent watching content together.
- **Friendship Network:** Add users, view public watchlists, and invite friends to spontaneous matching sessions.

### 🃏 Interactive Matching

- **The Veto Power:** Strategic control to permanently exclude a specific movie from shared suggestions for a pair or group.
- **Movie Roulette:** A high-fidelity UI tool to randomly select a winner from a pool of mutual matches.
- **Streaming Integration:** Instantly see where a movie is available (Netflix, Apple TV, Disney+, etc.) via TMDB Watch Providers.
- **Preference choosing:** When swiping, you can choose genres, years, and etc to choose from content interesting for YOU

### 🧠 Intelligent Recommendations

- **In-Database ML:** Personalized suggestions powered by a **k-means clustering** algorithm implemented directly in **PL/pgSQL**.
- **Taste Clusters:** Users are grouped into "taste profiles" based on genre preference vectors, delivering high-accuracy recommendations without external ML overhead.

---

## 🛠️ Tech Stack

| Layer                | Technology                                               |
| :------------------- | :------------------------------------------------------- |
| **Frontend**         | [Flutter](https://flutter.dev/) (Dart)                   |
| **State Management** | [Riverpod](https://riverpod.dev/) (with Code Generation) |
| **Backend / DB**     | [Supabase](https://supabase.com/) (PostgreSQL)           |
| **Data Source**      | [TMDB API v4](https://developer.themoviedb.org/v4)       |
| **Environment**      | [NixOS](https://nixos.org/) (Flakes)                     |
| **Secrets**          | `.env` management                                        |

---

## 🏗️ Architecture

<!-- NOTE: Needs to be best practices -->

### Project Structure

<!-- NOTE: Implement -->

### Backend Logic

- **Real-time Synchronization:** Utilizes Supabase Broadcast and Presence for instantaneous match notifications.
- **Database Triggers:** Automated SQL triggers handle mutual match detection:
  > When User A and User B both "Like" a Movie ID, the database automatically creates a `Match` record and broadcasts it to both clients.
- **Optimized Caching:** Hybrid strategy storing essential metadata (IDs, genres, popularity) for ML processing while fetching heavy assets (posters, trailers) on-demand from TMDB.

---

## 🧪 Testing & Reliability

- **Unit Testing:** Comprehensive coverage for domain logic, including boundary cases (0, max, and overflow).
- **Edge Case Handling:** Robust "Cold Start" logic for new users and graceful handling of empty movie pools (Exhausted Deck UI).
- **Security:** strict **Row-Level Security (RLS)** policies ensuring User A cannot see User B’s private data without a mutual partnership link.

---

## 🚦 Getting Started

### Prerequisites

- Flutter SDK
- Nix (optional, for environment reproducibility)
- TMDB API Key (v4)
- Supabase Project URL & Anon Key

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/cinematch.git
    ```
2.  **Configure Environment:**
    Create a `.env` file in the root directory:
    ```env
    SUPABASE_URL=your_project_url
    SUPABASE_ANON_KEY=your_anon_key
    TMDB_API_KEY=your_tmdb_bearer_token
    ```
3.  **Run with Nix (optional):**
    ```bash
    nix develop
    ```
4.  **Launch the App:**
    ```bash
    flutter pub get
    flutter pub run build_runner build
    flutter run
    ```

---

## 📜 License

This project is for educational purposes as part of Database Systems and Mobile Development university courses.

---

**Cinematch: Because movie night shouldn't be a chore.**
