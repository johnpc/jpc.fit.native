import SwiftUI

struct RemainingSection: View {
    let remaining: Int
    
    var body: some View {
        Section {
            HStack {
                Text("Remaining")
                Spacer()
                Text("\(remaining) cal")
                    .foregroundColor(remaining > 0 ? .green : .red)
                    .fontWeight(.bold)
            }
        }
    }
}
