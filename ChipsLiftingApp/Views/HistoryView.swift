import SwiftUI
import SwiftData

struct HistoryView: View {
    let onStartWorkout: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
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

struct WorkoutRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name.isEmpty ? "Workout" : session.name)
                    .font(.headline)
                Spacer()
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
