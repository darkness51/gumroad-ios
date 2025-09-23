//
//  GRDLoginManager.swift
//  Gumroad
//
//  Created by Benjamin Reynolds on 7/15/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import CoreData
import NXOAuth2Client

class GRDLoginManager: NSObject {
    
    static let sharedInstance = GRDLoginManager()
    
    var twitterLoginUnsuccessfulNotificationString = "com.Gumroad.twitterLoginUnsuccessful"
    var appleLoginUnsuccessfulNotificationString = "com.Gumroad.appleLoginUnsuccessful"
    var googleLoginUnsuccessfulNotificationString = "com.Gumroad.googleLoginUnsuccessful"
    var loginSuccessfulNotificationString = "com.Gumroad.oauthLoginSuccessful"
    var loginErrorNotificationString = "com.Gumroad.oauthLoginError"

    var oauthObserver : NSObjectProtocol?
    var oauthFailureObserver : NSObjectProtocol?
    var isLoginInProgress : Bool = false
    
    var defaultEmail: String? {
        return UserDefaults.standard.string(forKey: "defaultEmail")
    }

    var facebookID: String? {
        return UserDefaults.standard.string(forKey: "facebookID")
    }

    var twitterID: String? {
        return UserDefaults.standard.string(forKey: "twitterID")
    }
    
    var appleUserID: String? {
        return UserDefaults.standard.string(forKey: "appleUserID")
    }
    
    var googleUserID: String? {
        return UserDefaults.standard.string(forKey: "googleUserID")
    }

    //MARK: - OAuth Observers

    func setupOAuthObservers() {
        // Setup success observer if uninitialized
        if self.oauthObserver == nil {
            self.oauthObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NXOAuth2AccountStoreAccountsDidChange, object: NXOAuth2AccountStore.sharedStore(), queue: nil) { [weak self] (oauthNotification) -> Void in
                if let userInfo = oauthNotification.userInfo {

                    if let oauthError = userInfo[NXOAuth2AccountStoreErrorKey] as? NSError {
                        self?.postNotificationForLoginError(userInfo, oauthError: oauthError)
                        return

                    } else {
                        self?.postNotificationForLoginSuccess(userInfo)
                        return
                    }
                }
                // Code should never reach this point
                let oauthError = oauthNotification.userInfo?[NXOAuth2AccountStoreErrorKey] as? NSError
                self?.postNotificationForLoginError(oauthNotification.userInfo, oauthError: oauthError)
                GRDNetworkRequest.shared.logoutUser() // ensure twitter/facebook/google gets logged out if we can't find a matching gumroad account
                return
            }
        }

