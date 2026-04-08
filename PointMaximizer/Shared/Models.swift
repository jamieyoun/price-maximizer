import Foundation
import SwiftUI

// MARK: - Store Category

enum StoreCategory: String, CaseIterable, Codable, Hashable {
    case grocery  = "Grocery"
    case dining   = "Dining"
    case gas      = "Gas & Auto"
    case travel   = "Travel"
    case retail   = "Shopping"
    case other    = "Other"

    var sfSymbol: String {
        switch self {
        case .grocery: return "cart.fill"
        case .dining:  return "fork.knife"
        case .gas:     return "fuelpump.fill"
        case .travel:  return "airplane"
        case .retail:  return "bag.fill"
        case .other:   return "creditcard.fill"
        }
    }

    var color: Color {
        switch self {
        case .grocery: return .green
        case .dining:  return .orange
        case .gas:     return .red
        case .travel:  return .blue
        case .retail:  return .purple
        case .other:   return .gray
        }
    }
}

// MARK: - Reward Currency
// Different card programs have different point values when redeemed optimally
// (transfer partners / travel portal). Cash back is always 1¢/point.

enum RewardCurrency: String, CaseIterable, Codable {
    case chaseUR         = "Chase Ultimate Rewards"
    case amexMR          = "Amex Membership Rewards"
    case citiTY          = "Citi ThankYou Points"
    case capitalOneMiles = "Capital One Miles"
    case wellsFargoRW    = "Wells Fargo Rewards"
    case usBankPoints    = "US Bank Rewards"
    case biltPoints      = "Bilt Points"
    case deltaMiles      = "Delta SkyMiles"
    case hiltonPoints    = "Hilton Honors Points"
    case hyattPoints     = "World of Hyatt Points"
    case marriottBonvoy  = "Marriott Bonvoy Points"
    case unitedMiles     = "United MileagePlus"
    case cashBack        = "Cash Back"

    /// Estimated value per point in cents — TPG April 2026 valuations.
    var centsPerPoint: Double {
        switch self {
        case .chaseUR:         return 2.0
        case .amexMR:          return 2.0
        case .citiTY:          return 1.7
        case .capitalOneMiles: return 1.7
        case .biltPoints:      return 1.67
        case .hyattPoints:     return 1.7
        case .unitedMiles:     return 1.35
        case .wellsFargoRW:    return 1.5
        case .usBankPoints:    return 1.5
        case .deltaMiles:      return 1.2
        case .marriottBonvoy:  return 0.7
        case .hiltonPoints:    return 0.5
        case .cashBack:        return 1.0
        }
    }

    /// Short label shown in UI.
    var shortLabel: String {
        switch self {
        case .chaseUR:         return "UR pts"
        case .amexMR:          return "MR pts"
        case .citiTY:          return "TY pts"
        case .capitalOneMiles: return "miles"
        case .wellsFargoRW:    return "pts"
        case .usBankPoints:    return "pts"
        case .biltPoints:      return "Bilt pts"
        case .deltaMiles:      return "Delta miles"
        case .hiltonPoints:    return "Hilton pts"
        case .hyattPoints:     return "Hyatt pts"
        case .marriottBonvoy:  return "Bonvoy pts"
        case .unitedMiles:     return "United miles"
        case .cashBack:        return "cash back"
        }
    }
}

// MARK: - Credit Card

struct CreditCard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var lastFour: String
    var colorHex: String
    var network: CardNetwork
    /// Maps StoreCategory.rawValue → points multiplier (e.g. "Grocery" → 3.0)
    var rewards: [String: Double]
    /// Point/mile currency this card earns — determines real-world value per point
    var rewardCurrency: RewardCurrency = .cashBack
    /// Optional quarterly spend caps per category (category.rawValue → dollar limit, 0 = no cap)
    var caps: [String: Double] = [:]

    // MARK: Helpers

    func multiplier(for category: StoreCategory) -> Double {
        rewards[category.rawValue] ?? rewards[StoreCategory.other.rawValue] ?? 1.0
    }

    func cap(for category: StoreCategory) -> Double {
        caps[category.rawValue] ?? 0
    }

    var baseMultiplier: Double {
        rewards[StoreCategory.other.rawValue] ?? 1.0
    }

    var displayColor: Color {
        Color(hex: colorHex) ?? .black
    }

    /// Estimated cash value per dollar spent in a category (cents).
    func estimatedValue(for category: StoreCategory) -> Double {
        multiplier(for: category) * rewardCurrency.centsPerPoint
    }
}

