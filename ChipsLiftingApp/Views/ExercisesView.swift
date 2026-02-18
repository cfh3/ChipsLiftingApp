import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var showingAdd = false

    private var filtered: [Exercise] {
        searchText.isEmpty ? exercises : exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
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
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                if exercise.isCustom {
                                    Text("Custom")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
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
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        modelContext.insert(Exercise(name: trimmed, category: category, isCustom: true))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
