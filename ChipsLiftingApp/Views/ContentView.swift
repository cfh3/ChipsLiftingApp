import SwiftUI
import SwiftData

/// Root view of the app. Owns the two-tab navigation and manages the
/// lifecycle of the currently active workout session.
///
/// Responsibilities:
/// - Render the History and Exercises tabs.
/// - Create a new `WorkoutSession` and present `ActiveWorkoutView` as a
///   full-screen cover when the user starts a workout.
/// - Seed the exercise library on first launch.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    /// The currently active workout session, if any. Presenting a non-nil
    /// value triggers the full-screen cover for `ActiveWorkoutView`.
    /// Set back to `nil` when the user finishes or discards the workout.
    @State private var activeSession: WorkoutSession?

    var body: some View {
        TabView {
            // Tab 1: chronological workout history with a start button
            HistoryView(onStartWorkout: startWorkout)
                .tabItem { Label("History", systemImage: "clock.fill") }

            // Tab 2: browseable exercise library with add/delete support
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "dumbbell.fill") }
        }
        // Present the active workout as a full-screen cover so it sits above
        // the tab bar. Dismissed by setting activeSession back to nil.
        .fullScreenCover(item: $activeSession) { session in
            ActiveWorkoutView(session: session, onDismiss: { activeSession = nil })
        }
        // Seed the exercise library once on first launch.
        // Uses a one-off fetch count rather than @Query so inserting seed data
        // doesn't cause ContentView to re-render (which would reset
        // ActiveWorkoutView's @State and collapse any open sheets).
        .task {
            let count = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
            if count == 0 { seedExercises() }
        }
    }

    /// Creates a new `WorkoutSession`, inserts it into the model context,
    /// and presents `ActiveWorkoutView` by assigning it to `activeSession`.
    ///
    /// The session name is chosen based on the current hour so the default
    /// label reflects when the workout took place.
    private func startWorkout() {
        let hour = Calendar.current.component(.hour, from: .now)
        let name: String
        switch hour {
        case 5..<12: name = "Morning Workout"
        case 12..<17: name = "Afternoon Workout"
        case 17..<21: name = "Evening Workout"
        default: name = "Night Workout"
        }
        let session = WorkoutSession(name: name)
        modelContext.insert(session)
        activeSession = session
    }

    /// Inserts all entries from `Exercise.seedData` into the model context.
    /// Called once when the app is launched and the exercise library is empty.
    private func seedExercises() {
        for (name, category) in Exercise.seedData {
            modelContext.insert(Exercise(name: name, category: category))
        }
    }
}
