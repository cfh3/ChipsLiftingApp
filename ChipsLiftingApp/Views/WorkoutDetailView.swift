import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Date", value: session.date.formatted(date: .long, time: .shortened))
                if let dur = session.formattedDuration {
                    LabeledContent("Duration", value: dur)
                }
                LabeledContent("Total Volume", value: "\(Int(session.totalVolume)) lbs")
                LabeledContent("Exercises", value: "\(session.uniqueExercises.count)")
            }

            ForEach(session.groupedSets, id: \.exercise) { group in
                Section(group.exercise) {
                    HStack {
                        Text("Set").frame(width: 36, alignment: .leading)
                        Text("Weight").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Reps").frame(width: 60, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
