import SwiftUI

struct RemainingSection: View {
    let remaining: Int
    var protein: Int = 0
    var hideProtein: Bool = true
    
    var body: some View {
        Section {
            HStack {
                Text("Remaining")
                Spacer()
                Text("\(remaining) cal")
                    .foregroundColor(remaining > 0 ? .green : .red)
                    .fontWeight(.bold)
            }
            if !hideProtein {
                HStack {
                    Text("Protein")
                    Spacer()
                    Text("\(protein)g")
                        .fontWeight(.bold)
                }
            }
        }
    }
}
