import SwiftUI

/// App icon + name row, shared by the list-header section and AphorismsView.
struct AppHeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("AppIconImage")
                .resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(10)
            VStack(alignment: .leading) {
                Text("fit.jpc.io").font(.headline)
                Text("Health tracker").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct HeaderSection: View {
    var body: some View {
        Section {
            AppHeaderRow()
        }
    }
}
