# Scriptured

Scriptured is a Bible reading habit app for iOS. It is designed to make daily Scripture reading feel clear, encouraging, and a little more fun.

The app combines an offline Bible reader with habit-building features like streaks, reading plans, XP, levels, and coins. The goal is simple: help users open the Bible consistently and keep going one day at a time.

## What It Does

- Read the Bible offline from bundled Bible files.
- Switch between English and Chinese Bible text.
- Choose a local reading plan and follow today's assignment.
- Mark chapters and plan readings as complete.
- Build a daily reading streak.
- Earn XP and coins for completed reading.
- Track level progress, chapters read, and daily goals.
- Use a warm green/beige interface with light and dark mode support.

## Main Screens

### Dashboard

The Home tab is the main habit dashboard. It shows the current streak, today's goal, XP progress, coin balance, chapters read, and the selected reading plan.

### Bible Reader

The Bible tab lets users choose a book and chapter, adjust text size, switch language, move between chapters, and mark a chapter as complete.

### Reading Plans

The Plans tab lists bundled reading plans, including shorter starter plans and longer Bible reading plans. Users can select or unselect a plan, and progress is saved.

### Profile

The Profile tab currently includes appearance settings for System, Light, and Dark mode.

## Current Reading Plans

The app currently includes bundled JSON reading plans such as:

- 21-Day Habit Starter
- 60-Day Gospel Plan
- Psalms & Proverbs Starter
- The Five Books of Moses
- One Year Chronological
- ESV Through the Bible
- ESV Every Day in the Word

## Tech Stack

- SwiftUI
- SwiftData
- Local bundled JSON resources
- MVVM-style view models
- Service layer for Bible loading, reading progress, rewards, streaks, and reading plans

## Project Structure

```text
scriptured/
  scriptured/
    App/
    App/DesignSystem/
    Features/
    Models/
    Resources/
    Services/
    ViewModels/
  docs/
```

## Running the App

1. Open the project in Xcode.
2. Select the `scriptured` app scheme.
3. Choose an iOS simulator or connected device.
4. Build and run.

The app is local-first and does not require a network connection for the bundled Bible text or bundled reading plans.

## Project Status

Scriptured is in active development. The core Bible reader, dashboard, reading plans, streaks, XP, coins, and daily goal tracking are implemented. Shop, widgets, sign-in, achievements, and deeper profile features are still future work.

## Notes

This is a personal app project and is not affiliated with any Bible publisher or third-party habit app. Bundled Bible and reading plan resources should be reviewed for licensing before public distribution.
