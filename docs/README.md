# Scriptured Internal README

Scriptured is a SwiftUI iOS Bible reading habit app. It is local-first, uses bundled offline Bible and reading-plan JSON resources, and layers habit-building mechanics on top of daily reading: streaks, XP, levels, coins, plan progress, and reward claiming.

This README is technical project context for contributors/Codex sessions. The root `README.md` is the more public GitHub-facing overview.

## Current Features

- Offline Bible reader using bundled JSON files:
  - `Resources/Bible/en_bbe.json`
  - `Resources/Bible/zh_cuv.json`
- English and Chinese Bible language switching.
- Book and chapter navigation with previous/next chapter controls.
- Reader position persistence with `UserDefaults`.
- Daily read/unread state backed by SwiftData `ReadingSession` rows.
- Reward exploit protection using persistent `RewardTransaction` rows.
- XP, levels, coins, and lifetime coins.
- Streak tracking with at-risk state and streak freezes.
- Gamified green/beige design system with reusable SwiftUI components.
- Home dashboard with streak, XP, coins, daily goal, chapter count, and current plan card.
- Local reading plans loaded from bundled JSON files in `Resources/ReadingPlans`.
- Reading plan selection, unselection, saved progress, current-day assignment, and plan-day rewards.
- App appearance setting: System, Light, Dark.

## App Structure

```text
scriptured/
  App/                    App shell, environment, tab navigation, appearance mode, activity signal
  App/DesignSystem/       Theme, cards, buttons, status/reward UI components
  Features/               SwiftUI feature screens
  Models/                 SwiftData models and domain models
  Resources/Bible/        Bundled offline Bible JSON files
  Resources/ReadingPlans/ Bundled local reading plan JSON files
  Services/               Local-first Bible, progression, streak, reading plan, and persistence services
  ViewModels/             Observable view models
  docs/                   Project and Codex handoff documentation
```

## Core Screens

### Home

`Features/Home/HomeView.swift`

Shows the gamified dashboard:

- Dashboard header
- Large streak hero card
- Protect/read call to action
- Current plan card
- XP progress and current level
- Coin balance
- Daily goal progress
- Chapters read out of total Bible chapters
- Daily goals completed tally

The current plan card shows today’s selected plan assignment. If no plan is selected, it prompts the user to browse Plans.

### Bible

`Features/Bible/BibleReaderView.swift`

Provides:

- Book and chapter selectors in the navigation bar
- Settings sheet for Bible language and text size
- Scrollable verse list
- Previous/next chapter buttons
- Complete Chapter / Mark Unread button
- Reward feedback banner
- Integration with reading plan progress when the current chapter matches today’s assignment

### Plans

`Features/Plans/PlansView.swift`

Provides:

- Local reading plans loaded from bundled JSON
- Selected Plan and Other Plans sections
- Plan detail screen with description, duration, and daily reading list
- Select saved/new plan
- Unselect selected plan
- Persistent progress per plan

### Profile / Shop

`ProfileView` currently includes appearance selection. `ShopView` is themed but still mostly scaffolded.

## Persistence

The app uses SwiftData. The model container is registered in `scripturedApp.swift` with:

- `ReadingSession`
- `UserStats`
- `RewardTransaction`
- `StreakState`
- `UserReadingPlan`
- `UserReadingPlanDayProgress`

Stored keys:

```text
appearanceMode
bibleReader.language
bibleReader.bookAbbrev
bibleReader.chapterNumber
readingPlan.selectedPlanId
readingActivity.revision
```

`ReadingActivitySignal` increments `readingActivity.revision` after completion/selection events so tabs can refresh shared dashboard state.

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

Prevents reward farming. Reward key formats:

```text
chapter:{language}:{bookAbbrev}:{chapterIndex}
planDay:{planId}:{dayNumber}
```

### ReadingPlanFile

Codable model for bundled plan JSON:

- `data: [String]`
- `data2: [[String]]`
- `id: String` decoded from string or int
- `abbv`
- `name`
- `info`

### UserReadingPlan / UserReadingPlanDayProgress

SwiftData models for selected plan state, current day, completed day numbers, completed reading keys, and per-day completion status.

## Services

### BibleService

Loads Bible books, chapters, and verses from bundled JSON.

### ReadingProgressService

Saves reading sessions, checks whether chapters were completed today, fetches sessions, and calculates reading counts. It updates an existing same-day chapter session if a later save has higher XP/coin values.

### ProgressionService

Handles XP, levels, coins, level-up rewards, and reward claiming.

```text
XP required for next level = 100 + level * 50
chapter reward = 10 XP + 1 coin
plan day reward = 25 XP + 5 coins
level-up reward = 100 coins
```

### StreakService

Calculates current streak, longest streak, whether reading is complete today, whether streak is at risk, whether a freeze should be consumed, and freezes available.

### ReadingPlanService

Loads all JSON files from `Resources/ReadingPlans`, decodes `ReadingPlanFile`, selects/unselects plans, restores active plan state, computes today’s assignment, parses reading references, and marks daily plan progress complete.

## Design System

Design system files are under `App/DesignSystem`:

- `AppTheme.swift`
- `GameButtons.swift`
- `GameCard.swift`
- `GameStatusComponents.swift`

Reusable components include:

- `GameCard`
- `PrimaryGameButton`
- `SecondaryGameButton`
- `StreakHeroCard`
- `XPProgressBar`
- `CoinBalancePill`
- `LevelBadge`
- `RewardBanner`
- `EmptyStateView`

The intended visual direction is warm green/beige, playful but respectful, with Dynamic Type-friendly text and dark mode aware colors.

## Validation

Most recent validation performed with Xcode tools:

- Project builds successfully.
- Chapter completion, plan completion, rewards, streaks, daily goals, selected plan card, and reader completed-button state have been reported resolved in the running app.
- In-memory SwiftData snippets previously confirmed the service/view model completion path can save chapter reward, session, and streak state in isolation.

## Known Gaps

- There is currently no test target in the active Xcode scheme.
- Shop is placeholder; no economy spend loop exists.
- Profile only has theme setting.
- Sign in with Apple and WidgetKit are scaffolded conceptually but not implemented.
- Streak freeze acquisition is not implemented.
