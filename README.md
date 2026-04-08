# Point Maximizer

**The smartest credit card at every checkout — right on your lock screen.**

Point Maximizer is a native iOS app that detects where you're shopping in real time and instantly tells you which credit card in your wallet earns the most points or cash back there. No more guessing at the register.

---

## Demo

<!-- ------------------------------------------------------------------ -->
<!-- TO ADD YOUR VIDEO:                                                   -->
<!--   1. Record a screen recording on your iPhone (Control Center →      -->
<!--      Screen Recording), or use Xcode → Window → Devices and          -->
<!--      Simulators to mirror + record.                                  -->
<!--   2. Upload the .mp4 to this repo under assets/demo.mp4, OR upload  -->
<!--      it to YouTube/Vimeo and paste the link below.                  -->
<!--   3. Replace the lines below with one of:                           -->
<!--      YouTube:  [![Demo](https://img.youtube.com/vi/YOUR_ID/0.jpg)](https://youtu.be/YOUR_ID) -->
<!--      Local:    https://github.com/jamieyoun/price-maximizer/assets/YOUR_ASSET_ID/demo.mp4   -->
<!-- ------------------------------------------------------------------ -->

> **Video coming soon** — see screenshots below for a full walkthrough.

---

## Screenshots

<table>
  <tr>
    <td align="center">
      <img src="assets/screenshots/01-onboarding.png" width="220" alt="Onboarding" /><br/>
      <sub><b>Onboarding</b></sub>
    </td>
    <td align="center">
      <img src="assets/screenshots/02-card-selector.png" width="220" alt="Card Selector" /><br/>
      <sub><b>Select Your Cards</b></sub>
    </td>
    <td align="center">
      <img src="assets/screenshots/03-card-list.png" width="220" alt="Card List" /><br/>
      <sub><b>Your Wallet</b></sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/screenshots/04-recommendation.png" width="220" alt="Recommendation Sheet" /><br/>
      <sub><b>Best Card at Checkout</b></sub>
    </td>
    <td align="center">
      <img src="assets/screenshots/05-lock-screen-widget.png" width="220" alt="Lock Screen Widget" /><br/>
      <sub><b>Lock Screen Widget</b></sub>
    </td>
    <td align="center">
      <img src="assets/screenshots/06-add-card-search.png" width="220" alt="Card Search" /><br/>
      <sub><b>Search & Add Cards</b></sub>
    </td>
  </tr>
</table>

<!--
HOW TO ADD SCREENSHOTS
======================
1. Run the app on your iPhone or in the iOS Simulator (iPhone 15 Pro recommended).
2. Take each screenshot listed below. On device: press Side + Volume Up.
   In Simulator: Cmd+S saves directly to your Desktop.
3. Create the folder:  mkdir -p /path/to/repo/assets/screenshots
4. Name and place each file exactly as referenced above, then run:
     git add assets/screenshots/
     git commit -m "Add app screenshots"
     git push

SHOT LIST (6 screenshots — ~10 minutes total)
---------------------------------------------
01-onboarding.png
   → Launch the app with no cards added. Capture the 3-step "How it works"
     onboarding screen with the "Select My Cards" black button at the bottom.

02-card-selector.png
   → Tap "Select My Cards". Capture the grouped issuer list (Chase, Amex, etc.)
     with one or two cards already checked (blue checkmark) and a last-4 field
     expanded showing the animated text field.

03-card-list.png
   → After adding 3–4 cards, capture the main "Your Cards" list view. Ideally
     have a location-aware category badge visible on one row (e.g. "Grocery").

04-recommendation.png
   → Trigger the tap-to-check flow (tap the lock screen widget or simulate via
     the deep link pointmaximizer://open). Capture the full recommendation sheet
     showing the card graphic, the large multiplier number, and the runner-up row.

05-lock-screen-widget.png
   → Show the iPhone lock screen with the Point Maximizer circular widget visible
     below the clock. A rectangular widget alongside it makes a great second option.
     Capture via Screenshots or use Simulator → File → Screenshot.

06-add-card-search.png
   → Open Add Card, type "sapphire" in the search field. Capture the live search
     results list showing Chase Sapphire Preferred and Chase Sapphire Reserve with
     their mini card chips and reward summaries.
-->

---

## How It Works

1. **Add your cards** — Choose from 41 preset cards (Chase, Amex, Citi, Capital One, and more) or enter custom multipliers manually. Reward rates are verified against each issuing bank.
2. **Tap the lock screen widget at checkout** — A single tap triggers a one-shot location check. No app opening required.
3. **Use the best card** — A sheet slides up showing your top card, its multiplier, and a runner-up. Tap "Open Wallet" to pay.

---

## Features

### Location-Aware Recommendations
A custom Merchant Intelligence Engine cross-references your GPS coordinates with Apple's Maps database to classify merchants into reward categories (Grocery, Dining, Gas, Travel, Shopping) with a confidence score. Context tags like "Airport Terminal" or "Morning Commute" further refine the pick.

### Lock Screen Widget
Built with WidgetKit, the widget lives in the accessory circular slot below your clock — always one tap away. Also available as rectangular, inline, small, and medium home screen sizes.

### 41 Verified Card Presets
Every reward rate and quarterly spending cap is sourced directly from the issuing bank. Cards span:

| Issuer | Cards |
|--------|-------|
| Chase | Sapphire Preferred, Sapphire Reserve, Freedom Flex, Freedom Unlimited, Amazon Prime Visa, Freedom Rise, Marriott Bonvoy Boundless, United Explorer, Ink Business Cash, World of Hyatt |
| Amex | Gold, Platinum, Blue Cash Preferred, Blue Cash Everyday, Green, Cash Magnet, Delta SkyMiles Gold, Delta SkyMiles Platinum, Hilton Honors, Hilton Honors Surpass, Marriott Bonvoy Brilliant |
| Citi | Double Cash, Custom Cash, Strata Premier, Rewards+ |
| Capital One | Savor, Venture, VentureOne, Quicksilver |
| Discover | It Cash Back, It Miles, It Chrome |
| Bank of America | Customized Cash, Premium Rewards, Unlimited Cash, Travel Rewards |
| Wells Fargo | Active Cash, Autograph, Autograph Journey |
| US Bank | Altitude Go, Cash+, Shopper Cash Rewards |
| Bilt | Bilt Mastercard |
| Apple | Apple Card |

### Spending Cap Tracking
Quarterly spend caps (e.g. Amex Blue Cash Preferred's $1,500 grocery cap) are tracked per card per category. When you hit a cap mid-quarter, Point Maximizer automatically promotes the next best card for that category.

### Card Search
Search all 41 presets by name when adding a card. Reward rates, multipliers, and spending caps auto-fill instantly.

### Runner-Up Comparison
The recommendation sheet always shows your second-best option — so you know exactly what you're leaving on the table.

### Siri Shortcut
Ask "Which card should I use with Point Maximizer?" and get a spoken recommendation hands-free.

### Multi-Currency Point Valuation
Cards are ranked by real-world value — not just raw multiplier. Chase UR points at 2¢ each beat a raw 3× cash back card at 1¢ each. Point valuations sourced from The Points Guy (April 2026).

| Currency | Value |
|----------|-------|
| Chase Ultimate Rewards | 2.0¢ / pt |
| Amex Membership Rewards | 2.0¢ / pt |
| Bilt Points | 1.67¢ / pt |
| Citi ThankYou Points | 1.7¢ / pt |
| World of Hyatt Points | 1.7¢ / pt |
| Capital One Miles | 1.7¢ / pt |
| Wells Fargo Rewards | 1.5¢ / pt |
| US Bank Rewards | 1.5¢ / pt |
| United MileagePlus | 1.35¢ / pt |
| Delta SkyMiles | 1.2¢ / pt |
| Marriott Bonvoy Points | 0.7¢ / pt |
| Hilton Honors Points | 0.5¢ / pt |
| Cash Back | 1.0¢ / pt |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Widget | WidgetKit (accessory + home screen families) |
| Location | CoreLocation — significant-change monitoring + one-shot `requestLocation()` |
| Merchant detection | MapKit reverse geocoding + category classification |
| Data sharing | App Groups (UserDefaults suite) |
| Siri | AppIntents framework |
| Deep linking | Custom URL scheme `pointmaximizer://open` |
| Persistence | JSON-encoded UserDefaults via shared App Group |

---

## Project Structure

```
PointMaximizer/
├── Shared/
│   ├── Models.swift              # CreditCard, WidgetData, RewardCurrency, StoreCategory
│   ├── CardPresets.swift         # 41 verified card presets with caps
│   └── SharedDataManager.swift  # App Group persistence, spend tracking, card ranking
├── Managers/
│   ├── LocationManager.swift     # CLLocationManager + one-shot async location
│   ├── MerchantIntelligenceEngine.swift  # Location → merchant category
│   ├── NotificationManager.swift # Proactive checkout nudges
│   └── WalletManager.swift       # Pass deep-linking
├── Views/
│   ├── ContentView.swift         # Main list + onboarding + deep link handler
│   ├── CardRecommendationSheet.swift  # Spinner → result sheet
│   ├── WalletImportView.swift    # Visual card selector (41 presets)
│   ├── AddCardView.swift         # Manual add + search + quick start
│   ├── CardDetailView.swift      # Edit card + cap tracking
│   └── CardRow.swift             # List row with live category badge
├── LiveActivity/
│   └── LiveActivityManager.swift
└── RecommendCardIntent.swift     # Siri AppIntent

PointMaximizerWidget/
├── PointMaximizerWidget.swift    # Timeline provider + widget bundle
└── WidgetViews.swift             # Lock screen + home screen layouts
```

---

## Requirements

- iOS 17.0+
- Xcode 15+
- An App Group identifier configured in both the app and widget targets (`group.com.yourname.pointmaximizer`)

---

## Setup

1. Clone the repo and open `PointMaximizer.xcodeproj` in Xcode.
2. Set your development team in **Signing & Capabilities** for both the app and widget targets.
3. Update the App Group identifier in both targets to match your team.
4. Build and run on a device (location services require a real device for full functionality).
5. Add your lock screen widget: **Lock Screen → Long Press → Customize → add Point Maximizer**.
