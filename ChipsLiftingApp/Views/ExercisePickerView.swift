import SwiftUI
import SwiftData

/// Modal sheet for adding an exercise to the active workout.
///
/// Two-step flow:
/// 1. Search and select an exercise from the grouped list.
/// 2. Configure the number of sets, weight, and reps on `ExerciseSetupView`.
///
/// The `onSelect` callback is invoked with all four values when the user
/// confirms, then the entire sheet is dismissed.
struct ExercisePickerView: View {
    /// Names of exercises already in the workout — hidden from the list
    /// so the user can't add the same exercise twice.
    let existingNames: Set<String>

    /// Called with the chosen exercise and its configuration (sets, weight, reps)
    /// just before the sheet dismisses.
    let onSelect: (Exercise, _ sets: Int, _ weight: Double, _ reps: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""

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
                            // NavigationLink manages its own push state internally,
                            // avoiding the re-render/reset issues of navigationDestination(item:).
                            // `dismiss` is captured from this scope so calling it inside
                            // onConfirm closes the entire picker sheet.
                            NavigationLink {
                                ExerciseSetupView(exercise: exercise) { sets, weight, reps in
                                    onSelect(exercise, sets, weight, reps)
                                    dismiss()
                                }
                            } label: {
                                Text(exercise.name)
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
    }
}

/// Second step of the add-exercise flow: configure sets, weight, and reps.
///
/// Presents a simple form with a stepper for set count and text fields for
/// weight and reps. The "Add" button stays disabled until both numeric fields
/// contain valid, positive values.
struct ExerciseSetupView: View {
    let exercise: Exercise

    /// Called with the confirmed (sets, weight, reps) when the user taps "Add".
    let onConfirm: (_ sets: Int, _ weight: Double, _ reps: Int) -> Void

    /// Defaults to 3 sets — a common starting point for most exercises.
    @State private var sets = 3
    @State private var weight = ""
    @State private var reps = ""

    private var canConfirm: Bool {
        Double(weight) != nil && (Int(reps) ?? 0) > 0
    }

    var body: some View {
        Form {
            Section {
                // Stepper bounded to a practical range (1–20 sets)
                Stepper("\(sets) \(sets == 1 ? "set" : "sets")", value: $sets, in: 1...20)
            } header: {
                Text("Sets")
            }

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
                Text("Weight & Reps")
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    guard let w = Double(weight), let r = Int(reps), r > 0 else { return }
                    onConfirm(sets, w, r)
                }
                .fontWeight(.semibold)
                .disabled(!canConfirm)
            }
        }
    }
}
