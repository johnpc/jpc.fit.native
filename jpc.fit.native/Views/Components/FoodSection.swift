import SwiftUI

struct FoodSection: View {
    let foods: [Food]
    let isLoading: Bool
    let dayString: String
    let hideProtein: Bool
    let onDelete: (IndexSet) -> Void
    let onEdit: (Food) -> Void
    
    var body: some View {
        Section("Food (\(dayString))") {
            if isLoading {
                ProgressView()
            } else if foods.isEmpty {
                Text("No food logged").foregroundColor(.secondary)
            } else {
                ForEach(foods, id: \.id) { food in
                    Button { onEdit(food) } label: {
                        HStack {
                            Text(food.name ?? "Food")
                            Spacer()
                            Text("\(food.calories) cal").foregroundColor(.secondary)
                            if !hideProtein, let p = food.protein {
                                Text("\(p)g").foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}