        // Setup failure observer if uninitialized
        if self.oauthFailureObserver == nil {
            self.oauthFailureObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NXOAuth2AccountStoreDidFailToRequestAccess, object: NXOAuth2AccountStore.sharedStore(), queue: nil) { [weak self] (oauthNotification) -> Void in

                let oauthError = oauthNotification.userInfo?[NXOAuth2AccountStoreErrorKey] as? NSError
                self?.postNotificationForLoginError(oauthNotification.userInfo, oauthError: oauthError)
                GRDNetworkRequest.shared.logoutUser() // ensure twitter/facebook/google gets logged out if we can't find a matching gumroad account
                return
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(logoutSocialAccounts), name: NSNotification.Name(rawValue: GRDNotificationStrings.logoutSocialAccountsNotificationString()), object: nil)
    }

    func removeOAuthObservers() {
        if let oauthObserver = self.oauthObserver {
            NotificationCenter.default.removeObserver(oauthObserver)
        }
        if let oauthFailureObserver = self.oauthFailureObserver {
            NotificationCenter.default.removeObserver(oauthFailureObserver)
        }

        self.oauthObserver = nil
        self.oauthFailureObserver = nil
    }
    
    @objc func logoutSocialAccounts(_ notification: Notification) {
        GRDLoginManager.sharedInstance.setDefaultUserEmailForLogin("")
        GRDLoginManager.sharedInstance.setCurrentFacebookID("")
        GRDLoginManager.sharedInstance.setCurrentTwitterID("")
        GRDLoginManager.sharedInstance.setCurrentAppleUserID("")
        GRDLoginManager.sharedInstance.setCurrentGoogleUserID("")
    }
    
    func logout() {
        GRDNetworkRequest.shared.logoutUser()
        CoreDataManager.shared.removeAllProducts()
        UserDefaults.standard.removeObject(forKey: recentlyViewedUserDefaultsKey)
    
        // clear cache and app group's NSUserDefaults, so data is no longer accessible to unauthenticated watch app
        GRDRemoteWatchDataCache.sharedInstance.invalidateCache()
        let defaults = UserDefaults(suiteName: appGroupName)
        for keyName in [GRDCreatorDataHandler.TimeRange.Today.rawValue,
                        GRDCreatorDataHandler.TimeRange.Monthly.rawValue,
                        GRDCreatorDataHandler.TimeRange.Alltime.rawValue,
                        accountObjectUserDefaultsKey] {
            defaults?.removeObject(forKey: keyName)
        }
    }

    // MARK: - Attempt Login

    func attemptLogin(_ email: String, password: String) -> Void {
        guard !isLoginInProgress else { return }
        (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).requestAccessToAccount(withType: "Gumroad", username: email, password: password)
        isLoginInProgress = true
    }

    func attemptTwitterLogin(_ twitterToken: String) {
        if !isLoginInProgress {
            guard var config = (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).configuration(forAccountType: "Twitter") else { return }
            config[kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters] = ["twitterToken":twitterToken]
            let accountStore = NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore
            accountStore.setConfiguration(config, forAccountType: "Twitter")
            accountStore.requestAccessToAccount(withType: "Twitter", username: "", password: "")
            isLoginInProgress = true
        }
    }

    func attemptFacebookLogin(_ facebookToken: String) {
        if !isLoginInProgress {
            guard var config = (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).configuration(forAccountType: "Facebook") else { return }
            config[kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters] = ["facebookToken":facebookToken]
            let accountStore = NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore
            accountStore.setConfiguration(config, forAccountType: "Facebook")
            accountStore.requestAccessToAccount(withType: "Facebook", username: "", password: "")
            isLoginInProgress = true
        }
    }
    
    func attemptAppleLogin(_ authorizationCode: String) {
        if !isLoginInProgress {
            guard var config = (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).configuration(forAccountType: "Apple") else { return }
            config[kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters] = ["appleAuthorizationCode":authorizationCode, "appleAppType": "consumer"]
            let accountStore = NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore
            accountStore.setConfiguration(config, forAccountType: "Apple")
            accountStore.requestAccessToAccount(withType: "Apple", username: "", password: "")
            isLoginInProgress = true
        }
    }
    
    func attemptGoogleLogin(_ googleToken: String) {
        if !isLoginInProgress {
            guard var config = (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).configuration(forAccountType: "Google") else { return }
            config[kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters] = ["googleIdToken":googleToken]
            let accountStore = NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore
            accountStore.setConfiguration(config, forAccountType: "Google")
            accountStore.requestAccessToAccount(withType: "Google", username: "", password: "")
            isLoginInProgress = true
        }
    }

    // MARK: - Post Notifications about login state changes

    func postNotificationForLoginSuccess(_ userInfo: [AnyHashable : Any]) {
        isLoginInProgress = false
        if let newAccountUserInfo: AnyObject = userInfo[NXOAuth2AccountStoreNewAccountUserInfoKey] as? NXOAuth2Account {
            if let accountType = (newAccountUserInfo as? NXOAuth2Account)?.accountType {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: loginSuccessfulNotificationString), object: nil, userInfo: ["accountType": accountType])
            }
        }
    }

    func postNotificationForLoginError(_ userInfo: [AnyHashable : Any]?, oauthError: Error?) {
        isLoginInProgress = false
        // as a fallback, always send a notification of an error even if we don't have as much info about it as we'd like
        var errorString = "unknown"
        if let error = oauthError {
            errorString = error.localizedDescription
        }
        var accountTypeString = "Gumroad"
        if let accountType = userInfo?[kNXOAuth2AccountStoreAccountType] as? String {
            accountTypeString = accountType
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.loginErrorNotificationString), object: nil, userInfo: ["accountType": accountTypeString, "oauthError": errorString])
    }
    
    func postNotificationForTwitterLoginUnsuccessful() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.twitterLoginUnsuccessfulNotificationString), object: nil)
    }

    func postNotificationForAppleLoginUnsuccessful() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.appleLoginUnsuccessfulNotificationString), object: nil)
    }
    
    func postNotificationForGoogleLoginUnsuccessful() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.googleLoginUnsuccessfulNotificationString), object: nil)
    }

    // MARK: - Save UserID

    func setDefaultUserEmailForLogin(_ email : String?) {
        if let userEmail = email {
            UserDefaults.standard.set(userEmail, forKey: "defaultEmail")
        }
    }
    
    func setCurrentFacebookID(_ userID : String) {
        UserDefaults.standard.set(userID, forKey: "facebookID")
    }
    
    func setCurrentTwitterID(_ userID : String) {
        UserDefaults.standard.set(userID, forKey: "twitterID")
    }
    
    func setCurrentAppleUserID(_ userID : String) {
        UserDefaults.standard.set(userID, forKey: "appleUserID")
    }
    
    func setCurrentGoogleUserID(_ userID : String) {
        UserDefaults.standard.set(userID, forKey: "googleUserID")
    }
    
    // MARK: - Event Logging
    
    func logSuccessfulLoginEvent(_ params : [String : String]) {
        logEvent("user_login_succeeded", params: params)
    }
    
    func logFailedLoginEvent(_ params : [String : String]) {
        logEvent("user_login_failed", params: params)
    }
}
