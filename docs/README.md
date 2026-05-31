# Scriptured

Scriptured is a SwiftUI iOS Bible reading habit app. It is local-first, works with bundled offline Bible JSON resources, and layers habit-building mechanics on top of daily reading: streaks, XP, levels, coins, and reward claiming.

## Current Features

- Offline Bible reader using bundled JSON files:
  - `en_bbe.json`
  - `zh_cuv.json`
- English and Chinese Bible language switching.
- Book and chapter navigation with previous/next chapter controls.
- Last reader position persistence across tab switches and app launches.
- Daily read/unread state backed by SwiftData reading sessions.
- Reward exploit protection using persistent reward transactions.
- XP, levels, coins, and lifetime coins.
- Streak tracking with at-risk state and streak freezes.
- Gamified Home dashboard.
- App appearance setting: System, Light, Dark.

## App Structure

```text
scriptured/
  App/              App-wide shell, environment, tab navigation, appearance mode
  Features/         SwiftUI feature screens
  Models/           SwiftData models and domain models
  Resources/Bible/  Bundled offline Bible JSON files
  Services/         Local-first data, progression, streak, and Bible services
  ViewModels/       Observable view models
  docs/             Project and Codex handoff documentation
```

## Core Screens

### Home

`Features/Home/HomeView.swift`

Shows the gamified dashboard:

- Large streak display
- Streak status and warning copy
- Today's reading goal
- XP progress and current level
- Coin and lifetime coin balances
- Continue Reading button
- Current Plan button

### Bible

`Features/Bible/BibleReaderView.swift`

Provides:

- Book and chapter selectors in the navigation bar
- Settings sheet for Bible language and text size
- Scrollable verse list
- Previous/next chapter buttons
- Mark Read / Mark Unread button
- Reward feedback alerts

### Profile

`Features/Profile/ProfileView.swift`

Currently includes appearance selection:

- System
- Light
- Dark

## Persistence

The app uses SwiftData. The model container is registered in `scripturedApp.swift` with:

- `ReadingSession`
- `UserStats`
- `RewardTransaction`
- `StreakState`

Reader position is stored in `UserDefaults` from `BibleReaderViewModel`:

- `bibleReader.language`
- `bibleReader.bookAbbrev`
- `bibleReader.chapterNumber`

Appearance mode is stored in `AppStorage` key:

- `appearanceMode`

## Important Models

### ReadingSession

Stores completed reading sessions:

- `id`
- `date`
- `bibleLanguage`
- `bookAbbrev`
- `bookName`
- `chapterIndex`
- `xpEarned`
- `coinsEarned`

### UserStats

Stores gamification totals:

- `totalXP`
- `currentLevel`
- `coins`
- `lifetimeCoins`
- `lastUpdated`

### RewardTransaction

Prevents reward farming:

- `rewardKey`
- `rewardType`
- `xpAwarded`
- `coinsAwarded`
- `createdAt`

Chapter reward keys use:

```text
chapter:{language}:{bookAbbrev}:{chapterIndex}
```

### StreakState

Stores streak metadata:

- `currentStreak`
- `longestStreak`
- `streakFreezesAvailable`
- `consumedFreezeDates`
- `lastEvaluatedAt`

## Services

### BibleService

Loads Bible books, chapters, and verses from bundled JSON.

### ReadingProgressService

Saves reading sessions, checks whether chapters were completed today, fetches sessions, and calculates reading counts.

### ProgressionService

Handles XP, levels, coins, level-up rewards, and reward claiming.

Level curve:

```text
XP required for next level = 100 + level * 50
```

Level-up reward:

```text
100 coins
```

### StreakService

Calculates:

- Current streak
- Longest streak
- Whether reading is complete today
- Whether streak is at risk
- Whether a freeze should be consumed
- Number of freezes available

## Validation

Most recent validation performed with Xcode build tools:

- Project builds successfully.
- Bible JSON decoding verified for English and Chinese.
- Reward exploit checks verified with in-memory SwiftData snippets.
- Streak behavior verified with in-memory SwiftData snippets.

## Known Gaps

- There is currently no test target in the active Xcode scheme.
- Plans, Shop, and Profile are still mostly placeholder features.
- Streak freeze earning/purchasing is not implemented yet.
- Reading plans are not connected to Bible reading progress yet.
- WidgetKit and Sign in with Apple are scaffolded conceptually but not implemented.
