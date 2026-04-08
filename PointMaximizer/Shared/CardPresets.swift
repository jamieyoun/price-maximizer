import Foundation

// MARK: - PresetCard
// All reward rates and quarterly spending caps verified against NerdWallet,
// The Points Guy, and Bankrate — April 2026.
//
// caps: quarterly dollar limit on a bonus category (0 = no cap).
// Annual caps are divided by 4 to produce quarterly equivalents.
// Monthly caps (Citi Custom Cash) are multiplied by 3.

struct PresetCard {
    let name: String
    let network: CardNetwork
    let colorHex: String
    let rewards: [StoreCategory: Double]
    let rewardCurrency: RewardCurrency
    /// Quarterly spending cap per category in dollars. 0 = uncapped.
    let caps: [StoreCategory: Double]

    init(name: String, network: CardNetwork, colorHex: String,
         rewards: [StoreCategory: Double],
         rewardCurrency: RewardCurrency,
         caps: [StoreCategory: Double] = [:]) {
        self.name           = name
        self.network        = network
        self.colorHex       = colorHex
        self.rewards        = rewards
        self.rewardCurrency = rewardCurrency
        self.caps           = caps
    }
}

enum CardPresets {

    static let all: [PresetCard] = [

        // MARK: ── Chase ──────────────────────────────────────────────────────
        // All Chase cards earn Chase Ultimate Rewards (2¢/pt optimal redemption).

        // Sapphire Preferred: 5× Chase Travel portal, 3× dining/online grocery/streaming,
        // 2× all other travel, 1× everything else. No bonus-category caps.
        PresetCard(
            name: "Chase Sapphire Preferred", network: .visa, colorHex: "#1B3A6B",
            rewards: [.grocery: 3, .dining: 3, .travel: 2, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .chaseUR
        ),

        // Sapphire Reserve: 8× Chase Travel portal, 4× direct flights & hotels,
        // 3× dining, 1× everything else.
        // Source: NerdWallet / TPG April 2026 (updated from prior 3× travel).
        PresetCard(
            name: "Chase Sapphire Reserve", network: .visa, colorHex: "#2C2C2C",
            rewards: [.grocery: 1, .dining: 3, .travel: 4, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .chaseUR
        ),

        // Freedom Flex: 5× rotating categories (up to $1,500/quarter, activation required),
        // 5× Chase Travel, 3× dining & drugstores, 1% everything else.
        // Rotating categories historically include grocery, gas, retail, Amazon, PayPal.
        PresetCard(
            name: "Chase Freedom Flex", network: .visa, colorHex: "#1A2744",
            rewards: [.grocery: 5, .dining: 3, .travel: 5, .gas: 5, .retail: 5, .other: 1],
            rewardCurrency: .chaseUR,
            caps: [.grocery: 1500, .gas: 1500, .retail: 1500]   // rotating $1,500/quarter
        ),

        // Freedom Unlimited: 5× Chase Travel, 3× dining & drugstores,
        // 1.5× ALL other purchases (including grocery, gas, retail).
        // Source: NerdWallet / TPG — corrected from prior 1× on grocery/gas/retail.
        PresetCard(
            name: "Chase Freedom Unlimited", network: .visa, colorHex: "#2C2C2C",
            rewards: [.grocery: 1.5, .dining: 3, .travel: 5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .chaseUR
        ),

        // Prime Visa: 5% on Amazon.com, Amazon Fresh, Whole Foods & Chase Travel;
        // 2% on restaurants, gas stations & local transit; 1% everything else.
        // General retail (non-Amazon) earns 1%. Corrected from prior 5× retail.
        PresetCard(
            name: "Chase Amazon Prime Visa", network: .visa, colorHex: "#232F3E",
            rewards: [.grocery: 5, .dining: 2, .travel: 5, .gas: 2, .retail: 1, .other: 1],
            rewardCurrency: .chaseUR
        ),

        // MARK: ── American Express ───────────────────────────────────────────
        // Amex MR cards earn Membership Rewards (2¢/pt optimal via transfer partners).
        // Blue Cash cards earn straight cash back (1¢/pt).

        // Gold: 4× U.S. supermarkets (up to $25,000/yr → ~$6,250/quarter, effectively uncapped),
        // 4× worldwide dining (up to $50,000/yr, effectively uncapped),
        // 3× flights booked directly or through Amex Travel, 1× everything else.
        PresetCard(
            name: "Amex Gold", network: .amex, colorHex: "#C9A84C",
            rewards: [.grocery: 4, .dining: 4, .travel: 3, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .amexMR
            // Annual caps ($25K grocery, $50K dining) too high to set as quarterly limits
        ),

        // Platinum: 5× airfare (directly or Amex Travel, up to $500K/yr — effectively uncapped),
        // 5× prepaid hotels through Amex Travel, 1× everything else.
        PresetCard(
            name: "Amex Platinum", network: .amex, colorHex: "#A8A9AD",
            rewards: [.grocery: 1, .dining: 1, .travel: 5, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .amexMR
        ),

        // Blue Cash Preferred: 6% U.S. supermarkets (up to $6,000/yr → $1,500/quarter),
        // 6% select U.S. streaming, 3% U.S. gas stations & transit (unlimited),
        // 1% everything else.
        PresetCard(
            name: "Amex Blue Cash Preferred", network: .amex, colorHex: "#007B8A",
            rewards: [.grocery: 6, .dining: 1, .travel: 1, .gas: 3, .retail: 1, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.grocery: 1500]   // $6,000/year ÷ 4 = $1,500/quarter
        ),

        // Blue Cash Everyday: 3% U.S. supermarkets, 3% U.S. gas stations,
        // 3% U.S. online retail purchases — all capped at $6,000/year each ($1,500/quarter),
        // 1% everything else.
        PresetCard(
            name: "Amex Blue Cash Everyday", network: .amex, colorHex: "#00A1DE",
            rewards: [.grocery: 3, .dining: 1, .travel: 1, .gas: 3, .retail: 3, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.grocery: 1500, .gas: 1500, .retail: 1500]   // $6,000/year each ÷ 4
        ),

        // Green: 3× worldwide travel (flights, hotels, transit, rideshare, parking),
        // 3× worldwide dining, 1× everything else. No spending caps.
        PresetCard(
            name: "Amex Green", network: .amex, colorHex: "#5B8C3E",
            rewards: [.grocery: 1, .dining: 3, .travel: 3, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .amexMR
        ),

        // Cash Magnet: unlimited 1.5% cash back on all purchases. No caps, no categories.
        PresetCard(
            name: "Amex Cash Magnet", network: .amex, colorHex: "#1A1A1A",
            rewards: [.grocery: 1.5, .dining: 1.5, .travel: 1.5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // Delta SkyMiles Gold: 2× Miles on Delta purchases, dining worldwide,
        // and U.S. supermarkets; 1× everything else. No spending caps.
        PresetCard(
            name: "Amex Delta SkyMiles Gold", network: .amex, colorHex: "#003087",
            rewards: [.grocery: 2, .dining: 2, .travel: 2, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .deltaMiles
        ),

        // Delta SkyMiles Platinum: 3× Miles on Delta purchases and hotels booked
        // directly; 2× at restaurants worldwide and U.S. supermarkets; 1× everything else.
        PresetCard(
            name: "Amex Delta SkyMiles Platinum", network: .amex, colorHex: "#4A4A4A",
            rewards: [.grocery: 2, .dining: 2, .travel: 3, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .deltaMiles
        ),

        // Hilton Honors (no annual fee): 7× Hilton hotels, 5× at U.S. restaurants,
        // U.S. supermarkets, and U.S. gas stations, 3× on all other purchases.
        PresetCard(
            name: "Amex Hilton Honors", network: .amex, colorHex: "#002B6B",
            rewards: [.grocery: 5, .dining: 5, .travel: 7, .gas: 5, .retail: 3, .other: 3],
            rewardCurrency: .hiltonPoints
        ),

        // Hilton Honors Surpass: 12× Hilton hotels, 6× at U.S. restaurants,
        // U.S. supermarkets, and U.S. gas stations; 3× all other purchases.
        PresetCard(
            name: "Amex Hilton Honors Surpass", network: .amex, colorHex: "#00395D",
            rewards: [.grocery: 6, .dining: 6, .travel: 12, .gas: 6, .retail: 3, .other: 3],
            rewardCurrency: .hiltonPoints
        ),

        // Marriott Bonvoy Brilliant: 6× Marriott Bonvoy hotels, 3× at worldwide
        // restaurants and on flights booked directly with airlines, 2× everything else.
        PresetCard(
            name: "Amex Marriott Bonvoy Brilliant", network: .amex, colorHex: "#8B6914",
            rewards: [.grocery: 2, .dining: 3, .travel: 6, .gas: 2, .retail: 2, .other: 2],
            rewardCurrency: .marriottBonvoy
        ),

        // MARK: ── Citi ───────────────────────────────────────────────────────

        // Double Cash: 2% on all purchases (1% when you buy + 1% when you pay).
        // Earns ThankYou points (redeemable as cash back at 1¢/pt or transferred to partners).
        PresetCard(
            name: "Citi Double Cash", network: .mastercard, colorHex: "#003087",
            rewards: [.grocery: 2, .dining: 2, .travel: 2, .gas: 2, .retail: 2, .other: 2],
            rewardCurrency: .cashBack
        ),

        // Custom Cash: 5% in your single highest-spend eligible category per billing cycle,
        // up to $500/month (= $1,500/quarter). 1% after cap or on all other categories.
        // Eligible 5% categories include grocery, dining, gas, travel, transit, streaming,
        // drugstores, home improvement, fitness, entertainment.
        PresetCard(
            name: "Citi Custom Cash", network: .mastercard, colorHex: "#0A3871",
            rewards: [.grocery: 5, .dining: 5, .travel: 5, .gas: 5, .retail: 1, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.grocery: 1500, .dining: 1500, .travel: 1500, .gas: 1500]   // $500/month × 3
        ),

        // Strata Premier: 3× restaurants, 3× supermarkets, 3× eligible travel (air, hotel,
        // car rental, cruise, gas station), 3× gas stations, 1× everything else.
        // 10× on hotels/cars/attractions through CitiTravel.com (portal booking).
        // No bonus-category spending caps.
        PresetCard(
            name: "Citi Strata Premier", network: .mastercard, colorHex: "#012169",
            rewards: [.grocery: 3, .dining: 3, .travel: 3, .gas: 3, .retail: 1, .other: 1],
            rewardCurrency: .citiTY
        ),

        // MARK: ── Capital One ─────────────────────────────────────────────────
        // Note: The annual-fee Capital One Savor was discontinued July 2024.
        // The former SavorOne was renamed to "Savor" in October 2024.

        // Savor (no annual fee): 3% dining, entertainment, grocery (excl. Walmart/Target),
        // popular streaming; 8% Capital One Entertainment; 5% hotels & rental cars through
        // Capital One Travel; 1% everything else. No spending caps.
        PresetCard(
            name: "Capital One Savor", network: .mastercard, colorHex: "#D4201F",
            rewards: [.grocery: 3, .dining: 3, .travel: 5, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .cashBack
        ),

        // Venture: 5× hotels, vacation rentals & rental cars through Capital One Travel;
        // 2× all other purchases. No spending caps.
        PresetCard(
            name: "Capital One Venture", network: .visa, colorHex: "#1A3A5C",
            rewards: [.grocery: 2, .dining: 2, .travel: 5, .gas: 2, .retail: 2, .other: 2],
            rewardCurrency: .capitalOneMiles
        ),

        // VentureOne: 5× hotels, vacation rentals & rental cars through Capital One Travel;
        // 1.25× all other purchases. No spending caps.
        PresetCard(
            name: "Capital One VentureOne", network: .visa, colorHex: "#2E6DA4",
            rewards: [.grocery: 1.25, .dining: 1.25, .travel: 5, .gas: 1.25, .retail: 1.25, .other: 1.25],
            rewardCurrency: .capitalOneMiles
        ),

        // Quicksilver: unlimited 1.5% cash back on all purchases.
        // 5% on hotels & rental cars through Capital One Travel.
        PresetCard(
            name: "Capital One Quicksilver", network: .visa, colorHex: "#9B1B1B",
            rewards: [.grocery: 1.5, .dining: 1.5, .travel: 5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // MARK: ── Discover ────────────────────────────────────────────────────

        // Discover it Cash Back: 5% on rotating quarterly categories (activation required),
        // up to $1,500/quarter combined. 1% on everything else.
        // 2026 Q1: grocery stores, wholesale clubs, streaming.
        // 2026 Q2: restaurants, home improvement stores.
        // Historical categories include gas, Amazon, PayPal, digital wallets, restaurants.
        PresetCard(
            name: "Discover It Cash Back", network: .discover, colorHex: "#F76B00",
            rewards: [.grocery: 5, .dining: 5, .travel: 1, .gas: 5, .retail: 5, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.grocery: 1500, .dining: 1500, .gas: 1500, .retail: 1500]  // $1,500/quarter combined
        ),

        // Discover It Miles: 1.5× miles on all purchases, unlimited.
        // Miles redeem at 1¢ each toward travel purchases (effectively 1.5% cash back on travel).
        PresetCard(
            name: "Discover It Miles", network: .discover, colorHex: "#CC5A00",
            rewards: [.grocery: 1.5, .dining: 1.5, .travel: 1.5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // Discover It Chrome: 2% at gas stations and restaurants on up to $1,000 in
        // combined purchases each quarter; 1% on everything else.
        PresetCard(
            name: "Discover It Chrome", network: .discover, colorHex: "#2C2C2C",
            rewards: [.grocery: 1, .dining: 2, .travel: 1, .gas: 2, .retail: 1, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.dining: 1000, .gas: 1000]   // $1,000/quarter combined on gas + dining
        ),

        // MARK: ── Chase (additional) ─────────────────────────────────────────

        // Freedom Rise: 1.5% cash back on all purchases (no bonus categories, no cap).
        // Chase's entry-level card — good everyday flat rate.
        PresetCard(
            name: "Chase Freedom Rise", network: .visa, colorHex: "#0A1F5C",
            rewards: [.grocery: 1.5, .dining: 1.5, .travel: 1.5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // Marriott Bonvoy Boundless: 6× Marriott hotels, 3× gas/grocery/dining,
        // 2× everything else. No bonus-category spending caps.
        PresetCard(
            name: "Chase Marriott Bonvoy Boundless", network: .visa, colorHex: "#8B1A1A",
            rewards: [.grocery: 3, .dining: 3, .travel: 6, .gas: 3, .retail: 2, .other: 2],
            rewardCurrency: .marriottBonvoy
        ),

        // United Explorer: 2× United purchases, hotels & dining; 1× everything else.
        PresetCard(
            name: "Chase United Explorer", network: .visa, colorHex: "#005DAA",
            rewards: [.grocery: 1, .dining: 2, .travel: 2, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .unitedMiles
        ),

        // Ink Business Cash: 5× office supply stores & internet/cable/phone services
        // (up to $25,000/year → $6,250/quarter); 2× gas stations & restaurants
        // (up to $25,000/year → $6,250/quarter); 1× everything else.
        PresetCard(
            name: "Chase Ink Business Cash", network: .visa, colorHex: "#0F1F5C",
            rewards: [.grocery: 1, .dining: 2, .travel: 1, .gas: 2, .retail: 5, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.retail: 6250, .dining: 6250, .gas: 6250]
        ),

        // World of Hyatt: 9× at Hyatt hotels (4× base + 5× cardholder bonus),
        // 2× dining, transit, gym & grocery stores, 1× everything else.
        // Source: chase.com / World of Hyatt — April 2026.
        PresetCard(
            name: "Chase World of Hyatt", network: .visa, colorHex: "#1D3461",
            rewards: [.grocery: 2, .dining: 2, .travel: 9, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .hyattPoints
        ),

        // MARK: ── Bank of America ─────────────────────────────────────────────

        // Customized Cash Rewards: 3% in one chosen category (gas, online shopping, dining,
        // travel, drugstores, or home improvement); 2% grocery stores & wholesale clubs;
        // 1% everything else. Combined quarterly cap: $2,500 on 3% + 2% categories.
        PresetCard(
            name: "BofA Customized Cash", network: .visa, colorHex: "#CC0000",
            rewards: [.grocery: 2, .dining: 3, .travel: 1, .gas: 3, .retail: 3, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.grocery: 2500, .dining: 2500, .gas: 2500, .retail: 2500]  // $2,500/quarter combined
        ),

        // Premium Rewards: unlimited 2× on travel & dining; 1.5× on all other purchases.
        // No spending caps.
        PresetCard(
            name: "BofA Premium Rewards", network: .visa, colorHex: "#8B0000",
            rewards: [.grocery: 1.5, .dining: 2, .travel: 2, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // Unlimited Cash Rewards: flat unlimited 1.5% cash back on all purchases.
        // Preferred Rewards members earn up to 2.625% with Platinum Honors tier.
        PresetCard(
            name: "BofA Unlimited Cash Rewards", network: .visa, colorHex: "#B8001E",
            rewards: [.grocery: 1.5, .dining: 1.5, .travel: 1.5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // Travel Rewards: unlimited 1.5× points on all purchases.
        // Points redeemable for travel at 1¢ each (effectively 1.5% on travel). No annual fee.
        PresetCard(
            name: "BofA Travel Rewards", network: .visa, colorHex: "#6B0000",
            rewards: [.grocery: 1.5, .dining: 1.5, .travel: 1.5, .gas: 1.5, .retail: 1.5, .other: 1.5],
            rewardCurrency: .cashBack
        ),

        // MARK: ── Wells Fargo ─────────────────────────────────────────────────

        // Active Cash: unlimited 2% cash rewards on all purchases. No caps. No categories.
        PresetCard(
            name: "Wells Fargo Active Cash", network: .visa, colorHex: "#C8102E",
            rewards: [.grocery: 2, .dining: 2, .travel: 2, .gas: 2, .retail: 2, .other: 2],
            rewardCurrency: .cashBack
        ),

        // Autograph: unlimited 3× restaurants, travel, gas stations, transit,
        // popular streaming, and phone plans; 1× everything else. No spending caps.
        PresetCard(
            name: "Wells Fargo Autograph", network: .visa, colorHex: "#D5001F",
            rewards: [.grocery: 1, .dining: 3, .travel: 3, .gas: 3, .retail: 1, .other: 1],
            rewardCurrency: .wellsFargoRW
        ),

        // Autograph Journey: 5× hotels, 4× airlines, 3× other travel & dining,
        // 1× everything else. No spending caps.
        // Source: wellsfargo.com — launched March 2024.
        PresetCard(
            name: "Wells Fargo Autograph Journey", network: .visa, colorHex: "#B8001E",
            rewards: [.grocery: 1, .dining: 3, .travel: 5, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .wellsFargoRW
        ),

        // MARK: ── Citi (additional) ──────────────────────────────────────────

        // Rewards+: 2× ThankYou Points at supermarkets and gas stations (first $6,000/year
        // → $1,500/quarter); 1× everything else. Rounds up to the nearest 10 points.
        PresetCard(
            name: "Citi Rewards+", network: .mastercard, colorHex: "#0A4F9E",
            rewards: [.grocery: 2, .dining: 1, .travel: 1, .gas: 2, .retail: 1, .other: 1],
            rewardCurrency: .citiTY,
            caps: [.grocery: 1500, .gas: 1500]   // $6,000/year ÷ 4
        ),

        // MARK: ── US Bank ─────────────────────────────────────────────────────

        // Altitude Go: 4× dining (including takeout & delivery, up to $2,000/quarter),
        // 2× grocery stores, gas stations, EV charging & streaming;
        // 1× everything else.
        PresetCard(
            name: "US Bank Altitude Go", network: .visa, colorHex: "#0054A6",
            rewards: [.grocery: 2, .dining: 4, .travel: 1, .gas: 2, .retail: 1, .other: 1],
            rewardCurrency: .usBankPoints,
            caps: [.dining: 2000]   // $2,000/quarter on 4× dining
        ),

        // Cash+: 5% on 2 chosen categories (fast food, electronics, movies, home utilities,
        // streaming, sporting goods, clothing, department stores, cell phones, gym, pet stores,
        // furniture — up to $2,000/quarter combined); 2% on 1 everyday category (grocery
        // stores, gas stations, or restaurants); 1% everything else.
        // Corrected: grocery/gas are 2%, not 5%. Retail/dining can be 5% via chosen categories.
        PresetCard(
            name: "US Bank Cash+", network: .visa, colorHex: "#002244",
            rewards: [.grocery: 2, .dining: 5, .travel: 1, .gas: 2, .retail: 5, .other: 1],
            rewardCurrency: .cashBack,
            caps: [.dining: 2000, .retail: 2000]   // $2,000/quarter combined on 5% categories
        ),

        // Shopper Cash Rewards: 6% at two chosen wholesale clubs/retailers (up to $1,500/quarter),
        // 3% at one everyday category of your choice (gas, grocery, or restaurants, up to $1,500/quarter),
        // 1.5% on all other eligible purchases.
        // Source: usbank.com — April 2026.
        PresetCard(
            name: "US Bank Shopper Cash Rewards", network: .visa, colorHex: "#003875",
            rewards: [.grocery: 3, .dining: 3, .travel: 1.5, .gas: 3, .retail: 6, .other: 1.5],
            rewardCurrency: .cashBack,
            caps: [.retail: 1500, .grocery: 1500, .gas: 1500, .dining: 1500]
        ),

        // MARK: ── Bilt ────────────────────────────────────────────────────────

        // Bilt Mastercard: 3× dining, 2× travel, 1× on rent (up to 100,000 pts/year)
        // and all other purchases. No transaction fee on rent payments.
        // Earns Bilt Points — transferable to Hyatt, United, AA, Delta, and more.
        // Source: biltrewards.com — April 2026.
        PresetCard(
            name: "Bilt Mastercard", network: .mastercard, colorHex: "#1A1A2E",
            rewards: [.grocery: 1, .dining: 3, .travel: 2, .gas: 1, .retail: 1, .other: 1],
            rewardCurrency: .biltPoints
        ),

        // MARK: ── Apple ───────────────────────────────────────────────────────

        // Apple Card: 3% Daily Cash at Apple and select partners (Nike, Uber, Walgreens,
        // Panera, Ace Hardware, ExxonMobil, T-Mobile, and more); 2% with Apple Pay;
        // 1% with physical titanium card.
        // Mapped: retail 3× (Apple/partner purchases), other 2× (Apple Pay everywhere).
        // Source: apple.com/apple-card — April 2026.
        PresetCard(
            name: "Apple Card", network: .mastercard, colorHex: "#8E8E93",
            rewards: [.grocery: 2, .dining: 2, .travel: 2, .gas: 2, .retail: 3, .other: 2],
            rewardCurrency: .cashBack
        ),
    ]

    // MARK: - Fuzzy matching (used by card selector import)

    static func match(walletName: String, network: CardNetwork) -> PresetCard? {
        let normalized = walletName.lowercased()
        var bestMatch: (preset: PresetCard, score: Int)? = nil

        for preset in all {
            guard preset.network == network else { continue }
            let keywords = preset.name.lowercased()
                .components(separatedBy: " ")
                .filter { $0.count >= 4 }
            let hits = keywords.filter { normalized.contains($0) }.count
            guard hits > 0 else { continue }
            if bestMatch == nil || hits > bestMatch!.score {
                bestMatch = (preset, hits)
            }
        }
        return bestMatch?.preset
    }
}
