# Codex Handoff: Scriptured

This document is for the next Codex session. Assume no prior conversation context.

## Project Summary

Scriptured is a SwiftUI iOS app for Bible reading habits. It currently has a local-first architecture, offline Bible JSON loading, SwiftData persistence, gamification, streak tracking, and a Home dashboard.

The user has been iterating mostly on the Bible reader and Home dashboard. Keep changes scoped and avoid broad rewrites.

## Current Architecture

The app uses SwiftUI + MVVM + service layer.

Important folders:

```text
scriptured/scriptured/App
scriptured/scriptured/Features
scriptured/scriptured/Models
scriptured/scriptured/Services
scriptured/scriptured/ViewModels
scriptured/scriptured/Resources/Bible
scriptured/docs
```

`scripturedApp.swift` registers the SwiftData model container. If adding a SwiftData model, add it there.

Current registered SwiftData models:

- `ReadingSession`
- `UserStats`
- `RewardTransaction`
- `StreakState`

## Navigation

`App/MainTabView.swift` owns stable view model instances using `@State` so tab switching does not recreate the Bible reader.

Tabs:

- Home
- Bible
- Plans
- Shop
- Profile

Home buttons switch tabs via `selectedTab`:

- Continue Reading -> Bible tab
- Current Plan -> Plans tab

## Bible Reader

Files:

- `Features/Bible/BibleReaderView.swift`
- `ViewModels/BibleReaderViewModel.swift`
- `Services/BibleService.swift`
- `Models/BibleModels.swift`

Behavior:

- Loads bundled Bible JSON from `Resources/Bible`.
- Supports English and Chinese.
- Book and chapter selectors are in the top navigation bar.
- Text size and language are in the settings sheet.
- Previous/next arrows are at the bottom.
- Mark Read / Mark Unread toggles daily read state.
- Reader position persists across tab switches and app launches via `UserDefaults`.

Reader state keys:

```text
bibleReader.language
bibleReader.bookAbbrev
bibleReader.chapterNumber
```

Important: read/unread state is separate from reward claim state.

## Offline Bible JSON

Files:

- `Resources/Bible/en_bbe.json`
- `Resources/Bible/zh_cuv.json`

Actual JSON shape does not include a `book` name field, only `abbrev` and `chapters`. Book display names are mapped in `BibleBookNameProvider` inside `Models/BibleModels.swift`.

Known abbreviation fixes already applied:

- Judges uses `jud`
- Revelation uses `re`

## Reading Progress

Files:

- `Models/ReadingSession.swift`
- `Services/ReadingProgressService.swift`

Reading sessions represent daily completed chapters. Marking unread deletes today's `ReadingSession` for that chapter only.

Methods include:

- save completed session
- check if chapter completed today
- fetch all sessions
- total chapters read
- today's completed readings
- remove today's completed session

## Reward / XP / Coins

Files:

- `Models/UserStats.swift`
- `Models/RewardTransaction.swift`
- `Services/ProgressionService.swift`

Rules:

- Marking a chapter read awards `10 XP` and `1 coin` only if the reward has never been claimed for that chapter and Bible language.
- Reward transaction key format:

```text
chapter:{language}:{bookAbbrev}:{chapterIndex}
```

Examples:

```text
chapter:en:gn:1
chapter:zh:gn:1
chapter:en:gn:2
```

- Marking unread must not delete reward transactions.
- Marking read again after unread must not award XP/coins again.
- Level-up reward is `100` coins.
- Level curve is `100 + level * 50` XP for next level.

## Streaks

Files:

- `Models/StreakState.swift`
- `Services/StreakService.swift`
- `Features/Home/StreakStatusCard.swift`

Rules:

- A streak increases when at least one reading is completed per day.
- If one day is missed and a freeze is available, consume one freeze and preserve the streak.
- If a day is missed without a freeze, the streak resets.
- Longest streak is tracked.

Default new `StreakState` currently starts with `1` freeze.

## Home Dashboard

Files:

- `Features/Home/HomeView.swift`
- `ViewModels/HomeViewModel.swift`
- `Features/Home/StreakStatusCard.swift`

Current Home shows:

- Large streak hero
- Aggressive but not shame-based copy
- Today's goal card
- XP progress
- Current level
- Coins and lifetime coins
- Continue Reading button
- Current Plan button

Copy examples currently used:

- `Your streak is safe for today.`
- `Your streak is at risk.`
- `Read now to protect your streak.`
- `Do not let your progress reset.`

## Appearance / Dark Mode

Files:

- `App/AppearanceMode.swift`
- `ContentView.swift`
- `Features/Profile/ProfileView.swift`

Appearance is stored using `@AppStorage("appearanceMode")`.

Modes:

- System
- Light
- Dark

`ContentView` applies `.preferredColorScheme(...)` based on the stored mode.

## Validation Commands / Tools

Prefer Xcode MCP tools:

- `XcodeRefreshCodeIssuesInFile` for quick diagnostics
- `BuildProject` for full validation
- `ExecuteSnippet` for in-memory SwiftData checks

The active scheme currently has no tests. `GetTestList` previously returned `0 tests`.

## Recent Validated Behaviors

- Project builds successfully after adding dark mode and Home dashboard.
- Bible reader restores persisted language/book/chapter.
- Level-up from Level 1 to 2 grants 100 coins.
- Reward exploit is blocked:
  - first read awards XP/coins
  - unread does not remove reward transaction
  - read again does not award XP/coins again
  - reward keys differ by language and chapter
- Streak service in-memory checks passed:
  - yesterday-only reading -> at risk
  - yesterday + today -> streak 2
  - two-days-ago with freeze -> freeze consumed, streak preserved

## Known Gaps / Risks

- No test target exists. If the user asks for unit tests, a test target must be created in Xcode/project settings first.
- Plans tab is placeholder and not connected to reading progress.
- Shop is placeholder; no economy spend loop exists.
- Profile only has theme setting.
- No sign-in implementation yet.
- No WidgetKit target yet.
- Streak freeze acquisition is not implemented.
- Reading sessions are daily read state; reward transactions are permanent claim state. Do not merge these concepts.

## Style Notes

- Keep UI practical and mobile-friendly.
- Existing visual style uses system grouped backgrounds, 8-point rounded rectangles, SF Symbols, and compact controls.
- Avoid large unrelated refactors.
- Prefer adding small services/view models over putting persistence logic directly into SwiftUI views.
- Use SwiftData through `ModelContext` injected from SwiftUI environment.

## Common Pitfalls

- Do not recreate `BibleReaderViewModel` inside `TabView.body`; that causes reader state resets when switching tabs.
- Do not award rewards directly from read-session saves; always go through `ProgressionService.claimChapterCompletionReward`.
- Do not delete `RewardTransaction` when marking unread.
- Do not assume Bible JSON contains `book`; it may not.
- Do not use `rv` for Revelation; this dataset uses `re`.
- Do not use `judg` only for Judges; this dataset uses `jud`.
