import Foundation

/// The composition root: the ONE place logic meets the real backend, HealthKit
/// and auth. ViewModels default their dependencies from here, so flipping
/// `AppMode` swaps every seam at once — nothing downstream is special-cased.
/// Written once, in `App.init`, before any view exists (the seams are all
/// `Sendable`, so default-argument reads from any context are safe).
enum AppServices {
    private(set) static var mode: AppMode = .live
    private(set) static var api: APIServiceProtocol = APIService.shared
    private(set) static var health: HealthStatsProviding = HealthKitService.shared
    private(set) static var auth: AuthServiceProtocol = AmplifyAuthService()
    /// The demo sign-in session; only rendered when `mode == .demo`.
    static let demoSession = DemoSession()

    static func configure(_ newMode: AppMode) {
        mode = newMode
        switch newMode {
        case .live:
            api = APIService.shared
            health = HealthKitService.shared
            auth = AmplifyAuthService()
        case .demo:
            api = DemoAPIService()
            health = DemoHealthStats()
            auth = demoSession
        }
    }
}
