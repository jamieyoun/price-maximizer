import CoreLocation
import MapKit

// MerchantContext is defined in Shared/Models.swift (compiled into both targets).

/// Identifies what kind of anchor environment surrounds a merchant.
private enum AnchorType: String {
    case airport  = "Airport Terminal"
    case hotel    = "Hotel"
    case mall     = "Shopping Mall"
    case transit  = "Transit Hub"
    case highway  = "Highway / Rest Stop"
    case stadium  = "Stadium / Arena"
    case hospital = "Hospital / Medical"
    case none     = ""
}

// MARK: - Engine

/// Combines close-range POI data, medium-range anchor detection,
/// time-of-day signals, and keyword fingerprinting to produce a
/// high-confidence MerchantContext for any physical location.
actor MerchantIntelligenceEngine {

    static let shared = MerchantIntelligenceEngine()

    // MARK: - Public API

    func analyze(location: CLLocation, at date: Date = .init()) async -> MerchantContext {
        // Run both radii in parallel — 80 m for "what am I at", 700 m for "what am I near"
        async let closeTask  = fetchPOIs(near: location, radius: 80)
        async let anchorTask = fetchPOIs(near: location, radius: 700)
        let (closePOIs, anchorPOIs) = await (closeTask, anchorTask)

        return buildContext(
            location: location,
            date: date,
            closePOIs: closePOIs,
            anchorPOIs: anchorPOIs
        )
    }

    // MARK: - Core logic

    private func buildContext(
        location: CLLocation,
        date: Date,
        closePOIs: [MKMapItem],
        anchorPOIs: [MKMapItem]
    ) -> MerchantContext {

        var signals: [String] = []

        // 1. Identify the primary merchant (closest / most specific POI)
        let primary = closePOIs.first
        let merchantName = primary?.name ?? "Unknown Merchant"
        signals.append("Primary POI: \(merchantName)")

        // 2. Detect anchor environment from the wider radius
        let anchor = detectAnchor(from: anchorPOIs, signals: &signals)

        // 3. Infer base category from the primary POI
        let (baseCategory, baseConfidence) = inferBaseCategory(
            from: primary,
            allClose: closePOIs,
            signals: &signals
        )

        // 4. Apply anchor overrides
        let (finalCategory, anchorConfidenceDelta) = applyAnchorOverride(
            base: baseCategory,
            merchantName: merchantName,
            anchor: anchor,
            signals: &signals
        )

        // 5. Apply time-of-day context
        let timeTag = timeOfDayTag(date: date, category: finalCategory, signals: &signals)

        // 6. Build enriched display name
        let enrichedName = buildEnrichedName(
            merchantName: merchantName,
            anchor: anchor,
            timeTag: timeTag
        )

        let contextTag = anchor != .none ? anchor.rawValue : timeTag

        let confidence = min(1.0, baseConfidence + anchorConfidenceDelta)

        return MerchantContext(
            category:     finalCategory,
            confidence:   confidence,
            merchantName: merchantName,
            enrichedName: enrichedName,
            contextTag:   contextTag,
            signals:      signals
        )
    }

    // MARK: - Anchor detection

    private func detectAnchor(from items: [MKMapItem], signals: inout [String]) -> AnchorType {
        // Priority order: airport beats mall beats hotel, etc.
        for item in items {
            if let poi = item.pointOfInterestCategory {
                switch poi {
                case .airport:
                    signals.append("Anchor: airport within 700 m")
                    return .airport
                case .publicTransport:
                    signals.append("Anchor: transit hub within 700 m")
                    return .transit
                case .hotel:
                    signals.append("Anchor: hotel within 700 m")
                    return .hotel
                default: break
                }
            }

            let name = (item.name ?? "").lowercased()
            if airportKeywords.contains(where: { name.contains($0) }) {
                signals.append("Anchor: airport keyword in '\(item.name ?? "")'")
                return .airport
            }
            if mallKeywords.contains(where: { name.contains($0) }) {
                signals.append("Anchor: mall keyword in '\(item.name ?? "")'")
                return .mall
            }
            if hotelKeywords.contains(where: { name.contains($0) }) {
                signals.append("Anchor: hotel keyword in '\(item.name ?? "")'")
                return .hotel
            }
            if highwayKeywords.contains(where: { name.contains($0) }) {
                signals.append("Anchor: highway/rest-stop keyword")
                return .highway
            }
            if stadiumKeywords.contains(where: { name.contains($0) }) {
                signals.append("Anchor: stadium keyword")
                return .stadium
            }
        }
        return .none
    }

    // MARK: - Base category inference

    private func inferBaseCategory(
        from item: MKMapItem?,
        allClose: [MKMapItem],
        signals: inout [String]
    ) -> (StoreCategory, Double) {

        // Try typed POI category first (most reliable)
        if let poi = item?.pointOfInterestCategory {
            if let cat = poiCategoryMap[poi] {
                signals.append("POI type match: \(poi.rawValue) → \(cat.rawValue)")
                return (cat, 0.85)
            }
        }

        // Keyword fingerprint on primary name
        let name = (item?.name ?? "").lowercased()
        for (cat, keywords) in categoryKeywords {
            for kw in keywords where name.contains(kw) {
                signals.append("Keyword match: '\(kw)' → \(cat.rawValue)")
                return (cat, 0.70)
            }
        }

        // Try secondary POIs in close radius
        for secondary in allClose.dropFirst() {
            if let poi = secondary.pointOfInterestCategory, let cat = poiCategoryMap[poi] {
                signals.append("Secondary POI type: \(poi.rawValue) → \(cat.rawValue) (confidence reduced)")
                return (cat, 0.45)
            }
        }

        signals.append("No confident match — defaulting to Other")
        return (.other, 0.20)
    }

    // MARK: - Anchor overrides

    /// Certain anchor contexts should override what the merchant "appears" to be.
    /// E.g. a Starbucks inside an airport earns travel rewards, not dining rewards,
    /// on cards like Chase Sapphire Reserve that give 3x on travel broadly.
    private func applyAnchorOverride(
        base: StoreCategory,
        merchantName: String,
        anchor: AnchorType,
        signals: inout [String]
    ) -> (StoreCategory, Double) {

        let lower = merchantName.lowercased()

        switch anchor {
        case .airport:
            // Everything inside an airport terminal is a travel purchase on most premium travel cards.
            // Exception: pure retail chains that don't fit the travel bucket.
            let isHardRetail = retailOnlyBrands.contains(where: { lower.contains($0) })
            if !isHardRetail {
                signals.append("Airport override: \(base.rawValue) → Travel (+0.10 confidence)")
                return (.travel, 0.10)
            }

        case .hotel:
            // Dining and bars inside hotels often code as Travel/Lodging.
            if base == .dining || base == .other {
                signals.append("Hotel override: \(base.rawValue) → Travel (+0.05 confidence)")
                return (.travel, 0.05)
            }

        case .highway:
            // Convenience stores and fast food at rest stops often code as Gas & Auto.
            if base == .dining || base == .retail {
                signals.append("Highway override: \(base.rawValue) → Gas & Auto (+0.05 confidence)")
                return (.gas, 0.05)
            }

        case .mall:
            // Most things in malls are Retail regardless of MCC.
            if base == .other {
                signals.append("Mall override: Other → Shopping (+0.10 confidence)")
                return (.retail, 0.10)
            }

        case .transit, .stadium, .hospital, .none:
            break
        }

        return (base, 0.0)
    }

    // MARK: - Time of day

    private func timeOfDayTag(date: Date, category: StoreCategory, signals: inout [String]) -> String {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5..<10:
            signals.append("Time signal: morning commute window")
            return "Morning Commute"
        case 10..<14:
            if category == .dining {
                signals.append("Time signal: lunch hour")
                return "Lunch"
            }
        case 14..<17:
            return ""
        case 17..<21:
            if category == .dining {
                signals.append("Time signal: dinner hour")
                return "Dinner"
            }
        case 21..<24, 0..<5:
            signals.append("Time signal: late night")
            return "Late Night"
        default: break
        }
        return ""
    }

    // MARK: - Enriched name builder

    private func buildEnrichedName(merchantName: String, anchor: AnchorType, timeTag: String) -> String {
        if anchor != .none {
            return "\(merchantName) · \(anchor.rawValue)"
        }
        if !timeTag.isEmpty {
            return "\(merchantName) · \(timeTag)"
        }
        return merchantName
    }

    // MARK: - MapKit fetch helper

    private func fetchPOIs(near location: CLLocation, radius: CLLocationDistance) async -> [MKMapItem] {
        await withCheckedContinuation { continuation in
            let req = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: radius)
            MKLocalSearch(request: req).start { response, _ in
                continuation.resume(returning: response?.mapItems ?? [])
            }
        }
    }

    // MARK: - Static lookup tables

    private let poiCategoryMap: [MKPointOfInterestCategory: StoreCategory] = [
        .foodMarket:     .grocery,
        .bakery:         .grocery,
        .restaurant:     .dining,
        .cafe:           .dining,
        .brewery:        .dining,
        .winery:         .dining,
        .nightlife:      .dining,
        .gasStation:     .gas,
        .evCharger:      .gas,
        .carRental:      .gas,
        .parking:        .gas,
        .airport:        .travel,
        .hotel:          .travel,
        .publicTransport:.travel,
        .marina:         .travel,
        .store:          .retail,
    ]

    private let categoryKeywords: [StoreCategory: [String]] = [
        .grocery: ["grocery","supermarket","safeway","kroger","whole foods","trader joe",
                   "publix","wegmans","aldi","food lion","market","costco","sam's club",
                   "bj's","sprouts","fresh market","stop & shop","giant","h-e-b","meijer"],
        .dining:  ["restaurant","cafe","coffee","mcdonald","starbucks","chipotle","subway",
                   "pizza","sushi","burger","taco","diner","grill","kitchen","bistro",
                   "bar ","wings","dunkin","panera","chick-fil","wendy","kfc","domino",
                   "noodle","ramen","pho","bbq"],
        .gas:     ["shell","chevron","bp ","exxon","mobil","fuel","speedway","circle k",
                   "wawa","kwik trip","sunoco","marathon","pilot","love's","gas station",
                   "76 ","arco","casey's"],
        .travel:  ["airport","hotel","motel","marriott","hilton","hyatt","delta ","united ",
                   "airways","airline","inn ","suites","resort","terminal","airbnb","sheraton",
                   "westin","intercontinental","holiday inn","hampton inn"],
        .retail:  ["target","walmart","amazon","best buy","home depot","lowe's","macy",
                   "nordstrom","gap ","h&m","zara","mall","outlet","tj maxx","marshalls",
                   "ross ","dollar tree","dollar general","five below","ulta","sephora",
                   "cvs","walgreens","rite aid","ikea","bed bath"],
    ]

    private let airportKeywords  = ["airport","terminal","concourse","airside","sfo","jfk",
                                    "lax","ord","atl","dfw","bos","sea","mia","den","lga"]
    private let mallKeywords     = ["mall","shopping center","galleria","plaza","outlets","pavilion"]
    private let hotelKeywords    = ["hotel","motel","inn ","suites","resort","marriott","hilton",
                                    "hyatt","sheraton","westin","holiday inn","hampton"]
    private let highwayKeywords  = ["rest area","rest stop","travel plaza","turnpike","truck stop",
                                    "love's","pilot ","petro ","flying j"]
    private let stadiumKeywords  = ["stadium","arena","field","center ","coliseum","amphitheater"]

    /// Retail brands that should NOT be reclassified as Travel even inside an airport.
    private let retailOnlyBrands = ["target","walmart","best buy","home depot","lowe's"]
}
