import XCTest
@testable import jpc_fit

/// StateMachine "Backend mode" + "Demo session" + the composition root.
@MainActor
final class AppModeTests: XCTestCase {
    func testLiveIsTheDefault() {
        XCTAssertEqual(AppMode.detect(arguments: ["/app"], environment: [:]), .live)
        XCTAssertEqual(AppMode.detect(arguments: ["/app", "-demo"], environment: ["FIT_DEMO": "0"]), .live)
    }

    func testDemoFromLaunchArgumentOrEnvironment() {
        XCTAssertEqual(AppMode.detect(arguments: ["/app", "--demo"], environment: [:]), .demo)
        XCTAssertEqual(AppMode.detect(arguments: [], environment: ["FIT_DEMO": "1"]), .demo)
    }

    func testConfigureSwapsEverySeamAtOnce() {
        AppServices.configure(.demo)
        XCTAssertEqual(AppServices.mode, .demo)
        XCTAssertTrue(AppServices.api is DemoAPIService)
        XCTAssertTrue(AppServices.health is DemoHealthStats)
        XCTAssertTrue(AppServices.auth is DemoSession)

        AppServices.configure(.live)
        XCTAssertEqual(AppServices.mode, .live)
        XCTAssertTrue(AppServices.api is APIService)
        XCTAssertTrue(AppServices.health is HealthKitService)
        XCTAssertTrue(AppServices.auth is AmplifyAuthService)
    }

    // MARK: Demo session

    func testSignInRequiresBothFields() {
        let session = DemoSession()
        XCTAssertEqual(session.state, .signedOut(message: nil))
        session.signIn(email: "", password: "x")
        XCTAssertEqual(session.state, .signedOut(message: "Enter an email and a password to try the demo."))
        XCTAssertFalse(session.isSignedIn)
        session.signIn(email: "  me@example.com ", password: "")
        XCTAssertFalse(session.isSignedIn)
    }

    func testSignInThenSignOutRoundTrip() async {
        let session = DemoSession()
        session.signIn(email: " demo@jpc.fit ", password: "pw")
        XCTAssertEqual(session.state, .signedIn(email: "demo@jpc.fit"))
        XCTAssertTrue(session.isSignedIn)

        await session.signOut()
        XCTAssertEqual(session.state, .signedOut(message: nil), "sign out clears any earlier message")

        session.signIn(email: "a@b.c", password: "pw")
        await session.deleteUser()
        XCTAssertFalse(session.isSignedIn, "deleting the demo account ends the session")
    }
}
