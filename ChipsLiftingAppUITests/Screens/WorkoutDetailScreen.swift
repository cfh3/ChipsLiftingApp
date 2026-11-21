import XCTest

/// Read-only detail view for one workout.
struct WorkoutDetailScreen: Screen {
    let app: XCUIApplication

    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        self.app = app
        waitFor(app.staticTexts["Total Volume"], "the workout detail screen", file: file, line: line)
    }

    /// Asserts the detail list has a section for `exercise` containing a set
    /// with the given weight and reps labels (e.g. "135 lbs", "10 reps").
    @discardableResult
    func assertSet(exercise: String, weight: String, reps: String,
                   file: StaticString = #filePath, line: UInt = #line) -> Self {
        // SwiftUI List section headers are shown uppercased on iOS.
        let header = app.staticTexts[exercise].exists ? app.staticTexts[exercise]
                                                      : app.staticTexts[exercise.uppercased()]
        waitFor(header, "'\(exercise)' section", file: file, line: line)
        waitFor(app.staticTexts[weight], "'\(weight)'", file: file, line: line)
        waitFor(app.staticTexts[reps], "'\(reps)'", file: file, line: line)
        snapshot("Workout detail")
        return self
    }
}
