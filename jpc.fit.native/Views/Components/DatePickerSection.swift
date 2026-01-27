import SwiftUI

struct DatePickerSection: View {
    @Binding var selectedDate: Date
    
    private var dayString: String { selectedDate.formatted(date: .numeric, time: .omitted) }
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    
    var body: some View {
        Section {
            HStack {
                Button {
                    let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                    print("PREV: \(selectedDate) -> \(newDate)")
                    selectedDate = newDate
                    print("AFTER: \(selectedDate)")
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(dayString).fontWeight(.bold)
                Spacer()
                Button {
                    let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                    print("NEXT: \(selectedDate) -> \(newDate)")
                    selectedDate = newDate
                    print("AFTER: \(selectedDate)")
                } label: {
                    Image(systemName: "chevron.right")
                }
                if !isToday {
                    Button("Today") { selectedDate = Date() }.font(.caption)
                }
            }
        }
    }
}
