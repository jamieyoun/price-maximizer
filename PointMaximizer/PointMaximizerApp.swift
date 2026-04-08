import SwiftUI
import UserNotifications

@main
struct PointMaximizerApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate (notification + lifecycle hooks)

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestPermission()
        return true
    }

    // Called when user taps a notification action while app is in foreground or background
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let lastFour = userInfo["cardLastFour"] as? String ?? ""

        switch response.actionIdentifier {
        case "OPEN_WALLET":
            // Find the matching card and open Wallet directly to it
            let cards = SharedDataManager.shared.loadCards()
            if let card = cards.first(where: { $0.lastFour == lastFour }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    WalletManager.shared.openWallet(for: card)
                }
            } else {
                WalletManager.shared.openWalletGeneric()
            }

        case UNNotificationDefaultActionIdentifier:
            // Tapped the notification body — open the app (ContentView handles the rest)
            break

        default:
            break
        }

        completionHandler()
    }

    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }
}
