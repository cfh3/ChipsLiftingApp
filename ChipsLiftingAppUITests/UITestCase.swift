import XCTest

/// Base class for UI tests.
///
/// Launches the app with `-ui-testing`, which makes `LiftingApp` use an
/// in-memory store. Every test starts from an empty history and a freshly
/// seeded exercise library, and never touches data on the simulator.
///
/// XCUITest APIs are main-actor isolated, so the class runs on the main actor.
/// setUp/tearDown use the async overloads, which XCTest lets subclasses isolate.
@MainActor
class UITestCase: XCTestCase {
    var app: XCUIApplication!

    /// Entry point for screen-object chains; the app always opens on History.
    var history: HistoryScreen { HistoryScreen(app: app) }

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Pin language and locale so formatted numbers ("1,350 lbs") are predictable.
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    override func tearDown() async throws {
        // Keep a picture of the final screen when a test fails.
        if let run = testRun, run.failureCount > 0 {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "Failure screen"
            shot.lifetime = .keepAlways
            add(shot)
        }
        app = nil
    }
}

/// Shared helpers for screen objects. Main-actor isolated like the XCUITest
/// APIs it wraps; conforming structs inherit that isolation.
@MainActor
protocol Screen {
    var app: XCUIApplication { get }
}

extension Screen {
    /// Default timeout for an element to appear.
    var timeout: TimeInterval { 5 }

    /// Fails the test (at the caller's line) unless `element` appears in time.
    @discardableResult
    func waitFor(_ element: XCUIElement, _ what: String,
                 file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      "Timed out waiting for \(what)", file: file, line: line)
        return element
    }

    /// Adds a named screenshot to the test's result bundle.
    func snapshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { $0.add(shot) }
    }
}
