// Background service worker
// Bridges messages between popup.js and the native Swift host.

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === "getRecommendation") {
        browser.runtime.sendNativeMessage(
            "com.yourcompany.pointmaximizer.safari-extension",
            { domain: message.domain },
            (response) => {
                sendResponse(response || { hasCards: false });
            }
        );
        return true; // keep channel open for async response
    }
});
