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
        FormSheet(title: title, confirmLabel: confirmLabel, confirmDisabled: confirmDisabled,
                  onCancel: onCancel, onConfirm: onConfirm) {
            TextField("Name", text: $name).focused($nameFieldFocused).textInputAutocapitalization(.words)
            CaloriesProteinFields(calories: $calories, protein: $protein, hideProtein: hideProtein)
        }
        .onAppear { if focusName { nameFieldFocused = true } }
    }
}
