import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var name: String
    var notes: String
    var endedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet] = []

    init(date: Date = .now, name: String = "", notes: String = "") {
        self.date = date
        self.name = name
        self.notes = notes
    }

    var isActive: Bool { endedAt == nil }

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    var uniqueExercises: [String] {
        var seen = Set<String>()
        return sets
            .sorted { $0.completedAt < $1.completedAt }
            .compactMap { set in
                guard !seen.contains(set.exerciseName) else { return nil }
                seen.insert(set.exerciseName)
                return set.exerciseName
            }
    }

    var groupedSets: [(exercise: String, category: ExerciseCategory, sets: [WorkoutSet])] {
        var order: [String] = []
        var grouped: [String: (ExerciseCategory, [WorkoutSet])] = [:]
        for set in sets.sorted(by: { $0.completedAt < $1.completedAt }) {
            if grouped[set.exerciseName] == nil {
                order.append(set.exerciseName)
                grouped[set.exerciseName] = (set.exerciseCategory, [])
            }
            grouped[set.exerciseName]?.1.append(set)
        }
        return order.compactMap { name in
            guard let (cat, sets) = grouped[name] else { return nil }
            return (exercise: name, category: cat, sets: sets.sorted { $0.setNumber < $1.setNumber })
        }
    }

    var formattedDuration: String? {
        guard let endedAt else { return nil }
        let minutes = Int(endedAt.timeIntervalSince(date)) / 60
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }
}
