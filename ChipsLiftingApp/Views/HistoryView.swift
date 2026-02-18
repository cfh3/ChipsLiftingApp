import SwiftUI
import SwiftData

/// Displays the user's workout history in reverse-chronological order.
///
/// Shows an empty state with a call-to-action when no workouts exist,
/// otherwise renders a list of `WorkoutRowView` cells. Each row navigates
/// to `WorkoutDetailView`. Rows can be deleted via swipe-to-delete.
struct HistoryView: View {
    /// Called when the user taps the "+" button or the empty-state CTA.
    /// Defined in `ContentView` so session creation stays at the root level.
    let onStartWorkout: () -> Void

    @Environment(\.modelContext) private var modelContext

    /// All sessions sorted newest-first. SwiftData re-runs this query
    /// automatically whenever the underlying store changes.
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    // Empty state — shown on first launch before any workouts exist
                    ContentUnavailableView {
                        Label("No Workouts", systemImage: "dumbbell")
                    } description: {
                        Text("Start your first workout to begin tracking.")
                    } actions: {
                        Button("Start Workout", action: onStartWorkout)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(destination: WorkoutDetailView(session: session)) {
                                WorkoutRowView(session: session)
                            }
                        }
                        // Swipe-to-delete removes the session and all its sets
                        // (cascade delete is defined on the model relationship).
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(sessions[i]) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onStartWorkout) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

/// A single row in the history list summarising one workout session.
///
/// Shows the session name, date, and — when sets exist — exercise count,
/// total volume, and duration. An "Active" badge is shown for sessions
/// that were never finished (e.g. after a force-quit).
struct WorkoutRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name.isEmpty ? "Workout" : session.name)
                    .font(.headline)
                Spacer()
                // Badge shown for in-progress sessions that have at least one set,
                // so abandoned empty sessions don't clutter the UI with the badge.
                if session.isActive && !session.sets.isEmpty {
                    Text("Active")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            // Stats row — only shown when there is data to display
            if !session.sets.isEmpty {
                HStack(spacing: 12) {
                    Label("\(session.uniqueExercises.count) exercises", systemImage: "list.bullet")
                    Label("\(Int(session.totalVolume)) lbs", systemImage: "scalemass.fill")
                    if let dur = session.formattedDuration {
                        Label(dur, systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
