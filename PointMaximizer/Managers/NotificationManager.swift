import UserNotifications
import CoreLocation

/// Manages smart, non-annoying proactive notifications.
///
/// Throttle rules (all must pass before a notification fires):
///   • Multiplier ≥ 2× AND confidence ≥ 0.6  — not worth notifying for 1× base rate
///   • Time window: 8 am – 9 pm local time    — no late-night pings
///   • Same merchant: at most once per 2 h     — no repeat spam at the same store
///   • Daily cap: at most 4 notifications/day  — background noise limit
///   • No duplicate: same card + category as the last notification → skip
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    // UserDefaults keys
    private let lastNotifDateKey   = "pm_last_notif_date"
    private let lastNotifPlaceKey  = "pm_last_notif_place"
    private let dailyCountKey      = "pm_daily_notif_count"
    private let dailyCountDateKey  = "pm_daily_notif_count_date"
    private let lastNotifCardKey   = "pm_last_notif_card"

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { self.registerCategories() }
        }
    }

    // MARK: - Schedule

    /// Called by LocationManager whenever a new merchant context is resolved.
    func scheduleIfAppropriate(context: MerchantContext, bestCard: CreditCard, multiplier: Double) {
        guard shouldNotify(context: context, card: bestCard, multiplier: multiplier) else { return }

        let content = UNMutableNotificationContent()
        content.title  = "\(context.merchantName)"
        content.body   = "Use \(bestCard.name) · \(formatMult(multiplier))× \(context.category.rawValue)"
        content.sound  = .none   // silent — informational, not urgent
        content.categoryIdentifier = "CARD_REC"
        content.userInfo = [
            "cardLastFour": bestCard.lastFour,
            "category":     context.category.rawValue,
        ]
        // Subtle banner only — no lock-screen interruption if Live Activity is already showing
        content.interruptionLevel = .passive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pm_rec_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { [weak self] _ in
            self?.recordNotification(placeName: context.merchantName, card: bestCard)
        }
    }

    // MARK: - Throttle logic

    private func shouldNotify(context: MerchantContext, card: CreditCard, multiplier: Double) -> Bool {
        // 1. Usefulness threshold
        guard multiplier >= 2.0, context.confidence >= 0.6 else { return false }

        // 2. Time window: 8 am – 9 pm
        let hour = Calendar.current.component(.hour, from: Date())
        guard (8...21).contains(hour) else { return false }

        // 3. Same merchant within 2 hours → skip
        if let lastPlace = defaults.string(forKey: lastNotifPlaceKey),
           let lastDate  = defaults.object(forKey: lastNotifDateKey) as? Date {
            let isSameMerchant = lastPlace.lowercased() == context.merchantName.lowercased()
            let tooSoon = Date().timeIntervalSince(lastDate) < 2 * 3600
            if isSameMerchant && tooSoon { return false }
        }

        // 4. Daily cap: 4 notifications
        let today = Calendar.current.startOfDay(for: Date())
        if let countDate = defaults.object(forKey: dailyCountDateKey) as? Date,
           Calendar.current.isDate(countDate, inSameDayAs: today) {
            let count = defaults.integer(forKey: dailyCountKey)
            if count >= 4 { return false }
        }

        // 5. Same card + category as last notification → skip (no value)
        if let lastCard = defaults.string(forKey: lastNotifCardKey),
           lastCard == "\(card.lastFour)-\(context.category.rawValue)" {
            return false
        }

        return true
    }

    private func recordNotification(placeName: String, card: CreditCard) {
        defaults.set(placeName, forKey: lastNotifPlaceKey)
        defaults.set(Date(),    forKey: lastNotifDateKey)
        defaults.set("\(card.lastFour)-", forKey: lastNotifCardKey)

        // Increment daily count
        let today = Calendar.current.startOfDay(for: Date())
        if let countDate = defaults.object(forKey: dailyCountDateKey) as? Date,
           Calendar.current.isDate(countDate, inSameDayAs: today) {
            let count = defaults.integer(forKey: dailyCountKey)
            defaults.set(count + 1, forKey: dailyCountKey)
        } else {
            defaults.set(today, forKey: dailyCountDateKey)
            defaults.set(1,     forKey: dailyCountKey)
        }
    }

    // MARK: - Notification categories (actions)

    private func registerCategories() {
        let openWallet = UNNotificationAction(
            identifier: "OPEN_WALLET",
            title: "Open Wallet",
            options: [.foreground]
        )
        let dismiss = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "CARD_REC",
            actions: [openWallet, dismiss],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Helper

    private func formatMult(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}
