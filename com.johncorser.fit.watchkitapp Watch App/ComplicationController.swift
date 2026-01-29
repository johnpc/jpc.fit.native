import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    private let defaults = UserDefaults(suiteName: "group.com.johncorser.fit")
    
    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        [CLKComplicationDescriptor(
            identifier: "calories",
            displayName: "Calories",
            supportedFamilies: [
                .circularSmall,
                .modularSmall,
                .modularLarge,
                .utilitarianSmall,
                .utilitarianLarge,
                .graphicCorner,
                .graphicCircular,
                .graphicRectangular
            ]
        )]
    }
    
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        let remaining = defaults?.integer(forKey: "watchRemaining") ?? 0
        let consumed = defaults?.integer(forKey: "watchConsumed") ?? 0
        let burned = defaults?.integer(forKey: "watchBurned") ?? 0
        
        let template = makeTemplate(for: complication.family, remaining: remaining, consumed: consumed, burned: burned)
        guard let template else { return nil }
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }
    
    private func makeTemplate(for family: CLKComplicationFamily, remaining: Int, consumed: Int, burned: Int) -> CLKComplicationTemplate? {
        let _ = remaining >= 0 ? UIColor.green : UIColor.red
        
        switch family {
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallSimpleText(
                textProvider: CLKSimpleTextProvider(text: "\(remaining)")
            )
            
        case .modularSmall:
            return CLKComplicationTemplateModularSmallSimpleText(
                textProvider: CLKSimpleTextProvider(text: "\(remaining)")
            )
            
        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Calories"),
                body1TextProvider: CLKSimpleTextProvider(text: "\(remaining) remaining"),
                body2TextProvider: CLKSimpleTextProvider(text: "🔥\(burned) 🍽️\(consumed)")
            )
            
        case .utilitarianSmall:
            return CLKComplicationTemplateUtilitarianSmallFlat(
                textProvider: CLKSimpleTextProvider(text: "\(remaining) cal")
            )
            
        case .utilitarianLarge:
            return CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "\(remaining) cal remaining")
            )
            
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: CLKSimpleTextProvider(text: "cal"),
                outerTextProvider: CLKSimpleTextProvider(text: "\(remaining)")
            )
            
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(remaining)"),
                line2TextProvider: CLKSimpleTextProvider(text: "cal")
            )
            
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Calories"),
                body1TextProvider: CLKSimpleTextProvider(text: "\(remaining) remaining"),
                body2TextProvider: CLKSimpleTextProvider(text: "🔥\(burned) 🍽️\(consumed)")
            )
            
        default:
            return nil
        }
    }
}
