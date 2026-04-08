import SwiftUI

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name      = ""
    @State private var lastFour  = ""
    @State private var network: CardNetwork = .visa
    @State private var cardColor: Color = .black
    @State private var rewards: [StoreCategory: Double] = {
        Dictionary(uniqueKeysWithValues: StoreCategory.allCases.map { ($0, 1.0) })
    }()
    @State private var caps: [StoreCategory: Double] = [:]

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    // Top 8 by cardholder popularity
    private let topPresets: [PresetCard] = {
        let names = [
            "Chase Sapphire Preferred",
            "Chase Freedom Unlimited",
            "Chase Sapphire Reserve",
            "Amex Gold",
            "Amex Platinum",
            "Amex Blue Cash Preferred",
            "Citi Double Cash",
            "Capital One Venture",
        ]
        return names.compactMap { n in CardPresets.all.first { $0.name == n } }
    }()

    private var searchResults: [PresetCard] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return CardPresets.all.filter { $0.name.lowercased().contains(q) }
    }

    private var isSearching: Bool { !searchText.isEmpty }

    var body: some View {
        NavigationView {
            Form {

                // MARK: Search
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search cards (e.g. Sapphire, Gold…)", text: $searchText)
                            .focused($searchFocused)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchFocused = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: Search results (replaces quick start while typing)
                if isSearching {
                    if searchResults.isEmpty {
                        Section {
                            Text("No cards match \"\(searchText)\"")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    } else {
                        Section("Results") {
                            ForEach(searchResults, id: \.name) { preset in
                                searchResultRow(preset)
                            }
                        }
                    }
                } else {
                    // MARK: Quick Start (top 8)
                    Section("Quick Start — Tap a Popular Card") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(topPresets, id: \.name) { preset in
                                    presetButton(preset)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                // MARK: Card Info
                Section("Card Info") {
                    TextField("Card Name (e.g. Chase Sapphire Preferred)", text: $name)
                    TextField("Last 4 Digits", text: $lastFour)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFour) { _, newVal in
                            lastFour = String(newVal.filter(\.isNumber).prefix(4))
                        }
                    Picker("Network", selection: $network) {
                        ForEach(CardNetwork.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    ColorPicker("Card Color", selection: $cardColor, supportsOpacity: false)
                }

                // MARK: Reward Multipliers
                Section("Reward Multipliers (× points)") {
                    ForEach(StoreCategory.allCases, id: \.self) { cat in
                        HStack {
                            Label(cat.rawValue, systemImage: cat.sfSymbol)
                                .foregroundColor(cat.color)
                            Spacer()
                            Stepper(
                                value: Binding(
                                    get: { rewards[cat] ?? 1.0 },
                                    set: { rewards[cat] = $0 }
                                ),
                                in: 1...20,
                                step: 0.5
                            ) {
                                Text("\(formatMultiplier(rewards[cat] ?? 1.0))×")
                                    .frame(minWidth: 36, alignment: .trailing)
                                    .font(.subheadline.monospacedDigit())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || lastFour.count != 4)
                }
            }
            .animation(.spring(response: 0.3), value: isSearching)
        }
    }

    // MARK: - Search result row

    @ViewBuilder
    private func searchResultRow(_ preset: PresetCard) -> some View {
        Button {
            applyPreset(preset)
            searchText = ""
            searchFocused = false
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [Color(hex: preset.colorHex) ?? .gray,
                                 (Color(hex: preset.colorHex) ?? .gray).opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 28)
                    .overlay(
                        Text(preset.network.rawValue.prefix(4))
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(topRewardSummary(preset))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Start button

    @ViewBuilder
    private func presetButton(_ preset: PresetCard) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: preset.colorHex) ?? .black)
                    .frame(width: 80, height: 50)
                    .overlay(
                        Image(systemName: preset.network.sfSymbol)
                            .foregroundColor(.white.opacity(0.8))
                    )
                Text(preset.name)
                    .font(.system(size: 9))
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func topRewardSummary(_ preset: PresetCard) -> String {
        preset.rewards
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { "\(formatMultiplier($0.value))× \($0.key.rawValue)" }
            .joined(separator: "  ·  ")
    }

    private func applyPreset(_ preset: PresetCard) {
        name      = preset.name
        network   = preset.network
        cardColor = Color(hex: preset.colorHex) ?? .black
        rewards   = preset.rewards
        caps      = preset.caps
    }

    private func save() {
        var card = CreditCard(
            name:     name,
            lastFour: lastFour,
            colorHex: cardColor.toHex(),
            network:  network,
            rewards:  [:]
        )
        card.rewards = Dictionary(uniqueKeysWithValues:
            rewards.map { ($0.key.rawValue, $0.value) }
        )
        card.caps = Dictionary(uniqueKeysWithValues:
            caps.map { ($0.key.rawValue, $0.value) }
        )
        var cards = SharedDataManager.shared.loadCards()
        cards.append(card)
        SharedDataManager.shared.saveCards(cards)
        dismiss()
    }

    private func formatMultiplier(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}
