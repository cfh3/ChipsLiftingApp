import SwiftUI
import SwiftData

/// Browseable exercise library showing all exercises grouped by category.
///
/// Supports full-text search, swipe-to-delete (for any exercise), and
/// adding custom exercises via the `AddExerciseView` sheet.
struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext

    /// All exercises sorted alphabetically. SwiftData keeps this up-to-date
    /// whenever exercises are inserted or deleted.
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var showingAdd = false

    /// Exercises filtered by the current search query, or all exercises when
    /// the search field is empty.
    private var filtered: [Exercise] {
        searchText.isEmpty ? exercises : exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Filtered exercises grouped by category in the canonical `allCases` order.
    /// Empty categories are omitted so the list stays clean.
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
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                // Badge distinguishes user-created exercises from seed data
                                if exercise.isCustom {
                                    Text("Custom")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        // Both seed and custom exercises can be deleted.
                        // Deleting a seed exercise removes it from the library
                        // but does not affect historical WorkoutSets (which store
                        // the exercise name by value).
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(exercises[i]) }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddExerciseView()
        }
    }
}

/// Form sheet for creating a new custom exercise.
///
/// Requires a non-empty name and a category selection. On confirmation the
/// exercise is inserted into the model context and the sheet is dismissed.
struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = ExerciseCategory.other

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Incline Cable Fly", text: $name)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        // Trim whitespace before saving so "  Squat  " becomes "Squat"
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        modelContext.insert(Exercise(name: trimmed, category: category, isCustom: true))
                        dismiss()
                    }
                    // Prevent saving a blank or whitespace-only name
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
