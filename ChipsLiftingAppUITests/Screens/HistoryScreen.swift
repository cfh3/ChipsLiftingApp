import XCTest

/// The History tab: workout list, or the "No Workouts" empty state.
struct HistoryScreen: Screen {
    let app: XCUIApplication

    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        self.app = app
        waitFor(app.navigationBars["History"], "History screen", file: file, line: line)
    }

    /// Asserts the empty state is showing.
    @discardableResult
    func assertEmpty(file: StaticString = #filePath, line: UInt = #line) -> Self {
        waitFor(app.staticTexts["No Workouts"], "the 'No Workouts' empty state", file: file, line: line)
        return self
    }

    /// Taps the empty-state "Start Workout" button.
    func startWorkout(file: StaticString = #filePath, line: UInt = #line) -> ActiveWorkoutScreen {
        waitFor(app.buttons["Start Workout"], "'Start Workout' button", file: file, line: line).tap()
        return ActiveWorkoutScreen(app: app, file: file, line: line)
    }

    /// Asserts the first workout row shows the given exercise count and volume.
    @discardableResult
    func assertFirstRow(exercises: Int, volume: String,
                        file: StaticString = #filePath, line: UInt = #line) -> Self {
        let row = firstRow
        waitFor(row, "a workout row", file: file, line: line)
        waitFor(row.staticTexts["\(exercises) exercises"], "'\(exercises) exercises' in the row", file: file, line: line)
        waitFor(row.staticTexts[volume], "'\(volume)' in the row", file: file, line: line)
        snapshot("History after finishing")
        return self
    }

    /// Opens the most recent workout.
    func openFirstWorkout(file: StaticString = #filePath, line: UInt = #line) -> WorkoutDetailScreen {
        waitFor(firstRow, "a workout row", file: file, line: line).tap()
        return WorkoutDetailScreen(app: app, file: file, line: line)
    }

    private var firstRow: XCUIElement { app.collectionViews.cells.firstMatch }
}
