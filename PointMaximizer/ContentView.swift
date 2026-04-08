import CoreLocation
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cards: [CreditCard] = []
    @State private var showAddCard = false
    @State private var showWalletImport = false

    // Tap-to-check sheet state
    @State private var showingCheckSheet = false
    @State private var resolvedData: WidgetData? = nil

    private var context: MerchantContext { locationManager.currentContext }

    var body: some View {
        NavigationStack {
            List {
                if cards.isEmpty {
                    onboardingSection
                } else {
                    howItWorksRow
                    cardListSection
                }
            }
            .navigationTitle("Point Maximizer")
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
            // Checkout recommendation sheet — spinner → card result
            .sheet(isPresented: $showingCheckSheet, onDismiss: { resolvedData = nil }) {
                CardRecommendationSheet(resolvedData: $resolvedData)
                    .presentationDetents([.height(620)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(28)
                    .animation(.spring(response: 0.4), value: resolvedData != nil)
            }
            // Widget or notification deep link: pointmaximizer://open
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onAppear {
                reloadCards()
                locationManager.requestPermission()
                LiveActivityManager.shared.end()
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

                // Primary CTA — select from preset card list
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

    // MARK: - "How it works" compact row (shown once cards exist)

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

    // MARK: - Deep link handler
    // pointmaximizer://open  →  one-shot location check → recommendation sheet

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "pointmaximizer", url.host == "open" else { return }
        guard !cards.isEmpty else { showAddCard = true; return }

        resolvedData = nil
        showingCheckSheet = true

        Task {
            // 1. One-shot location fix (CLLocationManager.requestLocation)
            guard let location = await locationManager.requestCurrentLocation() else { return }

            // 2. Merchant intelligence engine
            let context = await MerchantIntelligenceEngine.shared.analyze(
                location: location,
                at: Date()
            )

            // 3. Build the recommendation
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

                // Animate the sheet content in
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