// MARK: - Card Network

enum CardNetwork: String, CaseIterable, Codable {
    case visa       = "Visa"
    case mastercard = "Mastercard"
    case amex       = "American Express"
    case discover   = "Discover"

    var sfSymbol: String {
        switch self {
        case .visa:       return "v.circle.fill"
        case .mastercard: return "m.circle.fill"
        case .amex:       return "a.circle.fill"
        case .discover:   return "d.circle.fill"
        }
    }
}

// MARK: - Merchant Intelligence context

struct MerchantContext {
    var category: StoreCategory
    var confidence: Double
    var merchantName: String
    var enrichedName: String
    var contextTag: String
    var signals: [String]
}

// MARK: - Widget Entry Data

struct WidgetData: Codable, Identifiable {
    var id: Date { updatedAt }
    var placeName: String
    var enrichedPlaceName: String
    var contextTag: String
    var confidence: Double
    var category: StoreCategory
    var bestCardName: String
    var bestCardLastFour: String
    var bestCardColorHex: String
    var bestCardNetwork: CardNetwork
    var multiplier: Double
    /// Point currency of the best card (for value calculation)
    var bestCardCurrency: RewardCurrency = .cashBack
    /// Runner-up card info (empty strings = no runner-up)
    var runnerUpName: String = ""
    var runnerUpMultiplier: Double = 0
    var runnerUpCurrency: RewardCurrency = .cashBack
    var updatedAt: Date

    // MARK: Derived display strings

    var rewardLabel: String {
        let mult = formatMult(multiplier)
        return "\(mult)× \(category.rawValue)"
    }

    var actionLine: String { "Use \(bestCardName) → \(rewardLabel)" }

    /// Estimated cash value per dollar spent, in cents.
    var estimatedCentsPerDollar: Double {
        multiplier * bestCardCurrency.centsPerPoint
    }

    /// e.g. "≈ 8¢ / dollar"  or  "≈ $0.08 / dollar"
    var valueLabel: String {
        let cents = estimatedCentsPerDollar
        if cents >= 1 {
            return String(format: "≈ %.1f¢ per dollar", cents)
        }
        return String(format: "≈ $%.3f per dollar", cents / 100)
    }

    static var placeholder: WidgetData {
        WidgetData(
            placeName:         "Whole Foods",
            enrichedPlaceName: "Whole Foods · Morning Commute",
            contextTag:        "Morning Commute",
            confidence:        0.9,
            category:          .grocery,
            bestCardName:      "Amex Gold",
            bestCardLastFour:  "1234",
            bestCardColorHex:  "#C9A84C",
            bestCardNetwork:   .amex,
            multiplier:        4.0,
            bestCardCurrency:  .amexMR,
            runnerUpName:      "Amex Blue Cash Preferred",
            runnerUpMultiplier: 6.0,
            runnerUpCurrency:  .cashBack,
            updatedAt:         Date()
        )
    }

    static var empty: WidgetData {
        WidgetData(
            placeName:        "Add cards in app",
            enrichedPlaceName: "Add cards in app",
            contextTag:       "",
            confidence:       0.0,
            category:         .other,
            bestCardName:     "No cards set up",
            bestCardLastFour: "----",
            bestCardColorHex: "#888888",
            bestCardNetwork:  .visa,
            multiplier:       1.0,
            updatedAt:        Date()
        )
    }

    private func formatMult(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str = String(str.dropFirst()) }
        guard str.count == 6, let rgb = UInt64(str, radix: 16) else { return nil }
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >>  8) & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }

    func toHex() -> String {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
