import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 4) {
                        Text("\(dataManager.remainingCalories)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(dataManager.remainingCalories >= 0 ? .green : .red)
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            Label("\(dataManager.burnedCalories)", systemImage: "flame.fill")
                                .foregroundColor(.orange)
                            Label("\(dataManager.consumedCalories)", systemImage: "fork.knife")
                                .foregroundColor(.blue)
                        }
                        .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section("Quick Add") {
                    ForEach(dataManager.quickAdds.prefix(4)) { qa in
                        Button {
                            dataManager.addFood(name: "\(qa.icon) \(qa.name)", calories: qa.calories, protein: qa.protein)
                        } label: {
                            HStack {
                                Text(qa.icon)
                                Text(qa.name)
                                Spacer()
                                Text("\(qa.calories)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if !dataManager.foods.isEmpty {
                    Section("Today") {
                        ForEach(dataManager.foods) { food in
                            HStack {
                                Text(food.name)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(food.calories)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                let food = dataManager.foods[i]
                                dataManager.deleteFood(id: food.id, calories: food.calories)
                            }
                        }
                    }
                }
            }
            .navigationTitle("jpc.fit")
            .refreshable {
                await dataManager.refresh()
            }
        }
        .task {
            await dataManager.requestHealthKitAuth()
            await dataManager.refresh()
        }
    }
}
