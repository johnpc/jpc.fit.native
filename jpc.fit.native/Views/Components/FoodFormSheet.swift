import SwiftUI

/// Add/Edit food entry sheet. Renders a name/calories/protein form with Cancel
/// and a confirm action; the parent owns the bound state and the callbacks.
struct FoodFormSheet: View {
    let title: String
    @Binding var name: String
    @Binding var calories: String
    @Binding var protein: String
    let hideProtein: Bool
    let focusName: Bool
    let confirmLabel: String
    let confirmDisabled: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name).focused($nameFieldFocused).textInputAutocapitalization(.words)
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
            .onAppear { if focusName { nameFieldFocused = true } }
        }.presentationDetents([.medium])
    }
}
