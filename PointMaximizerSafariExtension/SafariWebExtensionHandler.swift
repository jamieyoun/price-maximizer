import SafariServices
import os.log

/// Native host for the Safari Web Extension.
/// Receives a message from popup.js containing the current page domain,
/// looks up the best card recommendation from App Groups, and returns
/// the result as a dictionary back to JavaScript.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let log = OSLog(subsystem: "com.yourcompany.pointmaximizer", category: "SafariExtension")

    func beginRequest(with context: NSExtensionContext) {
        guard
            let item    = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any]
        else {
            context.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        let domain   = message["domain"] as? String ?? ""
        let response = buildResponse(for: domain)

        let item2 = NSExtensionItem()
        item2.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [item2], completionHandler: nil)
    }

    // MARK: - Build recommendation

    private func buildResponse(for domain: String) -> [String: Any] {
        let (category, displayName) = DomainCategoryMapper.category(for: domain)

        guard let (card, multiplier) = SharedDataManager.shared.bestCard(for: category) else {
            return [
                "hasCards":    false,
                "displayName": displayName,
                "category":    category.rawValue,
            ]
        }

        let mult = multiplier.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(multiplier))
            : String(format: "%.1f", multiplier)

        return [
            "hasCards":      true,
            "displayName":   displayName,
            "category":      category.rawValue,
            "categoryIcon":  category.sfSymbol,
            "cardName":      card.name,
            "cardLastFour":  card.lastFour,
            "cardColorHex":  card.colorHex,
            "multiplier":    multiplier,
            "rewardLabel":   "\(mult)× \(category.rawValue)",
            "actionLine":    "Use \(card.name) → \(mult)× \(category.rawValue)",
        ]
    }
}
