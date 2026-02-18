import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @State private var activeSession: WorkoutSession?

    var body: some View {
        TabView {
            HistoryView(onStartWorkout: startWorkout)
                .tabItem { Label("History", systemImage: "clock.fill") }

            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "dumbbell.fill") }
        }
        .fullScreenCover(item: $activeSession) { session in
            ActiveWorkoutView(session: session, onDismiss: { activeSession = nil })
        }
        .task {
            if exercises.isEmpty { seedExercises() }
        }
    }

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

    private func seedExercises() {
        for (name, category) in Exercise.seedData {
            modelContext.insert(Exercise(name: name, category: category))
        }
    }
}
