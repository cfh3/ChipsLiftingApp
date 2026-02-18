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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // One card per exercise in the workout
                    ForEach($entries) { $entry in
                        ExerciseBlockView(
                            entry: $entry,
                            session: session,
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
                // Center: live elapsed timer.
                // Owned by ElapsedTimerView so its per-second state changes
                // don't re-render ActiveWorkoutView (which would reset sheet state).
                ToolbarItem(placement: .principal) {
                    ElapsedTimerView()
                }
                // Right: finish — scoped to FinishButtonView so reading
                // session.sets.isEmpty doesn't re-render ActiveWorkoutView.
                ToolbarItem(placement: .primaryAction) {
                    FinishButtonView(session: session, action: finishWorkout)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            // Pass existing exercise names so the picker hides already-added exercises
            ExercisePickerView(existingNames: Set(entries.map(\.name))) { exercise, weight, reps in
                addExercise(exercise, weight: weight, reps: reps)
            }
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { discardWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All logged sets will be deleted.")
        }
    }

    // MARK: - Actions

    /// Adds an exercise block to the workout with weight and reps pre-filled.
    ///
    /// No sets are created yet — the user taps the checkmark to log each set
    /// individually. Pre-filling saves retyping the same values for every set.
    /// The guard prevents adding the same exercise twice.
    private func addExercise(_ exercise: Exercise, weight: Double, reps: Int) {
        guard !entries.contains(where: { $0.name == exercise.name }) else { return }
        let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(weight)
        entries.append(ExerciseEntry(
            name: exercise.name,
            category: exercise.category,
            pendingWeight: weightStr,
            pendingReps: String(reps)
        ))
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

        let existingCount = session.sets.filter { $0.exerciseName == name }.count
        let set = WorkoutSet(
            exerciseName: name,
            exerciseCategory: entry.category,
            weight: weight,
            reps: reps,
            setNumber: existingCount + 1
        )
        set.session = session
        modelContext.insert(set)

        // Clear inputs after logging so the row doesn't auto-prepare
        // the next set — the user fills in values when they're ready.
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

}

/// Self-contained elapsed-time display for the workout toolbar.
///
/// Owning `elapsed` here (rather than in `ActiveWorkoutView`) means the
/// per-second state change only re-renders this tiny view. `ActiveWorkoutView`
/// stays completely still, so its `.sheet` modifier is never re-evaluated and
/// the exercise-picker sheet hierarchy remains stable.
struct ElapsedTimerView: View {
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        Text(formatted)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
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

    private var formatted: String {
        let s = Int(elapsed)
        return s >= 3600
            ? String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
            : String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// Finish button for the workout toolbar.
///
/// Scoped to its own view so that reading `session.sets.isEmpty` only
/// re-renders this button, not `ActiveWorkoutView`.
struct FinishButtonView: View {
    let session: WorkoutSession
    let action: () -> Void

    var body: some View {
        Button("Finish", action: action)
            .fontWeight(.semibold)
            .disabled(session.sets.isEmpty)
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

    /// The workout session. Sets are read here (not in ActiveWorkoutView)
    /// so SwiftData changes only re-render this card, not the parent.
    let session: WorkoutSession

    /// Called when the confirm button is tapped with valid inputs.
    let onAddSet: () -> Void

    /// Called with the set to remove when the minus button is tapped.
    let onDeleteSet: (WorkoutSet) -> Void

    private var completedSets: [WorkoutSet] {
        session.sets
            .filter { $0.exerciseName == entry.name }
            .sorted { $0.setNumber < $1.setNumber }
    }

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
