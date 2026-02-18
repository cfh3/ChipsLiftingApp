import Foundation
import SwiftData

/// A single logged set within a workout — one exercise performed for a given
/// weight and number of reps.
///
/// Exercise identity is stored by value (`exerciseName`, `exerciseCategory`)
/// rather than as a relationship to `Exercise`. This means historical sets
/// remain intact even if the exercise is renamed or deleted from the library.
@Model
final class WorkoutSet {
    /// Name of the exercise performed (e.g. "Bench Press").
    var exerciseName: String

    /// Category of the exercise, stored so the detail view can group/display
    /// sets without needing to fetch the originating `Exercise` object.
    var exerciseCategory: ExerciseCategory

    /// Load lifted in pounds.
    var weight: Double

    /// Number of repetitions completed.
    var reps: Int

    /// 1-based position of this set within the exercise during the session
    /// (e.g. 1 for the first set of squats, 2 for the second, etc.).
    var setNumber: Int

    /// Timestamp recorded when the set was saved. Used to determine the
    /// order exercises were first performed within a session.
    var completedAt: Date

    /// The parent workout session. `nil` briefly between object creation and
    /// insertion into the model context; always set before `context.save()`.
    var session: WorkoutSession?

    init(
        exerciseName: String,
        exerciseCategory: ExerciseCategory,
        weight: Double,
        reps: Int,
        setNumber: Int
    ) {
        self.exerciseName = exerciseName
        self.exerciseCategory = exerciseCategory
        self.weight = weight
        self.reps = reps
        self.setNumber = setNumber
        self.completedAt = .now
    }

    /// Total weight moved for this set (weight × reps), in pounds.
    var volume: Double { weight * Double(reps) }

    /// Weight formatted for display: whole numbers show no decimal (e.g. "135"),
    /// fractional values show one decimal place (e.g. "135.5").
    var displayWeight: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}
