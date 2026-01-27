import SwiftUI

struct FoodSection: View {
    let foods: [Food]
    let isLoading: Bool
    let dayString: String
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        Section("Food (\(dayString))") {
            if isLoading {
                ProgressView()
            } else if foods.isEmpty {
                Text("No food logged").foregroundColor(.secondary)
            } else {
                ForEach(foods, id: \.id) { food in
                    HStack {
                        Text(food.name ?? "Food")
                        Spacer()
                        Text("\(food.calories) cal").foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}
