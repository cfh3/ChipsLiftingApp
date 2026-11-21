import XCTest

/// End-to-end smoke test of the core flow: start a workout, add an exercise,
/// log a set, finish, and check the result in History and the detail view.
final class WorkoutSmokeUITests: UITestCase {

    func testStartWorkoutLogSetAndFinish() {
        history
            .assertEmpty()
            .startWorkout()
            .addExercise("Bench Press", weight: "135", reps: "10")
            .assertPrefill("Bench Press", weight: "135", reps: "10")
            .logSet(for: "Bench Press")
            .assertSet(1, of: "Bench Press", shows: "135 lbs")
            .finish()
            .assertFirstRow(exercises: 1, volume: "1,350 lbs")
            .openFirstWorkout()
            .assertSet(exercise: "Bench Press", weight: "135 lbs", reps: "10 reps")
    }
}
