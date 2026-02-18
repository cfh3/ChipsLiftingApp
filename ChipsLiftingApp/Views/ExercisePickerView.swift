import SwiftUI
import SwiftData

/// Modal sheet for adding an exercise to the active workout.
///
/// Shows a searchable list of all exercises grouped by category, filtered
/// to exclude exercises already present in the current workout. Tapping an
/// exercise calls `onSelect`, then dismisses the sheet.
struct ExercisePickerView: View {
    /// Names of exercises already added to the workout. These are hidden so
    /// the user can't accidentally add the same exercise twice.
    let existingNames: Set<String>

    /// Called with the selected exercise before the sheet dismisses.
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss

    /// All exercises from the library, sorted alphabetically.
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    /// Current search query entered by the user.
    @State private var searchText = ""

    /// Exercises that match the search query and are not already in the workout.
    private var filtered: [Exercise] {
        exercises.filter { exercise in
            !existingNames.contains(exercise.name) &&
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    /// Filtered exercises grouped by category in the canonical `allCases` order.
    /// Categories with no matching exercises are omitted entirely.
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
                                // Notify the parent and dismiss in one action
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                Text(exercise.name)
                                    .foregroundStyle(.primary)
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
