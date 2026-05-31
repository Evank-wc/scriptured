# Codex Handoff: Scriptured

This document is for the next Codex session. Assume no prior conversation context.

## Project Summary

Scriptured is a SwiftUI iOS app for Bible reading habits. It uses a local-first architecture, bundled offline Bible JSON, bundled local reading-plan JSON, SwiftData persistence, a gamified green/beige design system, streak tracking, XP, levels, coins, and plan progress.

The recent button/tracking regression has been resolved. Chapter completion and plan completion now register in the running app and update rewards, streaks, daily goals, plan progress, and dashboard state.

Keep changes scoped and avoid broad rewrites.

## Current Architecture

The app uses SwiftUI + MVVM + service layer.

Important folders:

```text
scriptured/scriptured/App
scriptured/scriptured/App/DesignSystem
scriptured/scriptured/Features
scriptured/scriptured/Models
scriptured/scriptured/Services
scriptured/scriptured/ViewModels
scriptured/scriptured/Resources/Bible
scriptured/scriptured/Resources/ReadingPlans
scriptured/docs
```

`scripturedApp.swift` registers the SwiftData model container. If adding a SwiftData model, add it there.

Current registered SwiftData models:

- `ReadingSession`
- `UserStats`
- `RewardTransaction`
- `StreakState`
- `UserReadingPlan`
- `UserReadingPlanDayProgress`

## Navigation

`App/MainTabView.swift` owns stable view model instances using `@State` so tab switching should not recreate the Bible reader.

Tabs:

- Home
- Bible
- Plans
- Shop
- Profile

Home navigation actions:

- Main read CTA -> Bible tab
- Browse Plans -> Plans tab
- Read Assigned Chapter -> opens a parsed `PlanReadingReference` in `BibleReaderViewModel` and switches to Bible

`MainTabView` configures shared view models with services using the SwiftUI environment `modelContext` and listens to `ReadingActivitySignal` to refresh cross-tab state.

## Design System

Files:

- `App/DesignSystem/AppTheme.swift`
- `App/DesignSystem/GameButtons.swift`
- `App/DesignSystem/GameCard.swift`
- `App/DesignSystem/GameStatusComponents.swift`

Reusable components:

- `GameCard`
- `PrimaryGameButton`
- `SecondaryGameButton`
- `StreakHeroCard`
- `XPProgressBar`
- `CoinBalancePill`
- `LevelBadge`
- `RewardBanner`
- `EmptyStateView`

The design direction is warm green/beige, playful but respectful, with dark-mode aware colors. Reference `docs/DESIGN_BRIEF.md` before large UI changes.

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
- `Complete Chapter` / `Mark Unread` toggles daily read state.
- Reader position persists through `UserDefaults`.
- Completing a chapter calls `ProgressionService.claimChapterCompletionReward`, then `ReadingProgressService.saveCompletedReadingSession`, then optionally `ReadingPlanService.markReadingComplete` if the chapter is part of today’s selected plan.

Reader state keys:

```text
bibleReader.language
bibleReader.bookAbbrev
bibleReader.chapterNumber
```

Read/unread state is separate from reward claim state. Marking unread deletes today’s `ReadingSession` only; it must not delete `RewardTransaction`.

## Offline Bible JSON

Files:

- `Resources/Bible/en_bbe.json`
- `Resources/Bible/zh_cuv.json`

Actual JSON shape may not include a `book` name field, only `abbrev` and `chapters`. Book display names are mapped in `BibleBookNameProvider` inside `Models/BibleModels.swift`.

Known abbreviation details:

- Genesis uses `gn`
- Judges uses `jud`
- Revelation uses `re`

## Reading Plans

Files:

- `Resources/ReadingPlans/21dayhabitstarter.json`
- `Resources/ReadingPlans/60daygospelplan.json`
- `Resources/ReadingPlans/esveverydayinword.json`
- `Resources/ReadingPlans/esvthroughthebible.json`
- `Resources/ReadingPlans/fivebooksofmoses.json`
- `Resources/ReadingPlans/oneyearchronological.json`
- `Resources/ReadingPlans/psalmsproverbsstarter.json`

Plan JSON shape:

```json
{
  "data": ["display reading strings"],
  "data2": [["structured reading strings"]],
  "id": "string or int",
  "abbv": "short label",
  "name": "plan name",
  "info": "description"
}
```

`Models/ReadingPlan.swift` includes:

