import SwiftUI
import WidgetKit

// MARK: - Entry View dispatcher

struct PointMaximizerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PointMaximizerEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    LockCircularView(data: entry.widgetData)
        case .accessoryRectangular: LockRectView(data: entry.widgetData)
        case .accessoryInline:      LockInlineView(data: entry.widgetData)
        case .systemSmall:          HomeSmallView(data: entry.widgetData)
        case .systemMedium:         HomeMediumView(data: entry.widgetData)
        default:                    LockRectView(data: entry.widgetData)
        }
    }
}

// MARK: - Deep-link URL builder
// Encodes card + category so the app can scroll to the right card on open.

private func deepLinkURL(for data: WidgetData) -> URL {
    var comps = URLComponents()
    comps.scheme = "pointmaximizer"
    comps.host   = "open"
    comps.queryItems = [
        URLQueryItem(name: "card",     value: data.bestCardLastFour),
        URLQueryItem(name: "category", value: data.category.rawValue),
    ]
    return comps.url ?? URL(string: "pointmaximizer://open")!
}

// MARK: - Lock Screen · Circular  (square icon below the clock)
//
// The compact square slot that shows a card icon + "Pay" label.
// Tap deep-links into the app which shows CardRecommendationSheet.

struct LockCircularView: View {
    let data: WidgetData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Check")
                    .font(.system(size: 9, weight: .bold))
            }
            .widgetAccentable()
        }
        .widgetURL(deepLinkURL(for: data))
    }
}

// MARK: - Lock Screen · Rectangular  ← primary layout
//
// Layout (3 rows):
//   Row 1: [icon]  Merchant name · context tag
//   Row 2: [arrow] Use <Card Name>
//   Row 3:         4× Dining                        (prominent multiplier)

struct LockRectView: View {
    let data: WidgetData

    var body: some View {
        Link(destination: deepLinkURL(for: data)) {
            VStack(alignment: .leading, spacing: 3) {

                // Row 1 — enriched merchant name
                HStack(spacing: 5) {
                    Image(systemName: data.category.sfSymbol)
                        .font(.system(size: 11, weight: .semibold))
                    Text(data.enrichedPlaceName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white.opacity(0.75))

                // Row 2 — action line: "Use Amex Gold →"
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Use \(data.bestCardName)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                // Row 3 — reward punch
                Text(data.rewardLabel)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(rewardCapsuleColor(data.multiplier).opacity(0.35))
                    )
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func rewardCapsuleColor(_ v: Double) -> Color {
        v >= 4 ? .green : v >= 2 ? .orange : .white
    }
}

// MARK: - Lock Screen · Inline  (single line above clock)

struct LockInlineView: View {
    let data: WidgetData

    var body: some View {
        Label {
            // "Amex Gold  4× Dining"
            Text("\(data.bestCardName)  \(data.rewardLabel)")
        } icon: {
            Image(systemName: data.category.sfSymbol)
        }
        .widgetAccentable()
    }
}

// MARK: - Home Screen · Small

struct HomeSmallView: View {
    let data: WidgetData

    private var cardColor: Color { Color(hex: data.bestCardColorHex) ?? .black }

    var body: some View {
        Link(destination: deepLinkURL(for: data)) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.55)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                VStack(alignment: .leading, spacing: 4) {
                    // Category icon
                    Image(systemName: data.category.sfSymbol)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    // Reward punch
                    Text(data.rewardLabel)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    // Action line
                    Text("Use \(data.bestCardName)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)

                    // Card digits + context tag
                    HStack {
                        Text("••\(data.bestCardLastFour)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                        if !data.contextTag.isEmpty {
                            Text("· \(data.contextTag)")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Home Screen · Medium

struct HomeMediumView: View {
    let data: WidgetData

    private var cardColor: Color { Color(hex: data.bestCardColorHex) ?? .black }

    var body: some View {
        Link(destination: deepLinkURL(for: data)) {
            ZStack {
                LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack(spacing: 0) {
                    // Left: location context
                    VStack(alignment: .leading, spacing: 6) {
                        Label(data.category.rawValue, systemImage: data.category.sfSymbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))

                        Text(data.enrichedPlaceName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if !data.contextTag.isEmpty {
                            Text(data.contextTag)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.65))
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)

                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1)
                        .padding(.vertical, 12)

                    // Right: reward punch
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(data.rewardLabel)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Use \(data.bestCardName)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)

                        Text("•••• \(data.bestCardLastFour)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                            Text("Tap for best card")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 14)
                }
                .padding(.vertical, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Previews

#Preview("Lock Rect — Airport Override", as: .accessoryRectangular) {
    PointMaximizerWidget()
} timeline: {
    PointMaximizerEntry(date: .now, widgetData: WidgetData(
        placeName: "Starbucks",
        enrichedPlaceName: "Starbucks · Airport Terminal",
        contextTag: "Airport Terminal",
        confidence: 0.88,
        category: .travel,
        bestCardName: "Chase Sapphire Reserve",
        bestCardLastFour: "5678",
        bestCardColorHex: "#1B3A6B",
        bestCardNetwork: .visa,
        multiplier: 3.0,
        updatedAt: .now
    ))
}

#Preview("Lock Rect — Grocery", as: .accessoryRectangular) {
    PointMaximizerWidget()
} timeline: {
    PointMaximizerEntry(date: .now, widgetData: .placeholder)
}

#Preview("Home Medium", as: .systemMedium) {
    PointMaximizerWidget()
} timeline: {
    PointMaximizerEntry(date: .now, widgetData: .placeholder)
}

#Preview("Home Small", as: .systemSmall) {
    PointMaximizerWidget()
} timeline: {
    PointMaximizerEntry(date: .now, widgetData: .placeholder)
}
