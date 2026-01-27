import SwiftUI

// Minimal test to debug date picker
struct DatePickerTestView: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Date Picker Test")
                .font(.title)
            
            Text("Selected: \(selectedDate.formatted(date: .numeric, time: .omitted))")
                .font(.headline)
            
            HStack(spacing: 40) {
                Button("← Prev") {
                    print("Before: \(selectedDate)")
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                    print("After: \(selectedDate)")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Next →") {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Also test with the actual component
            Text("Component Test:")
            DatePickerSection(selectedDate: $selectedDate)
        }
        .padding()
    }
}

#Preview {
    DatePickerTestView()
}
