import SwiftUI

struct HealthKitSection: View {
    let cache: HealthKitCache?
    let consumed: Int
    var hideSteps = false
    
    var body: some View {
        Section("HealthKit") {
            row("Active", "\(Int(cache?.activeCalories ?? 0)) cal")
            row("Basal", "\(Int(cache?.baseCalories ?? 0)) cal")
            if !hideSteps {
                row("Steps", "\(Int(cache?.steps ?? 0))")
            }
            row("Consumed", "\(consumed) cal")
        }
    }
    
    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value) }
    }
}
