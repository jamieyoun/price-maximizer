import SwiftUI

// MARK: - Card Selector
//
// Apple's PKPassLibrary requires a bank-level entitlement to read payment cards —
// unavailable to third-party apps. Instead, we show all 24 presets grouped by
// issuer. The user taps the cards they carry, enters the last 4 digits of each,
// and we auto-fill the reward rates from our preset database.

struct WalletImportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selections: [String: String] = [:]
    @State private var focusedCard: String? = nil
    @State private var searchText = ""

    private var selectedCount: Int { selections.values.filter { !$0.isEmpty }.count }
    private var isSearching: Bool { !searchText.isEmpty }

    private let popularNames = [
        "Chase Sapphire Preferred",
        "Chase Freedom Unlimited",
        "Chase Sapphire Reserve",
        "Amex Gold",
        "Amex Platinum",
        "Amex Blue Cash Preferred",
        "Citi Double Cash",
        "Capital One Venture",
    ]
    private var popularPresets: [PresetCard] {
        popularNames.compactMap { n in CardPresets.all.first { $0.name == n } }
    }

    private var searchResults: [PresetCard] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return CardPresets.all.filter { $0.name.lowercased().contains(q) }
    }

    private var issuers: [(name: String, cards: [PresetCard])] {
        [
            ("Chase",           CardPresets.all.filter { $0.name.hasPrefix("Chase") }),
            ("Amex",            CardPresets.all.filter { $0.name.hasPrefix("Amex") }),
            ("Citi",            CardPresets.all.filter { $0.name.hasPrefix("Citi") }),
            ("Capital One",     CardPresets.all.filter { $0.name.hasPrefix("Capital One") }),
            ("Discover",        CardPresets.all.filter { $0.name.hasPrefix("Discover") }),
            ("Bank of America", CardPresets.all.filter { $0.name.hasPrefix("BofA") }),
            ("Wells Fargo",     CardPresets.all.filter { $0.name.hasPrefix("Wells Fargo") }),
            ("US Bank",         CardPresets.all.filter { $0.name.hasPrefix("US Bank") }),
            ("Bilt",            CardPresets.all.filter { $0.name.hasPrefix("Bilt") }),
            ("Apple",           CardPresets.all.filter { $0.name.hasPrefix("Apple") }),
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                // Search bar
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search 41 cards…", text: $searchText)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isSearching {
                    // MARK: Search results
                    if searchResults.isEmpty {
                        Section {
                            Text("No cards match \"\(searchText)\"")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    } else {
                        Section("Results") {
                            ForEach(searchResults, id: \.name) { preset in
                                selectorRow(preset)
                            }
                        }
                    }
                } else {
                    // MARK: Popular picks
                    Section("Most Popular") {
                        ForEach(popularPresets, id: \.name) { preset in
                            selectorRow(preset)
                        }
                    }

                    // MARK: All cards by issuer
                    ForEach(issuers, id: \.name) { issuer in
                        Section(issuer.name) {
                            ForEach(issuer.cards, id: \.name) { preset in
                                selectorRow(preset)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Your Cards")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.spring(response: 0.3), value: isSearching)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedCount == 0 ? "Add Cards" : "Add \(selectedCount)") { save() }
                        .fontWeight(.semibold)
                        .disabled(selectedCount == 0)
                }
            }
        }
    }

    // MARK: - Shared row builder

    @ViewBuilder
    private func selectorRow(_ preset: PresetCard) -> some View {
        CardSelectorRow(
            preset:   preset,
            lastFour: Binding(
                get: { selections[preset.name] },
                set: { selections[preset.name] = $0 }
            ),
            isFocused: focusedCard == preset.name,
            onTap: { handleTap(preset.name) }
        )
    }

    // MARK: - Actions

    private func handleTap(_ name: String) {
        if selections[name] != nil {
            selections.removeValue(forKey: name)
            if focusedCard == name { focusedCard = nil }
        } else {
            selections[name] = ""
            focusedCard = name
        }
    }

    private func save() {
        var existing = SharedDataManager.shared.loadCards()
        let existingLastFours = Set(existing.map { $0.lastFour })

        for preset in CardPresets.all {
            guard let lastFour = selections[preset.name],
                  lastFour.count == 4,
                  !existingLastFours.contains(lastFour) else { continue }

            var card = CreditCard(
                name:           preset.name,
                lastFour:       lastFour,
                colorHex:       preset.colorHex,
                network:        preset.network,
                rewards:        Dictionary(uniqueKeysWithValues:
                                    preset.rewards.map { ($0.key.rawValue, $0.value) }),
                rewardCurrency: preset.rewardCurrency
            )
            card.caps = Dictionary(uniqueKeysWithValues:
                preset.caps.map { ($0.key.rawValue, $0.value) }
            )
            existing.append(card)
        }

        SharedDataManager.shared.saveCards(existing)
        dismiss()
    }
}

// MARK: - Card selector row

private struct CardSelectorRow: View {
    let preset: PresetCard
    @Binding var lastFour: String?
    let isFocused: Bool
    let onTap: () -> Void

    private var isSelected: Bool { lastFour != nil }
    private var cardColor: Color { Color(hex: preset.colorHex) ?? .gray }

    // Top two reward categories above 1×
    private var topRewards: String {
        preset.rewards
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { "\(formatMult($0.value))× \($0.key.rawValue)" }
            .joined(separator: "  ·  ")
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Mini card chip
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [cardColor, cardColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 34)
                        .overlay(
                            Text(preset.network.rawValue.prefix(4))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(preset.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if !topRewards.isEmpty {
                            Text(topRewards)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : Color(.systemGray3))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Last-4 entry — slides in when selected
            if isSelected {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Last 4 digits:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 1234",
                              text: Binding(
                                get: { lastFour ?? "" },
                                set: { lastFour = String($0.filter(\.isNumber).prefix(4)) }
                              ))
                        .keyboardType(.numberPad)
                        .font(.system(.subheadline, design: .monospaced))
                        .frame(maxWidth: 80)
                    Spacer()
                    if (lastFour ?? "").count == 4 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private func formatMult(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}
