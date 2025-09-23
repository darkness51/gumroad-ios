//
//  GRDAppDelegate.swift
//  Gumroad
//
//  Created by Matthew Whittaker on 8/29/19.
//  Copyright © 2019 Gumroad. All rights reserved.
//

import TwitterKit
import FBSDKCoreKit
import NXOAuth2Client
import Bugsnag
import PSPDFKit
import GoogleSignIn
import WidgetKit
import FirebaseCore

@UIApplicationMain
class GRDAppDelegate: UIResponder, UIApplicationDelegate {

    let miniPlayerWindow = MiniPlayerWindow(frame: UIScreen.main.bounds)
    var window: UIWindow? {
        get { return miniPlayerWindow }
        set { }
    }

    func isMiniPlayerShown() -> Bool {
        return miniPlayerWindow.isMiniPlayerShown()
    }

    func showMiniPlayer(audioPlayerVC: AudioPlayerViewController) {
        miniPlayerWindow.showMiniPlayer(audioPlayerVC: audioPlayerVC)
    }

    func hideMiniPlayer() {
        miniPlayerWindow.hideMiniPlayer()
    }

    @objc func updateMiniPlayerFrame() {
        miniPlayerWindow.updateMiniPlayerFrame()
    }

    func updateMiniPlayerDisplay() {
        miniPlayerWindow.updateMiniPlayerDisplay()
    }

    func updateMiniPlayerDisplay(percentage: Float) {
        miniPlayerWindow.updateMiniPlayerProgressBar(percentage: percentage)
    }

    func miniPlayerCurrentlyPlayingFileId() -> String? {
        return miniPlayerWindow.currentlyPlayingFileId()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Setup error reporting
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "BugsnagAPIKey") as? String {
            Bugsnag.start(withApiKey: apiKey)
        }

        #if NDEBUG
        FirebaseApp.configure()
        #endif

        let openCount = UserDefaults.standard.integer(forKey: appOpenCountUserDefaultsKey)
        UserDefaults.standard.set(openCount + 1, forKey: appOpenCountUserDefaultsKey)

        if let licenseKey = Bundle.main.object(forInfoDictionaryKey: "SDK_LICENSE_KEY") as? String {
            SDK.setLicenseKey(licenseKey)
        }


