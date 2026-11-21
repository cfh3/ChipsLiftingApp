import XCTest

/// The full-screen active workout, including the exercise picker and setup sheets.
struct ActiveWorkoutScreen: Screen {
    let app: XCUIApplication

    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        self.app = app
        waitFor(app.buttons["Add Exercise"], "the active workout screen", file: file, line: line)
    }

    /// Adds `name` via the picker, entering default weight and reps in the setup sheet.
    func addExercise(_ name: String, weight: String, reps: String,
                     file: StaticString = #filePath, line: UInt = #line) -> Self {
        app.buttons["Add Exercise"].tap()

        // Picker sheet: the seeded list is long, so scroll until the row is reachable.
        let row = app.buttons[A11y.pickerExercise(name)]
        waitFor(app.navigationBars["Add Exercise"], "the exercise picker", file: file, line: line)
        var swipes = 0
        while !row.isHittable && swipes < 10 {
            app.swipeUp()
            swipes += 1
        }
        waitFor(row, "'\(name)' in the picker", file: file, line: line).tap()

        // Setup sheet
        let weightField = waitFor(app.textFields[A11y.setupWeight], "setup weight field", file: file, line: line)
        weightField.tap()
        weightField.typeText(weight)
        let repsField = app.textFields[A11y.setupReps]
        repsField.tap()
        repsField.typeText(reps)
        snapshot("Setup sheet for \(name)")
        app.navigationBars[name].buttons["Add"].tap()

        // Both sheets close and the exercise card appears.
        waitFor(app.buttons[A11y.logSet(name)], "'\(name)' card", file: file, line: line)
        return self
    }

    /// Asserts the next-set fields are pre-filled with the setup values.
    @discardableResult
    func assertPrefill(_ name: String, weight: String, reps: String,
                       file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(app.textFields[A11y.entryWeight(name)].value as? String, weight,
                       "Weight pre-fill for \(name)", file: file, line: line)
        XCTAssertEqual(app.textFields[A11y.entryReps(name)].value as? String, reps,
                       "Reps pre-fill for \(name)", file: file, line: line)
        return self
    }

    /// Taps the checkmark to log the next set of `name`.
    func logSet(for name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let button = app.buttons[A11y.logSet(name)]
        XCTAssertTrue(button.isEnabled, "Log-set button for \(name) is disabled", file: file, line: line)
        button.tap()
        return self
    }

    /// Asserts logged set `number` of `name` shows `weight` (e.g. "135 lbs").
    @discardableResult
    func assertSet(_ number: Int, of name: String, shows weight: String,
                   file: StaticString = #filePath, line: UInt = #line) -> Self {
        let label = waitFor(app.staticTexts[A11y.loggedSet(name, number)],
                            "set \(number) of \(name)", file: file, line: line)
        XCTAssertEqual(label.label, weight, "Set \(number) of \(name)", file: file, line: line)
        snapshot("Set \(number) of \(name) logged")
        return self
    }

    /// Taps Finish and returns to History.
    func finish(file: StaticString = #filePath, line: UInt = #line) -> HistoryScreen {
        let finish = app.buttons["Finish"]
        XCTAssertTrue(finish.isEnabled, "Finish is disabled", file: file, line: line)
        finish.tap()
        return HistoryScreen(app: app, file: file, line: line)
    }
}
