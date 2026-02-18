import Foundation
import SwiftData

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

@Model
final class Exercise {
    var name: String
    var category: ExerciseCategory
    var isCustom: Bool

    init(name: String, category: ExerciseCategory, isCustom: Bool = false) {
        self.name = name
        self.category = category
        self.isCustom = isCustom
    }

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
