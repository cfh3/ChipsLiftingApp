# ChipsLiftingApp

An iOS workout tracking app built with SwiftUI and SwiftData.

## Features

- **Log workouts** — track exercises, sets, weight, and reps in real time
- **Workout history** — browse past sessions with total volume, duration, and exercise count
- **Exercise library** — 50+ pre-seeded exercises across 8 categories, with support for custom exercises
- **Live timer** — elapsed time displayed during active workouts
- **Dark mode** — full light and dark mode support

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Getting Started

1. Clone the repo
2. Open `ChipsLiftingApp.xcodeproj` in Xcode
3. Select a simulator or device and press **Cmd+R**

No dependencies or package setup required — the app uses only Apple frameworks (SwiftUI, SwiftData).

## Architecture

- **SwiftUI** for all views
- **SwiftData** for on-device persistence
- Models: `Exercise`, `WorkoutSession`, `WorkoutSet`

## Testing

Unit tests cover model logic (volume calculations, duration formatting, grouping, deduplication). Run with **Cmd+U** in Xcode.
