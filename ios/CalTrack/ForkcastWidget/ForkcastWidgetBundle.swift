import WidgetKit
import SwiftUI

@main
struct ForkcastWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieRingWidget()
        MacroWidget()
        WaterWidget()
        InteractiveWaterWidget()
    }
}
