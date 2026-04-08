import ActivityKit
import Combine
import SwiftUI

/// Manages the Live Activity lifecycle.
///
/// The Live Activity is visible in:
///   - Dynamic Island (compact + expanded) — shown when user double-clicks side button to pay
///   - Lock Screen               — shown as a banner below the clock
///
/// One activity runs at a time. When a new merchant is detected, the existing
/// activity is updated (not replaced) to avoid flicker.
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<PointMaximizerAttributes>?

    // MARK: - Public

    /// Start or update the Live Activity for the given merchant + card.
    func update(context: MerchantContext, card: CreditCard, multiplier: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = PointMaximizerAttributes.ContentState(
            merchantName:   context.enrichedName.isEmpty ? context.merchantName : context.enrichedName,
            contextTag:     context.contextTag,
            categorySymbol: storeCategorySymbol(context.category),
            categoryColor:  storeCategoryColorHex(context.category),
            cardName:       card.name,
            cardLastFour:   card.lastFour,
            cardColorHex:   card.colorHex,
            multiplier:     multiplier,
            rewardCategory: context.category.rawValue
        )

        if let existing = currentActivity {
            // Update in-place — no interruption to the user
            Task {
                await existing.update(
                    ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))
                )
            }
        } else {
            startNew(state: state)
        }
    }

    /// End the activity (call when app moves to background or user leaves store area).
    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .after(Date().addingTimeInterval(300)))
            currentActivity = nil
        }
    }

    // MARK: - Private

    private func startNew(state: PointMaximizerAttributes.ContentState) {
        let attributes = PointMaximizerAttributes()
        let content    = ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("[LiveActivityManager] Could not start activity: \(error)")
        }
    }

    // MARK: - Category helpers

    private func storeCategorySymbol(_ category: StoreCategory) -> String {
        switch category {
        case .grocery: return "cart.fill"
        case .dining:  return "fork.knife"
        case .gas:     return "fuelpump.fill"
        case .travel:  return "airplane"
        case .retail:  return "bag.fill"
        case .other:   return "creditcard.fill"
        }
    }

    private func storeCategoryColorHex(_ category: StoreCategory) -> String {
        switch category {
        case .grocery: return "#34C759"
        case .dining:  return "#FF9500"
        case .gas:     return "#FF3B30"
        case .travel:  return "#007AFF"
        case .retail:  return "#AF52DE"
        case .other:   return "#8E8E93"
        }
    }
}
