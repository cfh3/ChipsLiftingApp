/// Accessibility identifiers shared by the app and the UI test target.
///
/// This file is compiled into both `ChipsLiftingApp` and
/// `ChipsLiftingAppUITests`, so a view and the test that finds it always use
/// the same string. Identifiers are invisible to users and don't change
/// VoiceOver labels.
nonisolated enum A11y {
    // MARK: Exercise picker / setup sheets

    /// Row button for one exercise in `ExercisePickerView`.
    static func pickerExercise(_ name: String) -> String { "picker.exercise.\(name)" }

    /// Default-weight field in `ExerciseSetupView`.
    static let setupWeight = "setup.weight"

    /// Default-reps field in `ExerciseSetupView`.
    static let setupReps = "setup.reps"

    // MARK: Active workout (ExerciseBlockView)

    /// Pending-weight field for the next set of `name`.
    static func entryWeight(_ name: String) -> String { "entry.weight.\(name)" }

    /// Pending-reps field for the next set of `name`.
    static func entryReps(_ name: String) -> String { "entry.reps.\(name)" }

    /// Checkmark button that logs the next set of `name`.
    static func logSet(_ name: String) -> String { "entry.logSet.\(name)" }

    /// Weight label (e.g. "135 lbs") in logged set number `number` of `name`.
    static func loggedSet(_ name: String, _ number: Int) -> String { "entry.set.\(name).\(number)" }
}
