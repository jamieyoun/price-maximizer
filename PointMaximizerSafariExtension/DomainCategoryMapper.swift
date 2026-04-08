import Foundation

/// Maps e-commerce domains to StoreCategory so the Safari Extension
/// can recommend the right card for online purchases.
struct DomainCategoryMapper {

    static func category(for host: String) -> (StoreCategory, String) {
        let domain = host.lowercased()
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: "m.",   with: "")

        for (pattern, category, displayName) in categoryRules {
            if domain.contains(pattern) {
                return (category, displayName)
            }
        }
        return (.other, "Online Purchase")
    }

    // (domain keyword, category, display name shown in popup)
    private static let categoryRules: [(String, StoreCategory, String)] = [

        // MARK: Grocery / Food delivery
        ("amazon.com",         .retail,  "Amazon"),
        ("amazon.",            .retail,  "Amazon"),
        ("wholefoodsmarket",   .grocery, "Whole Foods"),
        ("instacart",          .grocery, "Instacart"),
        ("walmart.com",        .grocery, "Walmart"),
        ("target.com",         .retail,  "Target"),
        ("kroger",             .grocery, "Kroger"),
        ("safeway",            .grocery, "Safeway"),
        ("albertsons",         .grocery, "Albertsons"),
        ("shipt",              .grocery, "Shipt"),
        ("freshdirect",        .grocery, "FreshDirect"),
        ("missfresh",          .grocery, "MissFresh"),
        ("peapod",             .grocery, "Peapod"),
        ("thrive",             .grocery, "Thrive Market"),
        ("vitacost",           .grocery, "Vitacost"),

        // MARK: Dining / Food delivery
        ("doordash",           .dining,  "DoorDash"),
        ("ubereats",           .dining,  "Uber Eats"),
        ("grubhub",            .dining,  "Grubhub"),
        ("seamless",           .dining,  "Seamless"),
        ("postmates",          .dining,  "Postmates"),
        ("caviar",             .dining,  "Caviar"),
        ("opentable",          .dining,  "OpenTable"),
        ("yelp",               .dining,  "Yelp"),
        ("chipotle",           .dining,  "Chipotle"),
        ("dominos",            .dining,  "Domino's"),
        ("pizzahut",           .dining,  "Pizza Hut"),
        ("papajohns",          .dining,  "Papa Johns"),
        ("mcdonalds",          .dining,  "McDonald's"),
        ("starbucks",          .dining,  "Starbucks"),
        ("dunkindonuts",       .dining,  "Dunkin'"),
        ("dunkin.",            .dining,  "Dunkin'"),
        ("panera",             .dining,  "Panera"),
        ("chick-fil-a",        .dining,  "Chick-fil-A"),
        ("chickfila",          .dining,  "Chick-fil-A"),
        ("tiffins",            .dining,  "Restaurant"),

        // MARK: Travel
        ("expedia",            .travel,  "Expedia"),
        ("booking.com",        .travel,  "Booking.com"),
        ("hotels.com",         .travel,  "Hotels.com"),
        ("priceline",          .travel,  "Priceline"),
        ("kayak",              .travel,  "Kayak"),
        ("airbnb",             .travel,  "Airbnb"),
        ("vrbo",               .travel,  "VRBO"),
        ("google.com/travel",  .travel,  "Google Flights"),
        ("google.com/flights", .travel,  "Google Flights"),
        ("skyscanner",         .travel,  "Skyscanner"),
        ("united.com",         .travel,  "United Airlines"),
        ("delta.com",          .travel,  "Delta"),
        ("aa.com",             .travel,  "American Airlines"),
        ("southwest.com",      .travel,  "Southwest"),
        ("jetblue",            .travel,  "JetBlue"),
        ("alaskaair",          .travel,  "Alaska Airlines"),
        ("spirit",             .travel,  "Spirit Airlines"),
        ("marriott",           .travel,  "Marriott"),
        ("hilton",             .travel,  "Hilton"),
        ("hyatt",              .travel,  "Hyatt"),
        ("ihg.com",            .travel,  "IHG"),
        ("wyndham",            .travel,  "Wyndham"),
        ("bestwestern",        .travel,  "Best Western"),
        ("hertz",              .travel,  "Hertz"),
        ("enterprise",         .travel,  "Enterprise"),
        ("avis",               .travel,  "Avis"),
        ("nationalcar",        .travel,  "National"),
        ("turo",               .travel,  "Turo"),
        ("uber.com",           .travel,  "Uber"),
        ("lyft",               .travel,  "Lyft"),
        ("amtrak",             .travel,  "Amtrak"),
        ("tripadvisor",        .travel,  "TripAdvisor"),
        ("getyourguide",       .travel,  "GetYourGuide"),
        ("viator",             .travel,  "Viator"),

        // MARK: Gas & Auto
        ("gasbuddy",           .gas,     "GasBuddy"),
        ("shell.us",           .gas,     "Shell"),
        ("chevron",            .gas,     "Chevron"),
        ("exxon",              .gas,     "ExxonMobil"),
        ("mobil",              .gas,     "Mobil"),
        ("bp.com",             .gas,     "BP"),
        ("autozone",           .gas,     "AutoZone"),
        ("oreillyauto",        .gas,     "O'Reilly Auto"),
        ("advanceautoparts",   .gas,     "Advance Auto"),
        ("pepboys",            .gas,     "Pep Boys"),
        ("geico",              .gas,     "GEICO"),
        ("progressive",        .gas,     "Progressive"),
        ("statefarm",          .gas,     "State Farm"),

        // MARK: Retail / Shopping
        ("ebay",               .retail,  "eBay"),
        ("etsy",               .retail,  "Etsy"),
        ("walmart",            .retail,  "Walmart"),
        ("bestbuy",            .retail,  "Best Buy"),
        ("apple.com",          .retail,  "Apple Store"),
        ("costco",             .retail,  "Costco"),
        ("samsclub",           .retail,  "Sam's Club"),
        ("homedepot",          .retail,  "Home Depot"),
        ("lowes",              .retail,  "Lowe's"),
        ("wayfair",            .retail,  "Wayfair"),
        ("ikea",               .retail,  "IKEA"),
        ("chewy",              .retail,  "Chewy"),
        ("petco",              .retail,  "Petco"),
        ("petsmart",           .retail,  "PetSmart"),
        ("nordstrom",          .retail,  "Nordstrom"),
        ("macys",              .retail,  "Macy's"),
        ("bloomingdales",      .retail,  "Bloomingdale's"),
        ("saks",               .retail,  "Saks"),
        ("neiman",             .retail,  "Neiman Marcus"),
        ("gap.com",            .retail,  "Gap"),
        ("gap.",               .retail,  "Gap"),
        ("oldnavy",            .retail,  "Old Navy"),
        ("bananarepublic",     .retail,  "Banana Republic"),
        ("hm.com",             .retail,  "H&M"),
        ("zara",               .retail,  "Zara"),
        ("uniqlo",             .retail,  "Uniqlo"),
        ("lululemon",          .retail,  "Lululemon"),
        ("nike",               .retail,  "Nike"),
        ("adidas",             .retail,  "Adidas"),
        ("underarmour",        .retail,  "Under Armour"),
        ("asos",               .retail,  "ASOS"),
        ("revolve",            .retail,  "Revolve"),
        ("sephora",            .retail,  "Sephora"),
        ("ulta",               .retail,  "Ulta"),
        ("tjmaxx",             .retail,  "TJ Maxx"),
        ("marshalls",          .retail,  "Marshalls"),
        ("ross",               .retail,  "Ross"),
        ("dollartree",         .retail,  "Dollar Tree"),
        ("dollargeneral",      .retail,  "Dollar General"),
        ("gamestop",           .retail,  "GameStop"),
        ("walgreens",          .retail,  "Walgreens"),
        ("cvs",                .retail,  "CVS"),
        ("riteaid",            .retail,  "Rite Aid"),
        ("shein",              .retail,  "SHEIN"),
        ("temu",               .retail,  "Temu"),
        ("wish",               .retail,  "Wish"),
        ("overstock",          .retail,  "Overstock"),
        ("zappos",             .retail,  "Zappos"),
    ]
}
