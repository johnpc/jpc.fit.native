import SwiftUI

/// Shared chrome for the add/edit sheets: form + title + Cancel/confirm
/// toolbar + medium detent. The parent supplies the fields as content.
struct FormSheet<Content: View>: View {
    let title: String
    let confirmLabel: String
    let confirmDisabled: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            Form(content: content)
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

/// Calories + optional protein numeric fields, shared by both sheets.
struct CaloriesProteinFields: View {
    @Binding var calories: String
    @Binding var protein: String
    let hideProtein: Bool

    var body: some View {
        TextField("Calories", text: $calories).keyboardType(.numberPad)
        if !hideProtein { TextField("Protein (g)", text: $protein).keyboardType(.numberPad) }
    }
}
