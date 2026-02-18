import SwiftUI

/// Read-only detail view for a completed (or in-progress) workout session.
///
/// Displays a summary section with date, duration, total volume, and exercise
/// count, followed by one section per exercise showing each logged set.
/// Sets within each exercise are sorted by `setNumber` (ascending).
struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            // Top-level summary stats for the whole session
            Section("Summary") {
                LabeledContent("Date", value: session.date.formatted(date: .long, time: .shortened))
                // Duration is nil for active/unfinished sessions
                if let dur = session.formattedDuration {
                    LabeledContent("Duration", value: dur)
                }
                LabeledContent("Total Volume", value: "\(Int(session.totalVolume)) lbs")
                LabeledContent("Exercises", value: "\(session.uniqueExercises.count)")
            }

            // One section per exercise, in the order they were performed.
            // `groupedSets` on the model handles the ordering and grouping logic.
            ForEach(session.groupedSets, id: \.exercise) { group in
                Section(group.exercise) {
                    // Column header row
                    HStack {
                        Text("Set").frame(width: 36, alignment: .leading)
                        Text("Weight").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Reps").frame(width: 60, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // One row per set, sorted by setNumber within the group
                    ForEach(group.sets) { set in
                        HStack {
                            Text("\(set.setNumber)")
                                .frame(width: 36, alignment: .leading)
                                .foregroundStyle(.secondary)
                            Text("\(set.displayWeight) lbs")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(.medium)
                            Text("\(set.reps) reps")
                                .frame(width: 60, alignment: .trailing)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.name.isEmpty ? "Workout" : session.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
