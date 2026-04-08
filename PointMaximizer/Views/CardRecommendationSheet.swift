import Combine
import SwiftUI

// MARK: - Checkout sheet
// Spinner while resolving location → full Pickr-style recommendation with:
//   • Estimated cash value per dollar
//   • Runner-up card
//   • "Log spend" after Open Wallet tap

struct CardRecommendationSheet: View {
    @Binding var resolvedData: WidgetData?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let data = resolvedData {
            CardResultView(data: data)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            CheckingView()
        }
    }
}

// MARK: - Checking spinner

private struct CheckingView: View {
    @State private var dots = ""
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
            Text("Checking your location\(dots)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .animation(nil, value: dots)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            dots = dots.count >= 3 ? "" : dots + "."
        }
    }
}

// MARK: - Card result view

private struct CardResultView: View {
    let data: WidgetData
    @Environment(\.dismiss) private var dismiss

    @State private var showSpendLog = false
    @State private var spendAmount: Double? = nil
    @State private var didLogSpend = false

    private var cardColor: Color { Color(hex: data.bestCardColorHex) ?? .black }
    private var hasRunnerUp: Bool { !data.runnerUpName.isEmpty && data.runnerUpMultiplier > 0 }

    private var multiplierText: String {
        let m = data.multiplier
        return m.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(m))×" : String(format: "%.1f×", m)
    }

    private var displayName: String {
        data.enrichedPlaceName.isEmpty ? data.placeName : data.enrichedPlaceName
    }

    var body: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // ── Merchant header ──────────────────────────────────
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 50)
                    Image(systemName: data.category.sfSymbol)
                        .font(.system(size: 22))
                        .foregroundStyle(Color(.label))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(data.category.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)

            // ── Credit card graphic ──────────────────────────────
            LargeCardGraphic(data: data)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // ── Multiplier ───────────────────────────────────────
            VStack(spacing: 4) {
                Text(multiplierText)
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(Color(.label))
                Text(data.bestCardCurrency.shortLabel)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // ── Runner-up card ───────────────────────────────────
            if hasRunnerUp {
                RunnerUpRow(data: data)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
            }

            Spacer(minLength: 12)

            // ── Spend log (appears after Open Wallet tap) ────────
            if showSpendLog && !didLogSpend {
                SpendLogRow(
                    category: data.category,
                    amount: $spendAmount
                ) {
                    if let amount = spendAmount {
                        let cards = SharedDataManager.shared.loadCards()
                        if let card = cards.first(where: { $0.lastFour == data.bestCardLastFour }) {
                            SharedDataManager.shared.recordSpend(
                                cardID: card.id,
                                category: data.category,
                                amount: amount
                            )
                        }
                    }
                    didLogSpend = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── Open Wallet CTA ──────────────────────────────────
            Button(action: openWallet) {
                HStack(spacing: 6) {
                    Text(didLogSpend ? "Wallet Opened ✓" : "Open Wallet")
                        .font(.headline)
                    if !didLogSpend {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(didLogSpend ? Color(.systemGray4) : Color(.label))
                .foregroundStyle(didLogSpend ? Color(.label) : Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(didLogSpend)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .animation(.spring(response: 0.3), value: didLogSpend)
        }
        .background(Color(.systemBackground))
    }

    private func openWallet() {
        let cards = SharedDataManager.shared.loadCards()
        if let card = cards.first(where: { $0.lastFour == data.bestCardLastFour }) {
            WalletManager.shared.openWallet(for: card)
        } else {
            WalletManager.shared.openWalletGeneric()
        }
        withAnimation { showSpendLog = true }
    }
}

// MARK: - Runner-up row

private struct RunnerUpRow: View {
    let data: WidgetData

    private var multText: String {
        let m = data.runnerUpMultiplier
        return m.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(m))×" : String(format: "%.1f×", m)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.turn.down.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text("Runner-up: \(data.runnerUpName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(multText) \(data.runnerUpCurrency.shortLabel)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Spend log inline row

private struct SpendLogRow: View {
    let category: StoreCategory
    @Binding var amount: Double?
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.sfSymbol)
                .foregroundStyle(category.color)
            Text("Log spend:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("$0", value: $amount, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .frame(maxWidth: 90)
            Spacer()
            Button("Save", action: onSave)
                .font(.subheadline.weight(.semibold))
                .disabled(amount == nil)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Large Card Graphic

struct LargeCardGraphic: View {
    let data: WidgetData
    private var cardColor: Color { Color(hex: data.bestCardColorHex) ?? .black }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    // EMV chip
                    RoundedRectangle(cornerRadius: 7)
                        .fill(LinearGradient(
                            colors: [Color.yellow.opacity(0.85), Color.orange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 34)
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    Spacer()
                    Text(data.bestCardName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                Text("**** **** **** \(data.bestCardLastFour)")
                    .font(.system(.body, design: .monospaced).weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(2)
            }
            .padding(22)
        }
        .frame(height: 185)
        .shadow(color: cardColor.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}
