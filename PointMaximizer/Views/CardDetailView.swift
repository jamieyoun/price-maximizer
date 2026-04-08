import SwiftUI

struct CardDetailView: View {
    @State var card: CreditCard
    var onSave: (CreditCard) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // MARK: Preview
            Section("Preview") {
                HStack {
                    Spacer()
                    CardChip(card: card)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // MARK: Card Info
            Section("Card Info") {
                TextField("Card Name", text: $card.name)
                TextField("Last 4 Digits", text: $card.lastFour)
                    .keyboardType(.numberPad)
                    .onChange(of: card.lastFour) { _, newVal in
                        card.lastFour = String(newVal.filter(\.isNumber).prefix(4))
                    }
                Picker("Network", selection: $card.network) {
                    ForEach(CardNetwork.allCases, id: \.self) { Text($0.rawValue) }
                }
                Picker("Point Currency", selection: $card.rewardCurrency) {
                    ForEach(RewardCurrency.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                ColorPicker("Card Color",
                            selection: Binding(
                                get: { Color(hex: card.colorHex) ?? .black },
                                set: { card.colorHex = $0.toHex() }
                            ),
                            supportsOpacity: false)
            }

            // MARK: Reward Multipliers
            Section {
                ForEach(StoreCategory.allCases, id: \.self) { cat in
                    HStack {
                        Label(cat.rawValue, systemImage: cat.sfSymbol)
                            .foregroundColor(cat.color)
                        Spacer()
                        Stepper(
                            value: Binding(
                                get: { card.rewards[cat.rawValue] ?? 1.0 },
                                set: { card.rewards[cat.rawValue] = $0 }
                            ),
                            in: 1...20,
                            step: 0.5
                        ) {
                            Text("\(formatMult(card.rewards[cat.rawValue] ?? 1.0))×")
                                .frame(minWidth: 36, alignment: .trailing)
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                }
            } header: {
                Text("Reward Multipliers")
            }

            // MARK: Quarterly Spending Caps
            Section {
                ForEach(StoreCategory.allCases, id: \.self) { cat in
                    let mult = card.rewards[cat.rawValue] ?? 1.0
                    // Only show cap field for categories that earn above base
                    if mult > 1 {
                        HStack {
                            Label(cat.rawValue, systemImage: cat.sfSymbol)
                                .foregroundColor(cat.color)
                            Spacer()
                            TextField("No cap",
                                      value: Binding(
                                        get: {
                                            let v = card.caps[cat.rawValue] ?? 0
                                            return v > 0 ? v : nil
                                        },
                                        set: { card.caps[cat.rawValue] = $0 ?? 0 }
                                      ),
                                      format: .currency(code: "USD").precision(.fractionLength(0)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: 100)

                            // Spend progress this quarter
                            let spent = SharedDataManager.shared.spentAmount(cardID: card.id, category: cat)
                            let cap = card.caps[cat.rawValue] ?? 0
                            if cap > 0 && spent > 0 {
                                Text("\(Int(spent / cap * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(spent >= cap ? .red : .secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Quarterly Spending Caps")
            } footer: {
                Text("When you hit the cap, this card drops to its base rate and a better card is recommended instead.")
                    .font(.caption)
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(card)
                    dismiss()
                }
            }
        }
    }

    private func formatMult(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}
