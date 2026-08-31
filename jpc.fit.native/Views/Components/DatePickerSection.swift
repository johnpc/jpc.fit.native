import SwiftUI

/// Day navigation row: prev/next chevrons, the selected date, and a "Today"
/// shortcut whenever the selection isn't today.
struct DatePickerSection: View {
    @Binding var selectedDate: Date

    private var dayLabel: String { selectedDate.formatted(date: .numeric, time: .omitted) }
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    var body: some View {
        Section {
            HStack {
                Button { change(by: -1) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Previous day")
                Spacer()
                Text(dayLabel).fontWeight(.bold)
                Spacer()
                Button { change(by: 1) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Next day")
                if !isToday {
                    Button("Today") { selectedDate = Date() }
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
            }
        }
    }

    private func change(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
