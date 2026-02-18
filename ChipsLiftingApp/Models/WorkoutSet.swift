import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var exerciseName: String
    var exerciseCategory: ExerciseCategory
    var weight: Double
    var reps: Int
    var setNumber: Int
    var completedAt: Date
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

    var volume: Double { weight * Double(reps) }

    var displayWeight: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}
