import ActivityKit
import SwiftUI

/// Defines the data shape for the Live Activity / Dynamic Island.
///
/// Content state (updates live):  current best card + location
/// Static attributes: nothing — all data is dynamic for this use case
struct PointMaximizerAttributes: ActivityAttributes {
    public typealias PointMaximizerStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var merchantName:   String
        var contextTag:     String
        var categorySymbol: String   // SF Symbol name
        var categoryColor:  String   // hex
        var cardName:       String
        var cardLastFour:   String
        var cardColorHex:   String
        var multiplier:     Double
        var rewardCategory: String

        var rewardLabel: String {
            let m = multiplier.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(multiplier)) : String(format: "%.1f", multiplier)
            return "\(m)× \(rewardCategory)"
        }
    }
}
