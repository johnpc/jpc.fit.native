import Foundation

/// StateMachine: Backend mode
///
/// Which backend the process talks to, decided ONCE at launch from the launch
/// arguments / environment and never changed afterwards. `.live` is the
/// shipping app (Cognito + AppSync); `.demo` is the in-process fake backend
/// used by the acceptance suite, CI, and anyone without an account — it needs
/// no network and no credentials.
enum AppMode: Equatable {
    case live
    case demo

    static let demoArgument = "--demo"
    static let demoEnvironmentKey = "FIT_DEMO"

    /// `--demo` as a launch argument or `FIT_DEMO=1` in the environment selects
    /// the fake backend; anything else is the live app.
    static func detect(arguments: [String], environment: [String: String]) -> AppMode {
        if arguments.contains(demoArgument) || environment[demoEnvironmentKey] == "1" {
            return .demo
        }
        return .live
    }

    static var fromProcess: AppMode {
        detect(arguments: ProcessInfo.processInfo.arguments,
               environment: ProcessInfo.processInfo.environment)
    }
}
