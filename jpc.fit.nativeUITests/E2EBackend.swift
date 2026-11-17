import XCTest

/// Which backend a scenario runs against. Demo is the default and needs
/// nothing; live needs real credentials and a reachable backend.
enum E2EBackend: Equatable {
    case demo
    case live(email: String, password: String)

    static let environmentKey = "FIT_E2E_BACKEND"

    /// `FIT_E2E_BACKEND=live` selects the real backend; anything else is demo.
    /// Live without credentials is a configuration error, not a skip — a
    /// skipped suite reports green while testing nothing.
    static func fromEnvironment(_ env: [String: String] = ProcessInfo.processInfo.environment) throws -> E2EBackend {
        guard env[environmentKey] == "live" else { return .demo }
        let email = env["TEST_EMAIL"] ?? loadEnv("TEST_EMAIL")
        let password = env["TEST_PASSWORD"] ?? loadEnv("TEST_PASSWORD")
        guard let email, let password else {
            throw E2EConfigurationError.missingCredentials
        }
        return .live(email: email, password: password)
    }

    var launchArguments: [String] {
        self == .demo ? ["--demo"] : []
    }

    var email: String {
        if case .live(let email, _) = self { return email }
        return "demo@jpc.fit"
    }

    var password: String {
        if case .live(_, let password) = self { return password }
        return "demo-password"
    }

    /// Only the live app asks for HealthKit; the demo health seam never prompts.
    var showsHealthKitPrompt: Bool { self != .demo }

    /// Read a key from a local `.env` file (used when the value isn't in the
    /// process environment, e.g. running from Xcode rather than CI).
    private static func loadEnv(_ key: String) -> String? {
        let paths = [
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { "\($0)/.env" },
            FileManager.default.currentDirectoryPath + "/.env",
        ].compactMap { $0 }

        for envPath in paths {
            guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else { continue }
            for line in content.components(separatedBy: .newlines) {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2, String(parts[0]) == key {
                    return String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
}

enum E2EConfigurationError: Error, CustomStringConvertible {
    case missingCredentials

    var description: String {
        "FIT_E2E_BACKEND=live requires TEST_EMAIL and TEST_PASSWORD (environment or .env)"
    }
}
