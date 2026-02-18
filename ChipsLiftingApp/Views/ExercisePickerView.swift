import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    let existingNames: Set<String>
    let onSelect: (Exercise) -> Void

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
                            Button {
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
