import SwiftUI
import SwiftData

/// Modal sheet for selecting an exercise to add to the active workout.
///
/// Tapping an exercise presents `ExerciseSetupView` as a child sheet where
/// the user configures sets, weight, and reps. On confirmation, `onSelect`
/// is called and both sheets are dismissed together.
struct ExercisePickerView: View {
    /// Names of exercises already in the workout — hidden from the list
    /// so the user can't add the same exercise twice.
    let existingNames: Set<String>

    /// Called with the chosen exercise and its default weight/reps when confirmed.
    let onSelect: (Exercise, _ weight: Double, _ reps: Int) -> Void

    /// Dismisses the picker sheet (the outer sheet owned by ActiveWorkoutView).
    /// Captured here so it can be called from within the setup sheet closure.
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""

    /// Set when the user taps an exercise. Drives the setup sheet presentation.
    /// Kept inside the picker so it is unaffected by re-renders in ActiveWorkoutView.
    @State private var selectedExercise: Exercise?

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            !existingNames.contains(exercise.name) &&
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var grouped: [(ExerciseCategory, [Exercise])] {
        let dict = Dictionary(grouping: filtered, by: \.category)
        return ExerciseCategory.allCases.compactMap { cat in
            guard let list = dict[cat], !list.isEmpty else { return nil }
            return (cat, list)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, exercises in
                    Section(category.rawValue) {
                        ForEach(exercises) { exercise in
                            Button {
                                selectedExercise = exercise
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        // ExerciseSetupView is presented as a child sheet rather than a
        // navigation push. Child sheets are fully isolated from parent view
        // re-renders, avoiding premature dismissal when ActiveWorkoutView
        // updates (e.g. the elapsed timer). Dismissing the picker sheet
        // also dismisses this child sheet automatically.
        .sheet(item: $selectedExercise) { exercise in
            ExerciseSetupView(exercise: exercise) { weight, reps in
                onSelect(exercise, weight, reps)
                dismiss() // closes picker + this child sheet together
            }
        }
    }
}

/// Configures the default weight and reps for an exercise before adding it.
///
/// Presented as a child sheet from `ExercisePickerView`. These values
/// pre-fill the input row so the user doesn't have to retype them for
/// every set. The "Add" button is disabled until both fields are valid.
struct ExerciseSetupView: View {
    let exercise: Exercise

    /// Called with the default (weight, reps) when the user taps "Add".
    let onConfirm: (_ weight: Double, _ reps: Int) -> Void

    @State private var weight = ""
    @State private var reps = ""

    private var canConfirm: Bool {
        Double(weight) != nil && (Int(reps) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Reps")
                        Spacer()
                        TextField("0", text: $reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("per set")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Default Weight & Reps")
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let w = Double(weight), let r = Int(reps), r > 0 else { return }
                        onConfirm(w, r)
                    }
                    .fontWeight(.semibold)
                    .disabled(!canConfirm)
                }
            }
        }
    }
}
