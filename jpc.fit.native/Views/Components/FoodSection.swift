import SwiftUI

struct FoodSection: View {
    let state: FoodListState
    let dayString: String
    let hideProtein: Bool
    let onDelete: (IndexSet) -> Void
    let onEdit: (Food) -> Void

    var body: some View {
        Section("Food (\(dayString))") {
            switch state {
            case .loading:
                ProgressView()
            case .empty:
                Text("No food logged").foregroundColor(.secondary)
            case .rows(let foods):
                ForEach(foods, id: \.id) { food in
                    Button { onEdit(food) } label: { row(food) }
                        .foregroundStyle(.primary)
                }
                .onDelete(perform: onDelete)
            }
        }
    }

    private func row(_ food: Food) -> some View {
        HStack {
            Text(food.name ?? "Food")
            Spacer()
            Text("\(food.calories) cal").foregroundColor(.secondary)
            if !hideProtein, let p = food.protein {
                Text("\(p)g").foregroundColor(.secondary)
            }
        }
    }
}
