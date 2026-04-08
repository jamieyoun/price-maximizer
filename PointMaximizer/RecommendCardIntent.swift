import AppIntents

// MARK: - Siri Shortcut: "Hey Siri, which card should I use?"
//
// Reads the latest WidgetData snapshot (written by LocationManager whenever
// the user taps the widget) and speaks back the best card + reward.
//
// Supported phrases (all automatically wired by AppShortcutsProvider):
//   "Which card should I use with Point Maximizer?"
//   "Best card with Point Maximizer"
//   "Check my card with Point Maximizer"

struct RecommendCardIntent: AppIntent {

    static var title: LocalizedStringResource = "Get Best Card Recommendation"
    static var description = IntentDescription(
        "Tells you which credit card earns the most points at your current location."
    )

    // No parameters — reads from the shared snapshot written by the app.
    @MainActor
    func perform() async throws -> some ProvidesDialog & ReturnsValue<String> {

        let data = SharedDataManager.shared.loadWidgetData()

        // No cards set up yet
        guard data.bestCardName != "No cards set up",
              !data.bestCardLastFour.isEmpty else {
            return .result(
                value: "No recommendation",
                dialog: "Add your credit cards in the Point Maximizer app first."
            )
        }

        // e.g. "Use your Amex Gold — 4× Membership Rewards on Grocery."
        let mult = data.multiplier.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(data.multiplier))"
            : String(format: "%.1f", data.multiplier)

        let dialog = "Use your \(data.bestCardName) — \(mult)× \(data.bestCardCurrency.shortLabel) on \(data.category.rawValue)."

        return .result(value: data.bestCardName, dialog: IntentDialog(stringLiteral: dialog))
    }
}

// MARK: - Shortcut phrases registered with the system

struct PointMaximizerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecommendCardIntent(),
            phrases: [
                "Which card should I use with \(.applicationName)?",
                "Best card with \(.applicationName)",
                "Check my card with \(.applicationName)",
                "What card earns the most with \(.applicationName)?",
            ],
            shortTitle: "Best Card Now",
            systemImageName: "creditcard.fill"
        )
    }
}
