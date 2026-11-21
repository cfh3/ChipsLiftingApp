import SwiftUI
import SwiftData

/// App entry point.
///
/// Sets up the SwiftData model container for all three persistent model types.
/// The container is shared across the entire view hierarchy via the environment,
/// making `@Environment(\.modelContext)` and `@Query` available in any child view.
@main
struct LiftingApp: App {
    /// Built once at launch. UI tests pass `-ui-testing` to get an in-memory
    /// store, so every test run starts empty and never touches real data.
    private let container: ModelContainer

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        let config = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        do {
            // Register all SwiftData models so they are included in the same
            // store and can form cross-model relationships.
            container = try ModelContainer(
                for: Exercise.self, WorkoutSession.self, WorkoutSet.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
