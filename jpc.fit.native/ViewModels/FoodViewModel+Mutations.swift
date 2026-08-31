import Foundation

/// Food write actions for `FoodViewModel` — all OPTIMISTIC. The `foods` array
/// (and therefore the totals + widget) updates at tap time; the network write
/// follows. No post-write refetch: an immediate re-list is both slow (it held
/// the UI on a spinner for the whole round trip) and racy (DynamoDB's eventual
/// consistency can miss the just-written row). On failure the optimistic
/// change ROLLS BACK and `errorMessage` surfaces it — a row must never look
/// saved when the write was lost. The `.foodDataChanged` post carries
/// `object: self` so the owning view can ignore its own writes while still
/// reconciling watch-originated ones.
extension FoodViewModel {
    func addFood(name: String, calories: Int, protein: Int? = nil, day: String) async {
        // Show the row instantly under a temp id, then swap in the server id
        // so a follow-up edit/delete targets the real record.
        let temp = Food(id: UUID().uuidString, name: name, calories: calories, protein: protein, day: day)
        foods.append(temp)
        didMutate(day: day)
        if let id = await api.createFood(name: name, calories: calories, protein: protein, day: day) {
            if let idx = foods.firstIndex(where: { $0.id == temp.id }) {
                foods[idx] = Food(id: id, name: name, calories: calories, protein: protein, day: day)
            }
        } else {
            foods.removeAll { $0.id == temp.id }
            didMutate(day: day)
            errorMessage = "Couldn't save \"\(name)\" — check your connection and try again."
        }
    }

    func deleteFood(_ food: Food, day: String) async {
        guard let idx = foods.firstIndex(where: { $0.id == food.id }) else { return }
        foods.remove(at: idx)
        didMutate(day: day)
        if await !api.deleteFood(id: food.id) {
            foods.insert(food, at: min(idx, foods.count))
            didMutate(day: day)
            errorMessage = "Couldn't delete \"\(food.name ?? "Food")\" — check your connection and try again."
        }
    }

    func updateFood(id: String, name: String?, calories: Int, protein: Int?, day: String) async {
        guard let idx = foods.firstIndex(where: { $0.id == id }) else { return }
        let original = foods[idx]
        var patched = original
        if let name { patched.name = name }
        patched.calories = calories
        patched.protein = protein
        foods[idx] = patched
        didMutate(day: day)
        if await !api.updateFood(id: id, name: name, calories: calories, protein: protein) {
            if let i = foods.firstIndex(where: { $0.id == id }) { foods[i] = original }
            didMutate(day: day)
            errorMessage = "Couldn't save changes to \"\(original.name ?? "Food")\" — try again."
        }
    }

    private func didMutate(day: String) {
        updateWidget(day: day)
        NotificationCenter.default.post(name: .foodDataChanged, object: self)
    }
}
