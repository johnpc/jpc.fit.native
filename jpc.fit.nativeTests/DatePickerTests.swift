import XCTest
import SwiftUI
@testable import jpc_fit_native

final class DatePickerTests: XCTestCase {
    
    func testDateBinding() {
        // Create a state holder
        var date = Date()
        let originalDate = date
        
        // Simulate what the button does
        let newDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        date = newDate
        
        // Verify date changed
        XCTAssertNotEqual(date, originalDate)
        XCTAssertEqual(Calendar.current.component(.day, from: date), 
                       Calendar.current.component(.day, from: originalDate) - 1)
        print("Date changed from \(originalDate) to \(date)")
    }
    
    func testDateFormatting() {
        let date = Date()
        let formatted = date.formatted(date: .numeric, time: .omitted)
        print("Formatted: \(formatted)")
        XCTAssertFalse(formatted.isEmpty)
        
        // Change date and verify formatting changes
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        let formattedYesterday = yesterday.formatted(date: .numeric, time: .omitted)
        print("Yesterday formatted: \(formattedYesterday)")
        XCTAssertNotEqual(formatted, formattedYesterday)
    }
    
    func testStateUpdateSimulation() {
        // This simulates what @State does
        class StateHolder: ObservableObject {
            @Published var selectedDate = Date()
        }
        
        let holder = StateHolder()
        let original = holder.selectedDate
        
        // Track if publisher fires
        var didChange = false
        let cancellable = holder.$selectedDate.sink { _ in
            didChange = true
        }
        
        // Simulate button tap
        holder.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: holder.selectedDate)!
        
        XCTAssertTrue(didChange, "Publisher should have fired")
        XCTAssertNotEqual(holder.selectedDate, original, "Date should have changed")
        
        _ = cancellable // Keep alive
    }
}
