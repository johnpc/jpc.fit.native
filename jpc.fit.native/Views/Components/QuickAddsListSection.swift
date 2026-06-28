import SwiftUI
import Amplify

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

/// The Settings "Your Quick Adds" list: tappable rows to edit, swipe to delete.
struct QuickAddsListSection: View {
    let quickAdds: [QuickAdd]
    let hideProtein: Bool
    let iconDisplay: (String) -> String
    let onEdit: (QuickAdd) -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        Section("Your Quick Adds") {
            if quickAdds.isEmpty {
                Text("No custom quick adds").foregroundStyle(.secondary)
            } else {
                ForEach(quickAdds, id: \.id) { qa in
                    Button { onEdit(qa) } label: {
                        HStack {
                            Text(iconDisplay(qa.icon)); Text(qa.name); Spacer()
                            Text("\(qa.calories) cal").foregroundStyle(.secondary)
                            if !hideProtein, let p = qa.protein { Text("\(p)g").foregroundStyle(.secondary) }
                        }
                    }.foregroundStyle(.primary)
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}
