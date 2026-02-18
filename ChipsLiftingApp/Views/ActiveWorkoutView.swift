import SwiftUI
import SwiftData

/// Transient value type that tracks the UI state for one exercise during
/// an active workout — specifically the pending weight/reps inputs for the
/// next set about to be logged.
///
/// This is kept separate from `WorkoutSet` (the persisted model) so that
/// partially-typed inputs don't touch the database until the user confirms.
struct ExerciseEntry: Identifiable {
    let id = UUID()

    /// Exercise name, mirrored from the selected `Exercise` object.
    let name: String

    /// Category, mirrored so `WorkoutSet` can be created without re-fetching
    /// the `Exercise` from the store.
    let category: ExerciseCategory

    /// Weight input string bound to the text field. Validated as a `Double`
    /// before a set is saved.
    var pendingWeight: String = ""

    /// Reps input string bound to the text field. Validated as a positive
    /// `Int` before a set is saved.
    var pendingReps: String = ""
}

/// Full-screen view for logging a workout in real time.
///
/// Presents a scrollable list of `ExerciseBlockView` cards — one per exercise
/// added to the workout. The user can:
/// - Add exercises via the `ExercisePickerView` sheet.
/// - Log sets by entering weight/reps and tapping the checkmark.
/// - Delete individual sets with the minus button.
/// - Finish the workout (sets `endedAt` and dismisses) or discard it
///   (deletes the session entirely).
///
/// A live elapsed-time counter is shown in the navigation bar title area,
/// driven by a Swift Concurrency `Task` that increments every second.
struct ActiveWorkoutView: View {
    /// The SwiftData session object created in `ContentView.startWorkout()`.
    /// SwiftData's `@Observable` conformance means reading `session.sets`
    /// in the view body automatically re-renders when sets change.
    let session: WorkoutSession

    /// Called after the session is finished or discarded so `ContentView`
    /// can clear `activeSession` and dismiss the full-screen cover.
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext

    /// Ordered list of exercises added to this workout, with their pending
    /// input state. Order is preserved in insertion order (matches the
    /// order exercises appear on screen).
    @State private var entries: [ExerciseEntry] = []

    @State private var showingPicker = false
    @State private var showingDiscardAlert = false

    /// Seconds elapsed since the workout started, incremented by the async timer task.
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // One card per exercise in the workout
                    ForEach($entries) { $entry in
                        ExerciseBlockView(
                            entry: $entry,
                            completedSets: setsFor(entry.name),
                            onAddSet: { addSet(for: entry.name) },
                            onDeleteSet: deleteSet
                        )
                    }

                    // Full-width button to open the exercise picker sheet
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
                // Left: destructive discard action
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { showingDiscardAlert = true }
                        .foregroundStyle(.red)
                }
                // Center: live elapsed timer
                ToolbarItem(placement: .principal) {
                    Text(formatTime(elapsed))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                // Right: finish — disabled until at least one set is logged
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") { finishWorkout() }
                        .fontWeight(.semibold)
                        .disabled(session.sets.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            // Pass existing exercise names so the picker hides already-added exercises
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
        // Async timer: increments `elapsed` every second until the task is
        // cancelled (which happens automatically when the view disappears).
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                    elapsed += 1
                } catch {
                    break  // Task.sleep throws CancellationError when cancelled
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns the completed sets for `name`, sorted by set number.
    /// Reads directly from `session.sets` which is kept live by SwiftData.
    private func setsFor(_ name: String) -> [WorkoutSet] {
        session.sets.filter { $0.exerciseName == name }.sorted { $0.setNumber < $1.setNumber }
    }

    // MARK: - Actions

    /// Appends an `ExerciseEntry` for the selected exercise if it isn't
    /// already present in the workout (guard prevents duplicates).
    private func addExercise(_ exercise: Exercise) {
        guard !entries.contains(where: { $0.name == exercise.name }) else { return }
        entries.append(ExerciseEntry(name: exercise.name, category: exercise.category))
    }

    /// Validates the pending inputs for `name`, creates a `WorkoutSet`, and
    /// inserts it into the model context. Clears the input fields on success.
    ///
    /// Set number is derived from the current count of completed sets so it
    /// increments automatically (1, 2, 3 …) as the user logs more sets.
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

        // Clear inputs so the user is ready to log the next set
        if let idx = entries.firstIndex(where: { $0.name == name }) {
            entries[idx].pendingWeight = ""
            entries[idx].pendingReps = ""
        }
    }

    /// Removes a logged set from the model context.
    /// SwiftData automatically updates `session.sets` via the inverse relationship.
    private func deleteSet(_ set: WorkoutSet) {
        modelContext.delete(set)
    }

    /// Marks the session as finished and dismisses the view.
    private func finishWorkout() {
        session.endedAt = .now
        onDismiss()
    }

    /// Deletes the entire session (and all its sets via cascade) and dismisses.
    private func discardWorkout() {
        modelContext.delete(session)
        onDismiss()
    }

    /// Formats a `TimeInterval` as `M:SS` (under an hour) or `H:MM:SS`.
    private func formatTime(_ t: TimeInterval) -> String {
        let s = Int(t)
        return s >= 3600
            ? String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
            : String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// A card representing one exercise within the active workout.
///
/// Shows:
/// - The exercise name as a header.
/// - A table of already-logged sets (set number, weight, reps) with per-row
///   delete buttons.
/// - An input row for the next set: weight field, reps field, and a confirm
///   button that activates only when both inputs are valid.
struct ExerciseBlockView: View {
    /// Two-way binding to the entry's pending input fields so text field
    /// changes update the parent's state directly.
    @Binding var entry: ExerciseEntry

    /// Sets already saved for this exercise in the current session, sorted
    /// by set number. Passed in from `ActiveWorkoutView` so this view stays
    /// a pure rendering component.
    let completedSets: [WorkoutSet]

    /// Called when the confirm button is tapped with valid inputs.
    let onAddSet: () -> Void

    /// Called with the set to remove when the minus button is tapped.
    let onDeleteSet: (WorkoutSet) -> Void

    /// `true` only when both the weight and reps fields contain valid, positive values.
    private var canAdd: Bool {
        Double(entry.pendingWeight) != nil &&
        Int(entry.pendingReps) != nil &&
        (Int(entry.pendingReps) ?? 0) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Exercise name header
            Text(entry.name)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            // Completed sets table — hidden when no sets have been logged yet
            if !completedSets.isEmpty {
                // Column headers
                HStack {
                    Text("Set").frame(width: 36, alignment: .leading)
                    Text("Weight").frame(maxWidth: .infinity, alignment: .center)
                    Text("Reps").frame(width: 60, alignment: .center)
                    Spacer().frame(width: 28) // aligns with delete button column
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // One row per completed set
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

            // Input row for the next set
            HStack(spacing: 8) {
                // Label shows the upcoming set number (completed count + 1)
                Text("Set \(completedSets.count + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 54, alignment: .leading)

                // Weight input — decimal pad for values like 135.5
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

                // Reps input — number pad for whole numbers only
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

                // Confirm button — green when inputs are valid, grey otherwise
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
