import SwiftUI
import SwiftData

/// App entry point.
///
/// Sets up the SwiftData model container for all three persistent model types.
/// The container is shared across the entire view hierarchy via the environment,
/// making `@Environment(\.modelContext)` and `@Query` available in any child view.
@main
struct LiftingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Register all SwiftData models so they are included in the same
        // SQLite store and can form cross-model relationships.
        .modelContainer(for: [Exercise.self, WorkoutSession.self, WorkoutSet.self])
    }
}
