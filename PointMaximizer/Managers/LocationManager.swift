import Combine
import CoreLocation
import WidgetKit

/// Monitors the user's significant location changes, runs MerchantIntelligenceEngine
/// to resolve context, then writes a fresh WidgetData snapshot to the shared App Group
/// store and reloads widget timelines.
final class LocationManager: NSObject, ObservableObject {

    // MARK: - Published state (drives main-app UI)
    @Published var currentContext: MerchantContext = MerchantContext(
        category:     .other,
        confidence:   0,
        merchantName: "",
        enrichedName: "",
        contextTag:   "",
        signals:      []
    )
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    // Continuation for tap-to-check one-shot location requests
    private var oneShotContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus = manager.authorizationStatus
    }

    // MARK: - Public

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        // Cell-tower-based, wakes the app on significant position changes (~500 m).
        // Very battery-friendly; perfect for keeping widget data fresh in the background.
        manager.startMonitoringSignificantLocationChanges()
    }

    /// One-shot location fix for the tap-to-check flow.
    /// Returns the best available location within ~3 seconds, or nil on failure.
    func requestCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            oneShotContinuation = continuation
            manager.requestLocation()
        }
    }

    // MARK: - Resolve location → MerchantContext → WidgetData + Notifications + Live Activity

    private func resolve(location: CLLocation) {
        Task {
            let context = await MerchantIntelligenceEngine.shared.analyze(
                location: location,
                at: Date()
            )
            await MainActor.run {
                self.currentContext = context

                // 1. Update shared widget data
                let snapshot = SharedDataManager.shared.buildWidgetData(
                    merchantName: context.merchantName,
                    enrichedName: context.enrichedName,
                    contextTag:   context.contextTag,
                    confidence:   context.confidence,
                    category:     context.category
                )
                SharedDataManager.shared.saveWidgetData(snapshot)

                // 2. Fire smart notification + Live Activity only when at a real store
                if let (bestCard, multiplier) = SharedDataManager.shared.bestCard(for: context.category),
                   context.confidence >= 0.6 {

                    // Proactive notification (throttled — won't spam)
                    NotificationManager.shared.scheduleIfAppropriate(
                        context:    context,
                        bestCard:   bestCard,
                        multiplier: multiplier
                    )
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            startMonitoring()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        // If a one-shot request is pending, fulfil it and skip the background resolve
        if let continuation = oneShotContinuation {
            oneShotContinuation = nil
            continuation.resume(returning: loc)
            return
        }

        // Background significant-change update
        resolve(location: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] \(error.localizedDescription)")
        // Unblock any waiting tap-to-check caller
        if let continuation = oneShotContinuation {
            oneShotContinuation = nil
            continuation.resume(returning: nil)
        }
    }
}
