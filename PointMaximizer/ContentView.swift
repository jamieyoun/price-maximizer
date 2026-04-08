import CoreLocation
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cards: [CreditCard] = []
    @State private var showAddCard = false
    @State private var showWalletImport = false

    // Search
    @State private var searchText = ""

    // Quick-add from popular strip
    @State private var quickAddPreset: PresetCard? = nil

    // Tap-to-check sheet state
    @State private var showingCheckSheet = false
    @State private var resolvedData: WidgetData? = nil

    private var context: MerchantContext { locationManager.currentContext }

    // MARK: - Popular presets (top 8)
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

    // MARK: - Search filtering
    private var filteredCards: [CreditCard] {
        guard !searchText.isEmpty else { return cards }
        let q = searchText.lowercased()
        return cards.filter { $0.name.lowercased().contains(q) }
    }
    private var presetMatches: [PresetCard] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        let existingNames = Set(cards.map { $0.name })
        return CardPresets.all.filter {
            $0.name.lowercased().contains(q) && !existingNames.contains($0.name)
        }
    }
    private var isSearching: Bool { !searchText.isEmpty }

    var body: some View {
        NavigationStack {
            List {
                if cards.isEmpty {
                    onboardingSection
                } else {
                    if isSearching {
                        searchResultsSections
                    } else {
                        howItWorksRow
                        popularSection
                        cardListSection
                    }
                }
            }
            .navigationTitle("Point Maximizer")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search your cards or add new ones…"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showWalletImport = true } label: {
                            Image(systemName: "wallet.pass.fill").font(.title3)
                        }
                        Button { showAddCard = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddCard, onDismiss: reloadCards) {
                AddCardView()
            }
            .sheet(isPresented: $showWalletImport, onDismiss: reloadCards) {
                WalletImportView()
            }
            .sheet(item: $quickAddPreset, onDismiss: reloadCards) { preset in
                QuickAddSheet(preset: preset)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            .sheet(isPresented: $showingCheckSheet, onDismiss: { resolvedData = nil }) {
                CardRecommendationSheet(resolvedData: $resolvedData)
                    .presentationDetents([.height(620)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(28)
                    .animation(.spring(response: 0.4), value: resolvedData != nil)
            }
            .onOpenURL { url in handleDeepLink(url) }
            .onAppear {
                reloadCards()
                locationManager.requestPermission()
                LiveActivityManager.shared.end()
            }
        }
    }

    // MARK: - Popular cards strip

    private var popularSection: some View {
        Section("Popular Cards") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(popularPresets, id: \.name) { preset in
                        let alreadyAdded = cards.contains { $0.name == preset.name }
                        Button {
                            if !alreadyAdded { quickAddPreset = preset }
                        } label: {
                            VStack(spacing: 5) {
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: preset.colorHex) ?? .black,
                                                         (Color(hex: preset.colorHex) ?? .black).opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 86, height: 54)
                                        .overlay(
                                            Image(systemName: preset.network.sfSymbol)
                                                .foregroundStyle(.white.opacity(0.7))
                                                .font(.system(size: 14))
                                        )
                                    if alreadyAdded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white)
                                            .padding(4)
                                    }
                                }
                                Text(preset.name)
                                    .font(.system(size: 9))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(alreadyAdded ? .secondary : .primary)
                                    .frame(width: 86)
                                    .lineLimit(2)
                            }
                            .opacity(alreadyAdded ? 0.5 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Search results

    private var searchResultsSections: some View {
        Group {
            // Matching cards already in wallet
            if !filteredCards.isEmpty {
                Section("Your Cards") {
                    ForEach(filteredCards) { card in
                        NavigationLink(destination: CardDetailView(card: card, onSave: updateCard)) {
                            CardRow(card: card, category: context.category)
                        }
                    }
                }
            }

            // Presets not yet added
            if !presetMatches.isEmpty {
                Section("Add from Presets") {
                    ForEach(presetMatches, id: \.name) { preset in
                        Button { quickAddPreset = preset } label: {
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
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if filteredCards.isEmpty && presetMatches.isEmpty {
                Section {
                    Text("No results for \"\(searchText)\"")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Onboarding (no cards yet)

    private var onboardingSection: some View {
        Section {
            VStack(spacing: 32) {
                Text("How it works")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                VStack(spacing: 24) {
                    OnboardingStep(
                        number: "1",
                        icon:   "creditcard.fill",
                        color:  .blue,
                        title:  "Add your cards",
                        detail: "Enter your credit cards and their reward categories once."
                    )
                    OnboardingStep(
                        number: "2",
                        icon:   "lock.iphone",
                        color:  .indigo,
                        title:  "Tap the widget at checkout",
                        detail: "At the register, tap the Point Maximizer widget on your lock screen."
                    )
                    OnboardingStep(
                        number: "3",
                        icon:   "star.fill",
                        color:  .yellow,
                        title:  "Earn max points",
                        detail: "See exactly which card earns the most — then open Wallet in one tap."
                    )
                }

                Button(action: { showWalletImport = true }) {
                    Label("Select My Cards", systemImage: "rectangle.stack.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button(action: { showAddCard = true }) {
                    Text("Add a Card Manually")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 4)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - "How it works" compact row

    private var howItWorksRow: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "lock.iphone")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tap the lock screen widget at checkout")
                        .font(.subheadline.weight(.semibold))
                    Text("It checks your location and picks the best card.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Card list

    private var cardListSection: some View {
        Section("Your Cards") {
            ForEach(cards) { card in
                NavigationLink(destination: CardDetailView(card: card, onSave: updateCard)) {
                    CardRow(card: card, category: context.category)
                }
            }
            .onDelete(perform: deleteCards)
        }
    }

    // MARK: - Helpers

    private func topRewardSummary(_ preset: PresetCard) -> String {
        preset.rewards
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { "\(formatMult($0.value))× \($0.key.rawValue)" }
            .joined(separator: "  ·  ")
    }

    private func formatMult(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }

    // MARK: - Deep link handler

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "pointmaximizer", url.host == "open" else { return }
        guard !cards.isEmpty else { showAddCard = true; return }

        resolvedData = nil
        showingCheckSheet = true

        Task {
            guard let location = await locationManager.requestCurrentLocation() else { return }
            let context = await MerchantIntelligenceEngine.shared.analyze(
                location: location,
                at: Date()
            )
            await MainActor.run {
                let snapshot = SharedDataManager.shared.buildWidgetData(
                    merchantName: context.merchantName,
                    enrichedName: context.enrichedName,
                    contextTag:   context.contextTag,
                    confidence:   context.confidence,
                    category:     context.category
                )
                SharedDataManager.shared.saveWidgetData(snapshot)
                WidgetCenter.shared.reloadAllTimelines()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    resolvedData = snapshot
                }
            }
        }
    }

    // MARK: - CRUD helpers

    private func reloadCards() {
        cards = SharedDataManager.shared.loadCards()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteCards(at offsets: IndexSet) {
        let ids = offsets.map { cards[$0].id }
        cards.removeAll { ids.contains($0.id) }
        SharedDataManager.shared.saveCards(cards)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func updateCard(_ updated: CreditCard) {
        if let idx = cards.firstIndex(where: { $0.id == updated.id }) {
            cards[idx] = updated
        }
        SharedDataManager.shared.saveCards(cards)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Quick Add Sheet

private struct QuickAddSheet: View {
    let preset: PresetCard
    @Environment(\.dismiss) private var dismiss
    @State private var lastFour = ""
    @FocusState private var focused: Bool

    private var cardColor: Color { Color(hex: preset.colorHex) ?? .black }
    private var canSave: Bool { lastFour.count == 4 }

    var body: some View {
        VStack(spacing: 0) {
            // Card preview
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [cardColor, cardColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 100)
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    Text(preset.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("•••• •••• •••• \(lastFour.isEmpty ? "——" : lastFour)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Last 4 entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 4 digits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                TextField("e.g. 1234", text: $lastFour)
                    .keyboardType(.numberPad)
                    .font(.system(.title2, design: .monospaced).weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .focused($focused)
                    .onChange(of: lastFour) { _, v in
                        lastFour = String(v.filter(\.isNumber).prefix(4))
                    }
            }
            .padding(.top, 20)

            // Add button
            Button {
                saveCard()
            } label: {
                Text(canSave ? "Add Card" : "Enter Last 4 Digits")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? Color.black : Color(.systemGray4))
                    .foregroundStyle(canSave ? Color.white : Color(.systemGray))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .animation(.spring(response: 0.3), value: canSave)
        }
        .onAppear { focused = true }
    }

    private func saveCard() {
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
        var existing = SharedDataManager.shared.loadCards()
        existing.append(card)
        SharedDataManager.shared.saveCards(existing)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

// MARK: - Onboarding step row

private struct OnboardingStep: View {
    let number: String
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }
}
