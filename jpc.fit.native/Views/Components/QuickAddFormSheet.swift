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
        FormSheet(title: title, confirmLabel: confirmLabel, confirmDisabled: confirmDisabled,
                  onCancel: onCancel, onConfirm: onConfirm) {
            EmojiTextField(text: $icon, placeholder: "Icon (emoji)")
            TextField("Name", text: $name)
            CaloriesProteinFields(calories: $calories, protein: $protein, hideProtein: hideProtein)
        }
    }
}
