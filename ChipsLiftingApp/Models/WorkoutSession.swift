import Foundation
import SwiftData

/// A single workout session containing all exercises and sets performed.
///
/// A session is created when the user taps "Start Workout" and its `endedAt`
/// is set when they tap "Finish". Sessions without an `endedAt` are considered
/// active (e.g. if the app was force-quit mid-workout).
@Model
final class WorkoutSession {
    /// When the workout was started.
    var date: Date

    /// User-visible name auto-assigned based on time of day (e.g. "Morning Workout").
    var name: String

    /// Optional free-text notes (reserved for future use).
    var notes: String

    /// Set when the user finishes the workout. `nil` while the session is in progress.
    var endedAt: Date?

    /// All sets logged during this session.
    ///
    /// The `cascade` delete rule means deleting a session automatically
    /// deletes every associated `WorkoutSet`, preventing orphaned records.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet] = []

    init(date: Date = .now, name: String = "", notes: String = "") {
        self.date = date
        self.name = name
        self.notes = notes
    }

    /// `true` while the workout is in progress (no end date recorded yet).
    var isActive: Bool { endedAt == nil }

    /// Sum of (weight × reps) across all sets, in pounds.
    /// Useful as a high-level measure of workout load.
    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    /// Ordered list of unique exercise names, in the order they were first performed.
    ///
    /// Determined by sorting sets on `completedAt` and deduplicating names,
    /// so the order reflects the actual sequence of exercises during the workout.
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

    /// Sets grouped by exercise and ordered by first appearance in the workout.
    ///
    /// Within each group the sets are sorted by `setNumber` (ascending),
    /// so they render in the order they were logged. Used by both
    /// `WorkoutDetailView` and the active workout summary.
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

    /// Human-readable workout duration, or `nil` if the session is still active.
    ///
    /// Formatted as "45m" for sessions under an hour, or "1h 15m" for longer ones.
    var formattedDuration: String? {
        guard let endedAt else { return nil }
        let minutes = Int(endedAt.timeIntervalSince(date)) / 60
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }
}