        let twitterAppInformation = GRDNetworkRequest.shared.fetchTwitterApplicationInformation
        if let twtrAppID = twitterAppInformation["TWITTER_APP_ID"], let twtrAppSecret = twitterAppInformation["TWITTER_APP_SECRET"] {
            TWTRTwitter.sharedInstance().start(withConsumerKey: twtrAppID, consumerSecret: twtrAppSecret)
        }

        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in }

        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        let oauthAppInformation = GRDNetworkRequest.shared.fetchOAuthApplicationInformation
        let clientID = oauthAppInformation["client_id"]
        let secret = oauthAppInformation["secret_id"]
        let authorizationURL = oauthAppInformation["authorization_url"]
        let tokenURL = oauthAppInformation["token_url"]
        let redirectURL = oauthAppInformation["redirect_uri"]

        for accountType in GRDNetworkRequest.accountType.allCases {
            let oauthStore = NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore
            oauthStore.setClientID(clientID,
                                   secret: secret,
                                   scope: NSSet(object: "mobile_api creator_api") as Set<NSObject>,
                                   authorizationURL: URL(string: authorizationURL!),
                                   tokenURL: URL(string: tokenURL!),
                                   redirectURL: URL(string: redirectURL!),
                                   keyChainGroup: "gumroad",
                                   forAccountType: accountType.rawValue
            )
        }

        CoreDataManager.shared.fetchAllFiles().forEach({ productFile in
            guard productFile.isDownloaded() else { return }
            do {
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                guard var fileURL = productFile.fileSystemURL() else { return }
                try fileURL.setResourceValues(resourceValues)
            } catch let error {
                print(error.localizedDescription)
            }
        })

        // Make sure all legacy data is cleaned up on fresh installs
        if FirstLaunch().isFirstLaunch {
            GRDNetworkRequest.shared.logoutUser()
            CoreDataManager.shared.removeAllProducts()
        }

        application.beginReceivingRemoteControlEvents()
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        CoreDataManager.shared.removeAllLoadingProducts()
        updateMiniPlayerDisplay()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        self.registerForPushNotifications()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.absoluteString.contains("twitterkit") {
            return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
        }

        if let facebookAppId = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
           url.absoluteString.contains("fb\(facebookAppId)") {
            return ApplicationDelegate.shared.application(app, open: url, options: options)
        }

        if url.absoluteString.contains("googleusercontent") {
            return GIDSignIn.sharedInstance.handle(url)
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false), components.path.hasPrefix("/d/") {
            // used via iOS smart banners https://developer.apple.com/documentation/webkit/promoting_apps_with_smart_app_banners
            logEvent("deep_link_smart_banner")
            openProduct(with: components.path.replacingOccurrences(of: "/d/", with: ""))
        } else if let param = url.host?.removingPercentEncoding, param == "d" {
            // custom url scheme: gumroad://d/<product_url_redirect_token>
            logEvent("deep_link_url_scheme")
            openProduct(with: url.lastPathComponent)
        }

        return true
    }

    func openProduct(with urlRedirectToken: String, maxAttempts: Int = 20, currentAttempt: Int = 0) {
        CoreDataManager.shared.setUrlRedirectToken(urlRedirectToken)

        if let rootViewController = self.window?.rootViewController as? LaunchViewController,
           let navigationController = rootViewController.presentedViewController as? GRDNavigationViewController {
            if let tabController = navigationController.topViewController as? MainTabViewController,
               let index = tabController.viewControllers?.firstIndex(where: { $0 is LibraryViewController }),
               let libraryViewController = tabController.viewControllers?[index] as? LibraryViewController {
                tabController.selectedIndex = index
                tabController.loadingView.isHidden = false
                libraryViewController.refreshNetworkData()
            } else if currentAttempt < maxAttempts {
                // App was previously opened on the ProductViewController or DiscoverViewController screen (or we might have deeper embedded views on the navigation stack), so pop view controllers until the LibraryViewController is the top view.
                navigationController.popViewController(animated: false)
                self.openProduct(with: urlRedirectToken, maxAttempts: maxAttempts, currentAttempt: currentAttempt + 1)
            }
        } else if currentAttempt < maxAttempts {
            // App was previously not opened so MainTabViewController has not fully loaded and viewDidLoads have not yet run on the first tab view controller (HomeViewController). Attempt retries until all views are loaded before opening the product.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openProduct(with: urlRedirectToken, maxAttempts: maxAttempts, currentAttempt: currentAttempt + 1)
            }
        }
    }
}

// MARK: - Push Notifications

extension GRDAppDelegate {

    func registerForPushNotifications() {
        // Don't register for push notifications in test process because
        // "Unfortunately due to iOS simulator security reasons it isn't possible to automate accepting iOS permission alerts using KIF."
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCInjectBundle"] == nil else { return }
        #endif

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        GRDNetworkRequest.shared.postDeviceToken(token)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if GRDNetworkRequest.shared.currentUserAccount == nil {
            logEvent("push_notification_logged_out")
            return
        }

        logEvent("push_notification_received")
        guard let payload = userInfo as? [String: Any],
            let _ = payload["installment_id"] as? String else { return }

        GRDNetworkRequest.shared.fetchInstallment(with: payload, successBlock: { (task, data) in
            guard let installmentInfo = data["installment"] as? [String: Any] else { return }
            logEvent("push_notification_installment_fetch_succeeded", params: ["payload": payload])
            if let installment = CoreDataManager.shared.updateInstallment(with: installmentInfo) {
                logEvent("push_notification_installment_modal_presented", params: ["payload": payload])
                let vc = InstallmentViewController.instantiate()
                vc.installment = installment
                vc.isPresentedModally = true
                UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController?.presentedViewController?.present(vc, animated: true, completion: nil)
            }
        }) { (task, error) in
            logEvent("push_notification_installment_fetch_failed", params: ["payload": payload, "error": error.localizedDescription])
            print(error.localizedDescription)
        }
    }
}

// MARK: - Convenience class to clean up legacy data on fresh install

final class FirstLaunch {
    let userDefaults: UserDefaults = .standard

    let wasLaunchedBefore: Bool
    var isFirstLaunch: Bool {
        return !wasLaunchedBefore
    }

    init() {
        let key = "com.gumroad.FirstLaunch.WasLaunchedBefore"
        let wasLaunchedBefore = userDefaults.bool(forKey: key)
        self.wasLaunchedBefore = wasLaunchedBefore
        if !wasLaunchedBefore {
            userDefaults.set(true, forKey: key)
        }
    }
}
