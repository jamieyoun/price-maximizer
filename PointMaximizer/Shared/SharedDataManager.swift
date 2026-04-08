import Foundation
import WidgetKit

final class SharedDataManager {
    static let shared = SharedDataManager()

    static let appGroupID = "group.com.yourcompany.pointmaximizer"

    private let cardsKey      = "pm_saved_cards"
    private let widgetDataKey = "pm_widget_data"
    private let spendLogKey   = "pm_spend_log"   // [cardID_category_quarterKey: Double]

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupID)!
    }

    // MARK: - Cards

    func saveCards(_ cards: [CreditCard]) {
        guard let data = try? JSONEncoder().encode(cards) else { return }
        defaults.set(data, forKey: cardsKey)
        defaults.synchronize()
    }

    func loadCards() -> [CreditCard] {
        guard let data = defaults.data(forKey: cardsKey),
              let cards = try? JSONDecoder().decode([CreditCard].self, from: data)
        else { return [] }
        return cards
    }

    // MARK: - Widget Snapshot

    func saveWidgetData(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: widgetDataKey)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadWidgetData() -> WidgetData {
        guard let data = defaults.data(forKey: widgetDataKey),
              let wd = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return .empty }
        return wd
    }

    // MARK: - Spend Tracking (for cap enforcement)

    /// Current quarter key, e.g. "2026-Q2"
    private var currentQuarterKey: String {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let month = cal.component(.month, from: Date())
        let quarter = (month - 1) / 3 + 1
        return "\(year)-Q\(quarter)"
    }

    private func spendKey(cardID: UUID, category: StoreCategory) -> String {
        "\(cardID.uuidString)_\(category.rawValue)_\(currentQuarterKey)"
    }

    func recordSpend(cardID: UUID, category: StoreCategory, amount: Double) {
        guard amount > 0 else { return }
        var log = defaults.dictionary(forKey: spendLogKey) as? [String: Double] ?? [:]
        let key = spendKey(cardID: cardID, category: category)
        log[key] = (log[key] ?? 0) + amount
        defaults.set(log, forKey: spendLogKey)
        defaults.synchronize()
    }

    func spentAmount(cardID: UUID, category: StoreCategory) -> Double {
        let log = defaults.dictionary(forKey: spendLogKey) as? [String: Double] ?? [:]
        return log[spendKey(cardID: cardID, category: category)] ?? 0
    }

    /// True if this card has hit (or passed) its quarterly cap for the given category.
    func isCapReached(for card: CreditCard, category: StoreCategory) -> Bool {
        let capLimit = card.cap(for: category)
        guard capLimit > 0 else { return false }
        return spentAmount(cardID: card.id, category: category) >= capLimit
    }

    // MARK: - Recommendation Engine

    /// Returns all cards ranked by effective value for the given category.
    /// Cards that have hit their quarterly spending cap fall back to their base rate.
    /// Sorted descending by estimated cents-per-dollar (multiplier × point value).
    func rankedCards(for category: StoreCategory) -> [(card: CreditCard, multiplier: Double, isCapped: Bool)] {
        let cards = loadCards()
        guard !cards.isEmpty else { return [] }

        var ranked: [(card: CreditCard, multiplier: Double, isCapped: Bool)] = []
        for card in cards {
            let capped = isCapReached(for: card, category: category)
            // If cap reached, use base ("other") rate instead of category rate
            let mult: Double
            if capped {
                mult = card.baseMultiplier
            } else {
                mult = card.multiplier(for: category)
            }
            ranked.append((card, mult, capped))
        }

        // Sort by estimated cash value (multiplier × centsPerPoint), descending
        return ranked.sorted { a, b in
            let aValue = a.multiplier * a.card.rewardCurrency.centsPerPoint
            let bValue = b.multiplier * b.card.rewardCurrency.centsPerPoint
            return aValue > bValue
        }
    }

    /// Best card and its effective multiplier for the given category.
    func bestCard(for category: StoreCategory) -> (CreditCard, Double)? {
        guard let top = rankedCards(for: category).first else { return nil }
        return (top.card, top.multiplier)
    }

    // MARK: - Widget Data Builder

    func buildWidgetData(
        merchantName: String,
        enrichedName: String,
        contextTag: String,
        confidence: Double,
        category: StoreCategory
    ) -> WidgetData {
        let ranked = rankedCards(for: category)
        guard let best = ranked.first else { return .empty }

        let runnerUp = ranked.count > 1 ? ranked[1] : nil

        return WidgetData(
            placeName:          merchantName,
            enrichedPlaceName:  enrichedName,
            contextTag:         contextTag,
            confidence:         confidence,
            category:           category,
            bestCardName:       best.card.name,
            bestCardLastFour:   best.card.lastFour,
            bestCardColorHex:   best.card.colorHex,
            bestCardNetwork:    best.card.network,
            multiplier:         best.multiplier,
            bestCardCurrency:   best.card.rewardCurrency,
            runnerUpName:       runnerUp?.card.name ?? "",
            runnerUpMultiplier: runnerUp?.multiplier ?? 0,
            runnerUpCurrency:   runnerUp?.card.rewardCurrency ?? .cashBack,
            updatedAt:          Date()
        )
    }
}
