import Foundation
import SwiftData

/// The muscle-group category an exercise belongs to.
///
/// Used to group exercises in the picker and library views.
/// `CaseIterable` lets the views iterate all categories in a stable order.
/// `Codable` is required so SwiftData can persist the value as a String.
enum ExerciseCategory: String, Codable, CaseIterable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case other = "Other"
}

/// A single exercise definition stored in the exercise library.
///
/// Exercises are shared across all workouts — a `WorkoutSet` stores the
/// exercise name and category by value so historical sets are unaffected
/// if the exercise is later renamed or deleted.
@Model
final class Exercise {
    /// Display name shown throughout the app (e.g. "Bench Press").
    var name: String

    /// The primary muscle group this exercise targets.
    var category: ExerciseCategory

    /// `true` for exercises the user created; `false` for seed data.
    /// Custom exercises show a "Custom" badge in the library and can be deleted.
    var isCustom: Bool

    init(name: String, category: ExerciseCategory, isCustom: Bool = false) {
        self.name = name
        self.category = category
        self.isCustom = isCustom
    }

    /// Pre-built exercise list inserted on first launch when the library is empty.
    ///
    /// Covers the most common barbell, dumbbell, cable, and bodyweight movements
    /// across all major muscle groups. Stored as plain tuples to avoid creating
    /// managed objects before a model context is available.
    static let seedData: [(String, ExerciseCategory)] = [
        // Chest
        ("Bench Press", .chest), ("Incline Bench Press", .chest),
        ("Decline Bench Press", .chest), ("Dumbbell Fly", .chest),
        ("Cable Fly", .chest), ("Push Up", .chest), ("Chest Dips", .chest),
        // Back
        ("Deadlift", .back), ("Pull Up", .back), ("Chin Up", .back),
        ("Barbell Row", .back), ("Dumbbell Row", .back),
        ("Lat Pulldown", .back), ("Seated Cable Row", .back),
        ("Face Pull", .back), ("T-Bar Row", .back),
        // Shoulders
        ("Overhead Press", .shoulders), ("Dumbbell Shoulder Press", .shoulders),
        ("Lateral Raise", .shoulders), ("Front Raise", .shoulders),
        ("Rear Delt Fly", .shoulders), ("Arnold Press", .shoulders),
        ("Upright Row", .shoulders),
        // Arms
        ("Barbell Curl", .arms), ("Dumbbell Curl", .arms),
        ("Hammer Curl", .arms), ("Preacher Curl", .arms), ("Cable Curl", .arms),
        ("Tricep Pushdown", .arms), ("Skull Crusher", .arms),
        ("Close Grip Bench Press", .arms), ("Overhead Tricep Extension", .arms),
        // Legs
        ("Squat", .legs), ("Front Squat", .legs),
        ("Romanian Deadlift", .legs), ("Leg Press", .legs),
        ("Lunges", .legs), ("Leg Extension", .legs), ("Leg Curl", .legs),
        ("Calf Raise", .legs), ("Bulgarian Split Squat", .legs), ("Hack Squat", .legs),
        // Core
        ("Plank", .core), ("Crunch", .core), ("Cable Crunch", .core),
        ("Hanging Leg Raise", .core), ("Ab Wheel Rollout", .core),
        ("Russian Twist", .core), ("Side Plank", .core),
        // Cardio
        ("Running", .cardio), ("Cycling", .cardio),
        ("Rowing Machine", .cardio), ("Jump Rope", .cardio), ("Elliptical", .cardio),
    ]
}