- `ReadingPlanFile`
- `PlanReadingReference`
- `UserReadingPlan`
- `UserReadingPlanDayProgress`

`Services/ReadingPlanService.swift` handles:

- loading/decoding all bundled plans
- selecting/unselecting plans
- restoring active plan state from `UserDefaults`
- calculating today’s plan day from start date
- parsing plan readings into Bible book/chapter references
- marking individual plan readings complete
- marking today’s plan complete

Selected plan id key:

```text
readingPlan.selectedPlanId
```

Plan-day reward key format:

```text
planDay:{planId}:{dayNumber}
```

Plan-day reward amount:

```text
25 XP + 5 coins
```

## Reading Progress

Files:

- `Models/ReadingSession.swift`
- `Services/ReadingProgressService.swift`

Reading sessions represent daily completed chapters. Marking unread deletes today’s `ReadingSession` for that chapter only.

Methods include:

- save completed session
- check if chapter completed today
- fetch all sessions
- total chapters read
- today’s completed readings
- remove today’s completed session

Current implementation updates an existing same-day chapter session if a later save has higher `xpEarned` or `coinsEarned`.

## Reward / XP / Coins

Files:

- `Models/UserStats.swift`
- `Models/RewardTransaction.swift`
- `Services/ProgressionService.swift`

Rules:

- Marking a chapter read awards `10 XP` and `1 coin` only if the reward has never been claimed for that chapter and Bible language.
- Marking unread must not delete reward transactions.
- Marking read again after unread must not award XP/coins again.
- Completing today’s selected plan awards `25 XP` and `5 coins` once per plan day.
- Level-up reward is `100` coins.
- Level curve is `100 + level * 50` XP for next level.

Reward key examples:

```text
chapter:en:gn:1
chapter:zh:gn:1
planDay:21-day-habit-starter:1
```

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

- Dashboard header
- Large streak hero
- Main read/protect CTA
- Current plan card or no-plan prompt
- Today’s goal card
- XP progress and current level
- Coin balance
- Chapters read out of total Bible chapters
- Daily goals completed tally

`HomeViewModel.completeTodayPlan()` calls `ReadingPlanService.markTodayComplete`, sends `ReadingActivitySignal`, and reloads stats.

## Appearance / Dark Mode

Files:

- `App/AppearanceMode.swift`
- `ContentView.swift`
- `Features/Profile/ProfileView.swift`

Appearance is stored using:

```text
appearanceMode
```

Modes:

- System
- Light
- Dark

`ContentView` applies `.preferredColorScheme(...)` based on the stored mode.

## Validation Tools

Prefer Xcode MCP tools:

- `XcodeRefreshCodeIssuesInFile` for quick diagnostics
- `BuildProject` for full validation
- `ExecuteSnippet` for in-memory SwiftData checks

The active scheme currently has no tests.

Most recent state:

- Full project build succeeded after recent tracking wiring changes.
- The user confirmed the previous completion-button tracking bug is resolved.

## Known Gaps / Risks

- No test target exists. If the user asks for unit tests, a test target must be created in Xcode/project settings first.
- Shop is placeholder; no economy spend loop exists.
- Profile only has theme setting.
- No sign-in implementation yet.
- No WidgetKit target yet.
- Streak freeze acquisition is not implemented.
- Reading sessions are daily read state; reward transactions are permanent claim state. Do not merge these concepts.
- Reading plan parsing is string-based and depends on `BookAlias` mappings inside `ReadingPlanService`.

## Style Notes

- Keep UI practical, mobile-friendly, and consistent with the green/beige design system.
- Avoid large unrelated refactors.
- Prefer adding small services/view models over putting persistence logic directly into SwiftUI views.
- Use SwiftData through `ModelContext` injected from SwiftUI environment.
- Use Xcode MCP tools first when working from Xcode.

## Common Pitfalls

- Do not recreate `BibleReaderViewModel` inside `TabView.body`; that causes reader state resets when switching tabs.
- Do not award rewards directly from read-session saves; always go through `ProgressionService.claimChapterCompletionReward` or `claimPlanDayCompletionReward`.
- Do not delete `RewardTransaction` when marking unread.
- Do not assume Bible JSON contains `book`; it may not.
- Do not use `rv` for Revelation; this dataset uses `re`.
- Do not use `judg` only for Judges; this dataset uses `jud`.
- Do not create placeholder reading plans when real bundled JSON exists.
