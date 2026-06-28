import SwiftUI

/// Create/Edit quick-add sheet: icon + name/calories/protein form with Cancel
/// and a confirm action. The parent owns the bound state and the callbacks.
struct QuickAddFormSheet: View {
    let title: String
    @Binding var icon: String
    @Binding var name: String
    @Binding var calories: String
    @Binding var protein: String
    let hideProtein: Bool
    let confirmLabel: String
    let confirmDisabled: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                EmojiTextField(text: $icon, placeholder: "Icon (emoji)")
                TextField("Name", text: $name)
                TextField("Calories", text: $calories).keyboardType(.numberPad)
                if !hideProtein { TextField("Protein (g)", text: $protein).keyboardType(.numberPad) }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel, action: onConfirm).disabled(confirmDisabled)
                }
            }
        }.presentationDetents([.medium])
    }
}
