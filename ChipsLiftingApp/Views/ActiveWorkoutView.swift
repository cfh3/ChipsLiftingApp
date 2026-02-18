import SwiftUI
import SwiftData

struct ExerciseEntry: Identifiable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    var pendingWeight: String = ""
    var pendingReps: String = ""
}

struct ActiveWorkoutView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var entries: [ExerciseEntry] = []
    @State private var showingPicker = false
    @State private var showingDiscardAlert = false
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach($entries) { $entry in
                        ExerciseBlockView(
                            entry: $entry,
                            completedSets: setsFor(entry.name),
                            onAddSet: { addSet(for: entry.name) },
                            onDeleteSet: deleteSet
                        )
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top, 8)
            }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { showingDiscardAlert = true }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .principal) {
                    Text(formatTime(elapsed))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") { finishWorkout() }
                        .fontWeight(.semibold)
                        .disabled(session.sets.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView(existingNames: Set(entries.map(\.name))) { exercise in
                addExercise(exercise)
            }
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { discardWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All logged sets will be deleted.")
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                    elapsed += 1
                } catch {
                    break
                }
            }
        }
    }

    private func setsFor(_ name: String) -> [WorkoutSet] {
        session.sets.filter { $0.exerciseName == name }.sorted { $0.setNumber < $1.setNumber }
    }

    private func addExercise(_ exercise: Exercise) {
        guard !entries.contains(where: { $0.name == exercise.name }) else { return }
        entries.append(ExerciseEntry(name: exercise.name, category: exercise.category))
    }

    private func addSet(for name: String) {
        guard let entry = entries.first(where: { $0.name == name }),
              let weight = Double(entry.pendingWeight),
              let reps = Int(entry.pendingReps), reps > 0 else { return }

        let set = WorkoutSet(
            exerciseName: name,
            exerciseCategory: entry.category,
            weight: weight,
            reps: reps,
            setNumber: setsFor(name).count + 1
        )
        set.session = session
        modelContext.insert(set)

        if let idx = entries.firstIndex(where: { $0.name == name }) {
            entries[idx].pendingWeight = ""
            entries[idx].pendingReps = ""
        }
    }

    private func deleteSet(_ set: WorkoutSet) {
        modelContext.delete(set)
    }

    private func finishWorkout() {
        session.endedAt = .now
        onDismiss()
    }

    private func discardWorkout() {
        modelContext.delete(session)
        onDismiss()
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let s = Int(t)
        return s >= 3600
            ? String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
            : String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct ExerciseBlockView: View {
    @Binding var entry: ExerciseEntry
    let completedSets: [WorkoutSet]
    let onAddSet: () -> Void
    let onDeleteSet: (WorkoutSet) -> Void

    private var canAdd: Bool {
        Double(entry.pendingWeight) != nil &&
        Int(entry.pendingReps) != nil &&
        (Int(entry.pendingReps) ?? 0) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.name)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            if !completedSets.isEmpty {
                HStack {
                    Text("Set").frame(width: 36, alignment: .leading)
                    Text("Weight").frame(maxWidth: .infinity, alignment: .center)
                    Text("Reps").frame(width: 60, alignment: .center)
                    Spacer().frame(width: 28)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ForEach(completedSets) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .frame(width: 36, alignment: .leading)
                            .foregroundStyle(.secondary)
                        Text("\(set.displayWeight) lbs")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.medium)
                        Text("\(set.reps)")
                            .frame(width: 60, alignment: .center)
                        Button {
                            onDeleteSet(set)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                Divider()
                    .padding(.top, 4)
            }

            // Input row for next set
            HStack(spacing: 8) {
                Text("Set \(completedSets.count + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 54, alignment: .leading)

                TextField("0", text: $entry.pendingWeight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .trailing) {
                        Text("lbs")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.trailing, 4)
                    }

                TextField("0", text: $entry.pendingReps)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 80)
                    .overlay(alignment: .trailing) {
                        Text("reps")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.trailing, 4)
                    }

                Button(action: onAddSet) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canAdd ? .green : Color(.systemGray4))
                }
                .disabled(!canAdd)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
