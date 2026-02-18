import XCTest
import SwiftData
@testable import ChipsLiftingApp

// MARK: - WorkoutSet Tests

final class WorkoutSetTests: XCTestCase {

    func testVolumeCalculation() {
        let set = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                             weight: 135, reps: 10, setNumber: 1)
        XCTAssertEqual(set.volume, 1350)
    }

    func testVolumeWithZeroReps() {
        let set = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                             weight: 135, reps: 0, setNumber: 1)
        XCTAssertEqual(set.volume, 0)
    }

    func testVolumeWithDecimalWeight() {
        let set = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                             weight: 135.5, reps: 4, setNumber: 1)
        XCTAssertEqual(set.volume, 542, accuracy: 0.01)
    }

    func testDisplayWeightWholeNumber() {
        let set = WorkoutSet(exerciseName: "Squat", exerciseCategory: .legs,
                             weight: 225, reps: 5, setNumber: 1)
        XCTAssertEqual(set.displayWeight, "225")
    }

    func testDisplayWeightDecimal() {
        let set = WorkoutSet(exerciseName: "Squat", exerciseCategory: .legs,
                             weight: 225.5, reps: 5, setNumber: 1)
        XCTAssertEqual(set.displayWeight, "225.5")
    }

    func testDisplayWeightDropsTrailingZero() {
        // 100.0 should display as "100", not "100.0"
        let set = WorkoutSet(exerciseName: "Curl", exerciseCategory: .arms,
                             weight: 100.0, reps: 10, setNumber: 1)
        XCTAssertEqual(set.displayWeight, "100")
    }
}

// MARK: - WorkoutSession Tests

final class WorkoutSessionTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: WorkoutSession.self, WorkoutSet.self, Exercise.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    // MARK: isActive

    func testIsActiveWhenNoEndDate() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        XCTAssertTrue(session.isActive)
    }

    func testIsNotActiveAfterEndDateSet() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        session.endedAt = .now
        XCTAssertFalse(session.isActive)
    }

    // MARK: totalVolume

    func testTotalVolumeEmptySession() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        XCTAssertEqual(session.totalVolume, 0)
    }

    func testTotalVolumeWithSingleSet() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        let set = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                             weight: 100, reps: 10, setNumber: 1)
        set.session = session
        context.insert(set)
        try context.save()
        XCTAssertEqual(session.totalVolume, 1000)
    }

    func testTotalVolumeAcrossMultipleExercises() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        let set1 = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                              weight: 100, reps: 10, setNumber: 1) // 1000
        let set2 = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                              weight: 100, reps: 8,  setNumber: 2) // 800
        let set3 = WorkoutSet(exerciseName: "Squat", exerciseCategory: .legs,
                              weight: 150, reps: 5,  setNumber: 1) // 750
        for set in [set1, set2, set3] {
            set.session = session
            context.insert(set)
        }
        try context.save()
        XCTAssertEqual(session.totalVolume, 2550)
    }

    // MARK: uniqueExercises

    func testUniqueExercisesEmptySession() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        XCTAssertTrue(session.uniqueExercises.isEmpty)
    }

    func testUniqueExercisesDeduplicatesMultipleSets() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        let set1 = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                              weight: 135, reps: 10, setNumber: 1)
        let set2 = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                              weight: 135, reps: 8,  setNumber: 2)
        let set3 = WorkoutSet(exerciseName: "Squat", exerciseCategory: .legs,
                              weight: 225, reps: 5,  setNumber: 1)
        for set in [set1, set2, set3] {
            set.session = session
            context.insert(set)
        }
        try context.save()
        XCTAssertEqual(session.uniqueExercises.count, 2)
        XCTAssertTrue(session.uniqueExercises.contains("Bench Press"))
        XCTAssertTrue(session.uniqueExercises.contains("Squat"))
    }

    func testUniqueExercisesSingleExercise() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        let set1 = WorkoutSet(exerciseName: "Deadlift", exerciseCategory: .back,
                              weight: 315, reps: 5, setNumber: 1)
        let set2 = WorkoutSet(exerciseName: "Deadlift", exerciseCategory: .back,
                              weight: 315, reps: 3, setNumber: 2)
        for set in [set1, set2] {
            set.session = session
            context.insert(set)
        }
        try context.save()
        XCTAssertEqual(session.uniqueExercises.count, 1)
        XCTAssertEqual(session.uniqueExercises.first, "Deadlift")
    }

    // MARK: groupedSets

    func testGroupedSetsEmptySession() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        XCTAssertTrue(session.groupedSets.isEmpty)
    }

    func testGroupedSetsSortedBySetNumberWithinGroup() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        // Insert set 2 before set 1 intentionally
        let set2 = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                              weight: 135, reps: 8, setNumber: 2)
        let set1 = WorkoutSet(exerciseName: "Bench Press", exerciseCategory: .chest,
                              weight: 135, reps: 10, setNumber: 1)
        for set in [set2, set1] {
            set.session = session
            context.insert(set)
        }
        try context.save()

        let groups = session.groupedSets
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].sets[0].setNumber, 1)
        XCTAssertEqual(groups[0].sets[1].setNumber, 2)
    }

    func testGroupedSetsCorrectCategory() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        let set = WorkoutSet(exerciseName: "Deadlift", exerciseCategory: .back,
                             weight: 315, reps: 3, setNumber: 1)
        set.session = session
        context.insert(set)
        try context.save()

        let groups = session.groupedSets
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].exercise, "Deadlift")
        XCTAssertEqual(groups[0].category, .back)
    }

    func testGroupedSetsCorrectSetCount() throws {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        for i in 1...4 {
            let set = WorkoutSet(exerciseName: "Squat", exerciseCategory: .legs,
                                 weight: 225, reps: 5, setNumber: i)
            set.session = session
            context.insert(set)
        }
        try context.save()

        let groups = session.groupedSets
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].sets.count, 4)
    }

    // MARK: formattedDuration

    func testFormattedDurationNilWhenActive() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        XCTAssertNil(session.formattedDuration)
    }

    func testFormattedDurationUnderOneHour() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        session.endedAt = session.date.addingTimeInterval(45 * 60)
        XCTAssertEqual(session.formattedDuration, "45m")
    }

    func testFormattedDurationOneMinute() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        session.endedAt = session.date.addingTimeInterval(90) // 1.5 min truncates to 1m
        XCTAssertEqual(session.formattedDuration, "1m")
    }

    func testFormattedDurationOverOneHour() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        session.endedAt = session.date.addingTimeInterval(75 * 60) // 1h 15m
        XCTAssertEqual(session.formattedDuration, "1h 15m")
    }

    func testFormattedDurationExactlyOneHour() {
        let session = WorkoutSession(name: "Test")
        context.insert(session)
        session.endedAt = session.date.addingTimeInterval(60 * 60)
        XCTAssertEqual(session.formattedDuration, "1h 0m")
    }
}

