// Category → emoji icon mapping
const categoryIcons = {
    "Grocery":    "🛒",
    "Dining":     "🍽️",
    "Gas & Auto": "⛽",
    "Travel":     "✈️",
    "Shopping":   "🛍️",
    "Other":      "💳",
};

// Reward label → color
function rewardColor(multiplier) {
    if (multiplier >= 4) return "#30D158";  // green
    if (multiplier >= 2) return "#FF9F0A";  // orange
    return "#FFFFFF";
}

// Hex color with opacity for card chip background
function hexWithAlpha(hex, alpha) {
    const r = parseInt(hex.slice(1,3), 16);
    const g = parseInt(hex.slice(3,5), 16);
    const b = parseInt(hex.slice(5,7), 16);
    return `rgba(${r},${g},${b},${alpha})`;
}

async function init() {
    // Get current tab URL
    const tabs = await browser.tabs.query({ active: true, currentWindow: true });
    const url  = tabs[0]?.url ?? "";
    let domain = "";
    try { domain = new URL(url).hostname; } catch (_) {}

    // Ask native host for recommendation
    const rec = await new Promise((resolve) => {
        browser.runtime.sendMessage(
            { type: "getRecommendation", domain },
            (response) => resolve(response || { hasCards: false })
        );
    });

    document.getElementById("loading").classList.add("hidden");

    if (!rec.hasCards) {
        document.getElementById("no-cards").classList.remove("hidden");
        document.getElementById("open-app-btn").addEventListener("click", () => {
            browser.tabs.create({ url: "pointmaximizer://open" });
        });
        return;
    }

    // Populate recommendation UI
    const el = document.getElementById("recommendation");
    el.classList.remove("hidden");

    document.getElementById("merchant-icon").textContent =
        categoryIcons[rec.category] ?? "💳";
    document.getElementById("merchant-name").textContent  = rec.displayName;
    document.getElementById("category-label").textContent = rec.category;
    document.getElementById("card-name").textContent      = rec.cardName;
    document.getElementById("card-digits").textContent    = `•••• ${rec.cardLastFour}`;

    // Card chip color
    const chip = document.getElementById("card-chip");
    chip.style.background =
        `linear-gradient(135deg, ${rec.cardColorHex}, ${hexWithAlpha(rec.cardColorHex, 0.6)})`;

    // Reward label + color
    const rewardEl = document.getElementById("reward-label");
    rewardEl.textContent   = rec.rewardLabel;
    rewardEl.style.color   = rewardColor(rec.multiplier);

    // Open Wallet button → deep link into app which redirects to Wallet
    document.getElementById("wallet-btn").addEventListener("click", () => {
        const lastFour  = encodeURIComponent(rec.cardLastFour);
        const category  = encodeURIComponent(rec.category);
        browser.tabs.update({ url: `pointmaximizer://open?card=${lastFour}&category=${category}` });
    });
}

init();
