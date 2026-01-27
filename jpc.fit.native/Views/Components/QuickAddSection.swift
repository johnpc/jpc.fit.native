import SwiftUI

struct QuickAddSection: View {
    let quickAdds: [QuickAddItem]
    let onQuickAdd: (QuickAddItem) -> Void
    let onCustomAdd: () -> Void
    
    var body: some View {
        Section("Quick Add") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(quickAdds) { qa in
                    Button { onQuickAdd(qa) } label: {
                        VStack {
                            Text(qa.icon).font(.title)
                            Text(qa.name).font(.caption)
                            Text("\(qa.calories)").font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(8)
                        .background(Color(.systemGray6)).cornerRadius(8)
                    }.buttonStyle(.plain)
                }
                Button(action: onCustomAdd) {
                    VStack {
                        Text("➕").font(.title)
                        Text("Custom").font(.caption)
                    }
                    .frame(maxWidth: .infinity).padding(8)
                    .background(Color(.systemGray6)).cornerRadius(8)
                }.buttonStyle(.plain)
            }.padding(.vertical, 4)
        }
    }
}
