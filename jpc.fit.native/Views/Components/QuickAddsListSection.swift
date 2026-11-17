import SwiftUI

/// The Settings "Your Quick Adds" list: tappable rows to edit, swipe to delete.
struct QuickAddsListSection: View {
    let quickAdds: [QuickAddItem]
    let hideProtein: Bool
    let onEdit: (QuickAddItem) -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        Section("Your Quick Adds") {
            if quickAdds.isEmpty {
                Text("No custom quick adds").foregroundStyle(.secondary)
            } else {
                ForEach(quickAdds) { qa in
                    Button { onEdit(qa) } label: {
                        HStack {
                            Text(qa.icon); Text(qa.name); Spacer()
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