// MARK: - Exercise + ExerciseCategory Tests

final class ExerciseTests: XCTestCase {

    func testSeedDataNotEmpty() {
        XCTAssertFalse(Exercise.seedData.isEmpty)
    }

    func testSeedDataMinimumCount() {
        XCTAssertGreaterThanOrEqual(Exercise.seedData.count, 40)
    }

    func testSeedDataContainsFoundationalLifts() {
        let names = Set(Exercise.seedData.map(\.0))
        XCTAssertTrue(names.contains("Bench Press"))
        XCTAssertTrue(names.contains("Squat"))
        XCTAssertTrue(names.contains("Deadlift"))
        XCTAssertTrue(names.contains("Overhead Press"))
        XCTAssertTrue(names.contains("Pull Up"))
    }

    func testSeedDataNamesAreUnique() {
        let names = Exercise.seedData.map(\.0)
        XCTAssertEqual(names.count, Set(names).count, "Seed data contains duplicate exercise names")
    }

    func testSeedDataCoversExpectedCategories() {
        let categories = Set(Exercise.seedData.map(\.1))
        for expected: ExerciseCategory in [.chest, .back, .shoulders, .arms, .legs, .core, .cardio] {
            XCTAssertTrue(categories.contains(expected), "Seed data missing category: \(expected.rawValue)")
        }
    }

    func testExerciseCategoryAllCasesCount() {
        XCTAssertEqual(ExerciseCategory.allCases.count, 8)
    }

    func testExerciseCategoryRawValues() {
        XCTAssertEqual(ExerciseCategory.chest.rawValue,     "Chest")
        XCTAssertEqual(ExerciseCategory.back.rawValue,      "Back")
        XCTAssertEqual(ExerciseCategory.shoulders.rawValue, "Shoulders")
        XCTAssertEqual(ExerciseCategory.arms.rawValue,      "Arms")
        XCTAssertEqual(ExerciseCategory.legs.rawValue,      "Legs")
        XCTAssertEqual(ExerciseCategory.core.rawValue,      "Core")
        XCTAssertEqual(ExerciseCategory.cardio.rawValue,    "Cardio")
        XCTAssertEqual(ExerciseCategory.other.rawValue,     "Other")
    }

    func testExerciseDefaultsToNotCustom() {
        let exercise = Exercise(name: "Bench Press", category: .chest)
        XCTAssertFalse(exercise.isCustom)
    }

    func testCustomExercise() {
        let exercise = Exercise(name: "My Custom Move", category: .other, isCustom: true)
        XCTAssertTrue(exercise.isCustom)
        XCTAssertEqual(exercise.name, "My Custom Move")
        XCTAssertEqual(exercise.category, .other)
    }
}
