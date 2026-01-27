import SwiftUI

struct ErrorSection: View {
    let error: String?
    
    var body: some View {
        if let error {
            Section { Text(error).foregroundColor(.red).font(.caption) }
        }
    }
}
