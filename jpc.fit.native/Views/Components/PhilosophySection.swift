import SwiftUI

/// The Settings "Why T-Shirt Sizes?" philosophy disclosure.
struct PhilosophySection: View {
    var body: some View {
        Section {
            DisclosureGroup("Why T-Shirt Sizes?") {
                Text("**The philosophy of jpc.fit is that mindful eating is more important than counting every calorie exactly perfectly.**").font(.callout).padding(.vertical, 4)
                Text("In the USA, calorie labels can legally be wrong by up to 20%. Instead, we recommend loose estimation (and round up when it makes sense!)").font(.callout).padding(.vertical, 4)
                Text("If this philosophy doesn't work for you, you can create custom quick adds for your most common meals.").font(.callout).padding(.vertical, 4)
            }
        }
    }
}
