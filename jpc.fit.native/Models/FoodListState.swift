import Foundation

/// StateMachine: Food list
///
/// What the Calories list shows for the selected day. Derived by
/// `FoodViewModel.listState` from its one loading flag + rows; the section
/// view switches over it instead of re-deriving from two properties.
enum FoodListState: Equatable {
    case loading
    case empty
    case rows([Food])
}

extension Food: Equatable {
    public static func == (lhs: Food, rhs: Food) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.calories == rhs.calories
            && lhs.protein == rhs.protein && lhs.day == rhs.day
    }
}
