import PassKit
import UIKit

// MARK: - Wallet Import Candidate

struct WalletCard: Identifiable {
    let id: String
    /// Card name as it appears in Apple Wallet (e.g. "Chase Sapphire Preferred")
    let displayName: String
    /// Last 4 digits
    let lastFour: String
    let network: CardNetwork
    /// Auto-matched preset from our reward database, or nil if unknown card
    let matchedPreset: PresetCard?

    var cardName: String { matchedPreset?.name ?? displayName }
    var colorHex: String { matchedPreset?.colorHex ?? "#888888" }
    var rewards: [StoreCategory: Double] {
        if let preset = matchedPreset { return preset.rewards }
        let pairs: [(StoreCategory, Double)] = StoreCategory.allCases.map { ($0, 1.0) }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}

// MARK: - CardNetwork ← PKPaymentNetwork

extension CardNetwork {
    /// Infer the network from the card's display name in Apple Wallet.
    static func inferred(from name: String) -> CardNetwork {
        let lower = name.lowercased()
        if lower.contains("amex") || lower.contains("american express") { return .amex }
        if lower.contains("mastercard")                                  { return .mastercard }
        if lower.contains("discover")                                    { return .discover }
        return .visa
    }
}

// MARK: - WalletManager

/// Handles all Apple Wallet interactions:
/// - Reads payment passes to enable card import (via PKSecureElementPass, iOS 13.4+)
/// - Opens Wallet directly to the recommended card
final class WalletManager {
    static let shared = WalletManager()

    // MARK: - Wallet availability

    var isWalletAvailable: Bool {
        PKPassLibrary.isPassLibraryAvailable()
    }

    // MARK: - Import cards from Apple Wallet

    /// Reads all payment passes from the user's Wallet and attempts to
    /// auto-match each one against the CardPresets reward database.
    /// Returns candidates sorted: matched cards first, then unmatched.
    func readWalletCards() -> [WalletCard] {
        guard PKPassLibrary.isPassLibraryAvailable() else { return [] }

        // PKPaymentPass was deprecated iOS 13.4; use PKSecureElementPass instead.
        // Both share the same properties (primaryAccountNumberSuffix, paymentNetwork, etc.)
        let allPasses = PKPassLibrary().passes(of: .payment)
        let securePasses = allPasses.compactMap { $0 as? PKSecureElementPass }

        var cards: [WalletCard] = []
        for pass in securePasses {
            let name:     String = pass.localizedName
            let lastFour: String = pass.primaryAccountNumberSuffix
            let passID:   String = pass.primaryAccountIdentifier

            // paymentNetwork was removed from PassKit in recent SDKs.
            // Infer the network from the card's display name instead.
            let network = CardNetwork.inferred(from: name)

            let preset = CardPresets.match(walletName: name, network: network)
            cards.append(WalletCard(
                id:            passID,
                displayName:   name,
                lastFour:      lastFour,
                network:       network,
                matchedPreset: preset
            ))
        }

        // Matched cards first
        return cards.sorted { a, b in
            (a.matchedPreset != nil) && (b.matchedPreset == nil)
        }
    }

    // MARK: - Open Wallet to specific card

    @discardableResult
    func openWallet(for card: CreditCard) -> Bool {
        if let pass = findPass(matching: card.lastFour),
           let passURL = pass.passURL {
            UIApplication.shared.open(passURL)
            return true
        }
        openWalletGeneric()
        return false
    }

    func openWalletGeneric() {
        if let url = URL(string: "shoebox://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Pass lookup

    /// Returns the PKSecureElementPass whose last-4 suffix matches, or nil.
    func findPass(matching lastFour: String) -> PKSecureElementPass? {
        guard PKPassLibrary.isPassLibraryAvailable() else { return nil }
        let passes = PKPassLibrary().passes(of: .payment)
        return passes
            .compactMap { $0 as? PKSecureElementPass }
            .first { $0.primaryAccountNumberSuffix == lastFour }
    }

    func isInWallet(_ card: CreditCard) -> Bool {
        findPass(matching: card.lastFour) != nil
    }

    // MARK: - Face ID hint

    var faceIDHint: String {
        "Double-click side button to pay with Face ID"
    }
}
