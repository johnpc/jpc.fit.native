import Foundation

/// Food write actions for `FoodViewModel` — all OPTIMISTIC. The `foods` array
/// (and therefore the totals + widget) updates at tap time; the network write
/// follows. No post-write refetch: an immediate re-list is both slow (it held
/// the UI on a spinner for the whole round trip) and racy (DynamoDB's eventual
/// consistency can miss the just-written row). The `.foodDataChanged` post
/// carries `object: self` so the owning view can ignore its own writes while
/// still reconciling watch-originated ones.
extension FoodViewModel {
    func addFood(name: String, calories: Int, protein: Int? = nil, day: String) async {
        // Show the row instantly under a temp id, then swap in the server id
        // so a follow-up edit/delete targets the real record.
        let temp = Food(id: UUID().uuidString, name: name, calories: calories, protein: protein, day: day)
        foods.append(temp)
        didMutate(day: day)
        if let id = await api.createFood(name: name, calories: calories, protein: protein, day: day),
           let idx = foods.firstIndex(where: { $0.id == temp.id }) {
            foods[idx] = Food(id: id, name: name, calories: calories, protein: protein, day: day)
        }
    }

    func deleteFood(_ food: Food, day: String) async {
        foods.removeAll { $0.id == food.id }
        didMutate(day: day)
        await api.deleteFood(id: food.id)
    }

    func updateFood(id: String, name: String?, calories: Int, protein: Int?, day: String) async {
        if let idx = foods.firstIndex(where: { $0.id == id }) {
            var patched = foods[idx]
            if let name { patched.name = name }
            patched.calories = calories
            patched.protein = protein
            foods[idx] = patched
        }
        didMutate(day: day)
        await api.updateFood(id: id, name: name, calories: calories, protein: protein)
    }

    private func didMutate(day: String) {
        updateWidget(day: day)
        NotificationCenter.default.post(name: .foodDataChanged, object: self)
    }
}
