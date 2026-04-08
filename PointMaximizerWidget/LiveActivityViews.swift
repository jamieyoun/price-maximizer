import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget

struct PointMaximizerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PointMaximizerAttributes.self) { context in
            // ── Lock screen / StandBy banner ──────────────────────────────
            LockScreenBannerView(state: context.state)
                .containerBackground(.black.opacity(0.85), for: .widget)

        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded (long-press or payment moment) ───────────────
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state)
                }
            } compactLeading: {
                // ── Compact leading: category icon ────────────────────────
                Image(systemName: context.state.categorySymbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(hex: context.state.categoryColor) ?? .green)
            } compactTrailing: {
                // ── Compact trailing: multiplier ──────────────────────────
                Text(context.state.rewardLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
            } minimal: {
                // ── Minimal (another activity also running) ───────────────
                Image(systemName: context.state.categorySymbol)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: context.state.categoryColor) ?? .green)
            }
            .widgetURL(URL(string: "pointmaximizer://open?card=\(context.state.cardLastFour)"))
            .keylineTint(Color(hex: context.state.cardColorHex) ?? .white)
        }
    }
}

// MARK: - Lock Screen Banner
// Shown below the clock while the Live Activity is active.

struct LockScreenBannerView: View {
    let state: PointMaximizerAttributes.ContentState

    private var cardColor: Color { Color(hex: state.cardColorHex) ?? .black }
    private var catColor:  Color { Color(hex: state.categoryColor) ?? .green }

    var body: some View {
        Link(destination: URL(string: "pointmaximizer://open?card=\(state.cardLastFour)")!) {
            HStack(spacing: 14) {
                // Category icon
                ZStack {
                    Circle().fill(catColor.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: state.categorySymbol)
                        .foregroundStyle(catColor)
                        .font(.title3)
                }

                // Card + location
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.merchantName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("Use \(state.cardName) · ••\(state.cardLastFour)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer()

                // Reward punch
                Text(state.rewardLabel)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(catColor.opacity(0.3)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Dynamic Island Expanded regions

struct ExpandedLeadingView: View {
    let state: PointMaximizerAttributes.ContentState
    private var catColor: Color { Color(hex: state.categoryColor) ?? .green }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(state.rewardCategory, systemImage: state.categorySymbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(catColor)
            Text(state.merchantName)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            if !state.contextTag.isEmpty {
                Text(state.contextTag)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.leading, 4)
    }
}

struct ExpandedTrailingView: View {
    let state: PointMaximizerAttributes.ContentState
    private var catColor: Color { Color(hex: state.categoryColor) ?? .green }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(state.rewardLabel)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("use this card")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.trailing, 4)
    }
}

struct ExpandedBottomView: View {
    let state: PointMaximizerAttributes.ContentState
    private var cardColor: Color { Color(hex: state.cardColorHex) ?? .black }

    var body: some View {
        HStack(spacing: 10) {
            // Mini card chip
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 44, height: 28)
                .overlay(
                    Text("••\(state.cardLastFour)")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.white)
                )

            Text(state.cardName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // "Tap to open Wallet" hint
            Label("Open Wallet", systemImage: "wallet.pass.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}
