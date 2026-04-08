import SwiftUI

struct CardRow: View {
    let card: CreditCard
    let category: StoreCategory

    private var multiplier: Double { card.multiplier(for: category) }

    var body: some View {
        HStack(spacing: 12) {
            // Mini card chip
            RoundedRectangle(cornerRadius: 6)
                .fill(card.displayColor)
                .frame(width: 52, height: 34)
                .overlay(
                    Text("••\(card.lastFour)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.subheadline.weight(.semibold))
                Text(card.network.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Multiplier badge
            Text("\(formatMultiplier(multiplier))x")
                .font(.title3.bold())
                .foregroundColor(multiplier >= 3 ? .green : multiplier >= 2 ? .orange : .primary)
        }
        .padding(.vertical, 4)
    }

    private func formatMultiplier(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Full card chip (used in recommendation banner)

struct CardChip: View {
    let card: CreditCard
    var width: CGFloat = 180
    var height: CGFloat = 110

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [card.displayColor, card.displayColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width, height: height)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Spacer()
                    Image(systemName: card.network.sfSymbol)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title2)
                }

                Spacer()

                Text("•••• \(card.lastFour)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.white)

                Text(card.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(10)
            .frame(width: width, height: height)
        }
        .shadow(color: card.displayColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}
