//
//  GRDNetworkRequest.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 1/16/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import Foundation
import AFNetworking
import NXOAuth2Client
import TwitterKit
import FBSDKLoginKit
import GoogleSignIn

class GRDNetworkRequest: NSObject {

    static let shared = GRDNetworkRequest()

    enum accountType: String, CaseIterable {
        case Gumroad, Twitter, Facebook, Apple, Google
    }

    // MARK: - Paths

    var fetchExistingPurchasesUrlString: String {
        "\(Environment.apiURLString)/purchases/index.json"
    }

    var archivePurchaseUrlString: String {
        "\(Environment.apiURLString)/purchases/%@/archive"
    }

    var unarchivePurchaseUrlString: String {
        "\(Environment.apiURLString)/purchases/%@/unarchive"
    }

    var fetchInstallmentWithExternalIdUrlString: String {
        "\(Environment.apiURLString)/installments/%@.json"
    }

    var mediaLocationsUrlString: String {
        "\(Environment.apiURLString)/media_locations.json"
    }

    var resetPasswordUrlString: String {
        "\(Environment.apiURLString)/forgot_password"
    }

    var externalEpubCSSStylingUrlString: String {
        "\(Environment.apiURLString)/ios-epub-styling.css"
    }

    var postDeviceTokenUrlString: String {
        return "\(Environment.apiURLString)/devices"
    }

    var creatorAnalyticsUrlString: String {
        return "\(Environment.apiURLString)/analytics/data_by_date.json"
    }

    var analyticsByDateUrlString: String {
        return "\(Environment.apiURLString)/analytics/by_date.json"
    }

    var analyticsByStateUrlString: String {
        return "\(Environment.apiURLString)/analytics/by_state.json"
    }

    var analyticsByReferralUrlString: String {
        return "\(Environment.apiURLString)/analytics/by_referral.json"
    }

    var revenueTotalsUrlString: String {
        return "\(Environment.apiURLString)/analytics/revenue_totals.json"
    }

    var productsUrlString: String {
        return "\(Environment.apiURLString)/analytics/products.json"
    }

    var salesUrlString: String {
        return "\(Environment.apiURLString)/sales/%@.json"
    }

    var saleRefundUrlString: String {
        return "\(Environment.apiURLString)/sales/%@/refund"
    }

    var recommendedProductsUrlString: String {
        return "\(Environment.apiURLString)/recommended_products.json"
    }

    var staffPickedProductsUrlString: String {
        return "\(Environment.apiURLString)/staff_picked_products.json"
    }

    var productDetailUrlString: String {
        return "\(Environment.apiURLString)/products/%@.json"
    }

    var sellerDetailUrlString: String {
        return "\(Environment.apiURLString)/sellers/%@.json"
    }

    var ordersUrlString: String {
        return "\(Environment.apiURLString)/orders"
    }

    var featureFlagsUrlString: String {
        return "\(Environment.apiURLString)/feature_flags/%@.json"
    }

    var productPageViewUrlString: String {
        return "\(Environment.apiURLString)/products/%@/product_page_views"
    }

    var productsSearchUrlString: String {
        return "\(Environment.apiURLString)/products"
    }

    var relatedProductsUrlString: String {
        return "\(Environment.apiURLString)/products/%@/related_products"
    }

    var categoriesUrlString: String {
        return "\(Environment.apiURLString)/taxonomies"
    }

    // MARK: - Actions

    func postDeviceToken(_ token: String) {
        guard
            let account = currentUserAccount,
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            else { return }

        let url = URL(string: postDeviceTokenUrlString)
        let requestParams = [
            "mobile_token": mobileToken,
            "device[token]": token,
            "device[device_type]": "ios",
            "device[app_type]": "consumer",
            "device[app_version]": appVersion
        ]

        guard let currentDataRequest = NXOAuth2Request(resource: url, method: "POST", parameters: requestParams) else { return }
        currentDataRequest.account = account
        currentDataRequest.perform(sendingProgressHandler: nil, responseHandler: { (_, _, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }

    func logoutUser() {
        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.cookies?.forEach { cookieStorage.deleteCookie($0) }

        for account in (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).accounts as! [NXOAuth2Account] {
            if GRDNetworkRequest.accountType(rawValue: account.accountType) != nil {
                (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).removeAccount(account)
            }
        }

        let facebookLoginManager = LoginManager()
        facebookLoginManager.logOut()

        guard (ProcessInfo.processInfo.environment["XCInjectBundle"] == nil) else { return }
        let twitterLoginManager = TWTRTwitter.sharedInstance()
        let sessionStore = twitterLoginManager.sessionStore
        if let twitterSession = sessionStore.session() {
            twitterLoginManager.sessionStore.logOutUserID(twitterSession.userID)
        }

        GIDSignIn.sharedInstance.signOut()

        NotificationCenter.default.post(name: Notification.Name(rawValue: GRDNotificationStrings.logoutSocialAccountsNotificationString()), object: nil)
    }

    func fetchExistingPurchases(successBlock: ((URLResponse, [String : Any]) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        NXOAuth2Request.performMethod("GET", onResource: URL(string: fetchExistingPurchasesUrlString), usingParameters: ["mobile_token": mobileToken, "include_subscriptions": "true", "include_mobile_unfriendly_products": "true"], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                guard let responseObject = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : Any] else { return }

                if let userId = responseObject["user_id"] as? String {
                    account.userData = userId as NSString
                }

                var purchases = responseObject["products"] as! [[String : Any]]
                let uniquePermalinkMapFunction = {  (purchase: [String : Any]) -> String in
                    return purchase["unique_permalink"] as! String
                }

                CoreDataManager.shared.removeAllPlaceholderProducts()

                let aliveUniquePermalinks = purchases.map(uniquePermalinkMapFunction)
                CoreDataManager.shared.removeInvalidProducts(with: aliveUniquePermalinks)

                for pInfo in purchases as [Dictionary] {
                    var productData = pInfo
                    var newProduct: Product?
                    if let fileInformation = productData["file_data"] as? [AnyHashable]  {
                        newProduct = CoreDataManager.shared.createProduct(with: productData, fileInformation: fileInformation)
                    } else {
                        let uniquePermalink = productData["unique_permalink"] as? String
                        if CoreDataManager.shared.getProduct(with: uniquePermalink) != nil {
                            newProduct = CoreDataManager.shared.getProduct(with: uniquePermalink)
                        } else {
                            newProduct = CoreDataManager.shared.createProduct(with: productData)
                        }
                    }
                    CoreDataManager.shared.updateProductInformation(productData, for: newProduct)
                }

                successBlock?(response!, responseObject)
            } catch let error {
                print(error.localizedDescription)
            }
        })
    }

    func archiveProduct(_ purchaseId: String, successBlock: (() -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let requestUrl = String(format: archivePurchaseUrlString, purchaseId)
        NXOAuth2Request.performMethod("POST", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            if let error = error {
                failureBlock?(error)
                return
            }
            successBlock?()
        })
    }

    func unarchiveProduct(_ purchaseId: String, successBlock: (() -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let requestUrl = String(format: unarchivePurchaseUrlString, purchaseId)
        NXOAuth2Request.performMethod("POST", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            if let error = error {
                failureBlock?(error)
                return
            }
            successBlock?()
        })
    }

    func fetchInstallment(with payload: [String: Any], successBlock: ((URLSessionDataTask, NSDictionary) -> Void)?, failureBlock: ((URLSessionDataTask, Error) -> Void)?) {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 5
        let sessionManager = AFHTTPSessionManager(sessionConfiguration: sessionConfiguration)
        let requestUrl = String(format: fetchInstallmentWithExternalIdUrlString, payload["installment_id"] as! String)
        var params = payload
        params["mobile_token"] = mobileToken
        sessionManager.get(requestUrl, parameters: params, headers: [:], progress: nil, success: { (task, rawResponseObject) -> Void in
            if let responseObject = rawResponseObject as? NSDictionary,
               let success = successBlock {
                success(task, responseObject)
            }
        }) { (task, error) -> Void in
            if let failure = failureBlock, let task = task {
                failure(task, error)
            }
        }
    }

    func getS3PlaylistUrl(_ file: File, successBlock: @escaping ((URL) -> Void), failureBlock: @escaping ((URLSessionDataTask, Error) -> Void)) -> URLSessionDataTask {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 10
        let sessionManager = AFHTTPSessionManager(sessionConfiguration: sessionConfiguration)
        return sessionManager.get((file.streaming_url! as NSString).appending(".json"), parameters: ["mobile_token": mobileToken], headers: [:], progress: nil, success: { (task, rawResponseObject) -> Void in
            if let responseObject = rawResponseObject as? NSDictionary {
                let s3StreamURL = responseObject.object(forKey: "playlist_url") as! String
                successBlock(URL(string: s3StreamURL)!)
            }
        }) { (task, error) -> Void in
            guard let task = task else { return }
            failureBlock(task, error)
        }!
    }

    func resetPassword(_ email: String, successBlock: (() -> Void)?, failureBlock: ((Error) ->  Void)?) -> URLSessionDataTask {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 5
        let sessionManager = AFHTTPSessionManager(sessionConfiguration: sessionConfiguration)
        return sessionManager.post(resetPasswordUrlString, parameters: ["user": ["email": email]], headers: [:], progress: nil, success: { (task, rawResponseObject) -> Void in
            if let success = successBlock {
                success()
            }
        }) { (task, error) -> Void in
            if let failure = failureBlock {
                failure(error)
            }
        }!
    }

    func updateMediaLocation(_ urlRedirectId: String, productFileId: String, purchaseId: String?, location: Int, successBlock: (() -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let params: [String: Any] = ["mobile_token": mobileToken, "platform": "iphone", "url_redirect_id": urlRedirectId, "product_file_id": productFileId, "purchase_id": purchaseId ?? "", "location": location]
        NXOAuth2Request.performMethod("POST", onResource: URL(string: mediaLocationsUrlString), usingParameters: params, with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            if let error = error {
                failureBlock?(error)
                return
            }
            successBlock?()
        })
    }

    //MARK: OAuth Logic

    var currentUserAccount: NXOAuth2Account? {
        guard let accountStore = NXOAuth2AccountStore.sharedStore() as? NXOAuth2AccountStore else { return nil }
        if let emailAccount = accountStore.accounts(withAccountType: "Gumroad").last as? NXOAuth2Account {
            return emailAccount
        } else if let facebookAccount = accountStore.accounts(withAccountType: "Facebook").last as? NXOAuth2Account {
            return facebookAccount
        } else if let twitterAccount = accountStore.accounts(withAccountType: "Twitter").last as? NXOAuth2Account {
            return twitterAccount
        } else if let appleAccount = accountStore.accounts(withAccountType: "Apple").last as? NXOAuth2Account {
            return appleAccount
        } else if let googleAccount = accountStore.accounts(withAccountType: "Google").last as? NXOAuth2Account {
            return googleAccount
        } else {
            return nil
        }
    }

    var fetchOAuthApplicationInformation: Dictionary<String, String> {
        return [
            "client_id": ROT13.encode(Environment.oauthClientID),
            "secret_id": ROT13.encode(Environment.oauthSecretID),
            "authorization_url": "\(Environment.rootURLString)/oauth/authorize",
            "token_url": "\(Environment.rootURLString)/oauth/token",
            "redirect_uri": Environment.rootURLString
        ]
    }

    var fetchTwitterApplicationInformation: Dictionary<String, String> {
        return [
            "TWITTER_APP_ID": Environment.twitterAppId,
            "TWITTER_APP_SECRET": Environment.twitterAppSecret,
        ]
    }

    // Primary method for requesting data for the user for the current time range
    func fetchCreatorAnalytics(_ timeRangeOption: String, query: String? = nil, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)? ) {
        guard let account = currentUserAccount else { return }

        fetchCreatorAnalytics(with: account, timeRangeOption: timeRangeOption, query: query, successBlock: successBlock, failureBlock: failureBlock)
    }

    func fetchCreatorAnalytics(with account: NXOAuth2Account, timeRangeOption: String, query: String? = nil, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let range = GRDCreatorDataHandler.convertTimeRangeOptionToAPIRange(timeRangeOption)
        let currentTime = GRDCreatorDataHandler.getCurrentDateTimeWithTimezone()
        var requestParams = ["mobile_token": mobileToken, "range": range, "end_time": currentTime]

        // Add query parameter if provided
        if let query = query {
            requestParams["query"] = query
        }

        let currentDataRequest = NXOAuth2Request(resource: URL(string: creatorAnalyticsUrlString), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchAnalyticsByDate(_ dateRange: DateRange, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let requestParams = ["mobile_token": mobileToken,
                             "date_range": dateRange.rawValue,
                             "group_by": [.year, .all].contains(dateRange) ? "month" : "day"]
        let currentDataRequest = NXOAuth2Request(resource: URL(string: analyticsByDateUrlString), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchAnalyticsByState(_ dateRange: DateRange, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let requestParams = ["mobile_token": mobileToken, "date_range": dateRange.rawValue]
        let currentDataRequest = NXOAuth2Request(resource: URL(string: analyticsByStateUrlString), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchAnalyticsByReferral(_ dateRange: DateRange, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let requestParams = ["mobile_token": mobileToken,
                             "date_range": dateRange.rawValue,
                             "group_by": [.year, .all].contains(dateRange) ? "month" : "day"]
        let currentDataRequest = NXOAuth2Request(resource: URL(string: analyticsByReferralUrlString), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchRevenueTotals(with account: NXOAuth2Account, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let requestParams = ["mobile_token": mobileToken]
        let currentDataRequest = NXOAuth2Request(resource: URL(string: revenueTotalsUrlString), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchProducts(successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {

        guard let account = currentUserAccount else { return }

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let requestParams = ["mobile_token": mobileToken]
        let currentDataRequest = NXOAuth2Request(resource: URL(string: productsUrlString), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchSale(with saleId: String, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {

        guard let account = currentUserAccount else { return }

        if let archivedObj = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: false) {
            UserDefaults(suiteName: appGroupName)?.set(archivedObj, forKey: accountObjectUserDefaultsKey)
        }

        let requestParams = ["mobile_token": mobileToken]
        let currentDataRequest = NXOAuth2Request(resource: URL(string: String(format: salesUrlString, saleId)), method: "GET", parameters: requestParams)
        currentDataRequest?.account = account
        currentDataRequest?.perform(sendingProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func refundSale(purchaseId: String, amount: String, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {

        guard let account = currentUserAccount else { return }

        let requestUrl = String(format: saleRefundUrlString, purchaseId)
        NXOAuth2Request.performMethod("PATCH", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken, "amount": amount], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            if let error = error {
                failureBlock?(error)
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func fetchRecommendedProducts(successBlock: (([DiscoverProduct]) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        NXOAuth2Request.performMethod("GET", onResource: URL(string: recommendedProductsUrlString), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let productsContainer = try JSONDecoder().decode(DiscoverProductsContainer.self, from: responseData)
                successBlock?(productsContainer.products)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }

    func fetchStaffPickedProducts(page: Int, successBlock: (([DiscoverProduct]) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        var requestParams = [
            "mobile_token": mobileToken,
            "page": String(page)
        ]
        NXOAuth2Request.performMethod("GET", onResource: URL(string: staffPickedProductsUrlString), usingParameters: requestParams, with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let productsContainer = try JSONDecoder().decode(DiscoverProductsContainer.self, from: responseData)
                successBlock?(productsContainer.products)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }

    func fetchProductDetails(permalink: String, successBlock: ((DiscoverProductDetailContainer) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let requestUrl = String(format: productDetailUrlString, permalink)
        NXOAuth2Request.performMethod("GET", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let productContainer = try JSONDecoder().decode(DiscoverProductDetailContainer.self, from: responseData)
                successBlock?(productContainer)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }

    func fetchSellerDetails(id: String, successBlock: ((DiscoverSellerDetail) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let requestUrl = String(format: sellerDetailUrlString, id)
        NXOAuth2Request.performMethod("GET", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let sellerContainer = try JSONDecoder().decode(DiscoverSellerDetailContainer.self, from: responseData)
                successBlock?(sellerContainer.seller)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }

    func orderProduct(transactionId: String, permalink: String, recommendationType: DiscoverRecommendationType?, purchaseType: String?, successBlock: ((URLResponse, NSDictionary) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        var requestParams: [String: Any] = [
            "mobile_token": mobileToken,
            "order[app_store_transaction_id]": transactionId,
            "order[permalink]": permalink
        ]
        if let recommendationType = recommendationType {
            requestParams["order[recommended_by]"] = recommendationType.rawValue
        }
        if purchaseType == "rent_only" {
            requestParams["order[is_rental]"] = true
        }
        NXOAuth2Request.performMethod("POST", onResource: URL(string: ordersUrlString), usingParameters: requestParams, with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            if let error = error {
                failureBlock?(error)
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock {
                    success(response!, responseObject)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func featureFlagCheck(id: String, successBlock: ((Bool) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let requestUrl = String(format: featureFlagsUrlString, id)
        NXOAuth2Request.performMethod("GET", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil else {
                if let failure = failureBlock { failure(error!) }
                return
            }

            if let responseObject = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? NSDictionary {
                if let success = successBlock,
                   let data = responseObject as? [String: Any] {
                    success(data["enabled_for_user"] as? Bool ?? false)
                    return
                }
            }

            // if it can't be parsed, respond with an error
            if let failure = failureBlock {
                failure(NSError(domain: "Cannot parse data", code: 400, userInfo: nil))
            }
        })
    }

    func productPageView(permalink: String, successBlock: (() -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        let requestUrl = String(format: productPageViewUrlString, permalink)
        NXOAuth2Request.performMethod("POST", onResource: URL(string: requestUrl), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            if let error = error {
                failureBlock?(error)
                return
            }
            successBlock?()
        })
    }

    func productsSearch(query: String, taxonomyId: String? = nil, tags: [DiscoverTag], filetypes: [DiscoverFileType], successBlock: ((DiscoverSearchContainer) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        var requestParams: [String: Any] = [
            "mobile_token": mobileToken,
            "query": query,
            "size": "100",
            "sort": "featured"
        ]
        if let taxonomyId = taxonomyId {
            requestParams["taxonomy_id"] = taxonomyId
            requestParams["include_taxonomy_descendants"] = "true"
        }
        if tags.count > 0 {
            requestParams["tags"] = tags.map { $0.key }.joined(separator: ",")
        }
        if filetypes.count > 0 {
            requestParams["filetypes"] = filetypes.map { $0.key }.joined(separator: ",")
        }
        NXOAuth2Request.performMethod("GET", onResource: URL(string: productsSearchUrlString), usingParameters: requestParams, with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let searchContainer = try JSONDecoder().decode(DiscoverSearchContainer.self, from: responseData)
                successBlock?(searchContainer)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }

    func relatedProducts(permalink: String, context: String? = nil, successBlock: (([DiscoverProduct]) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        var requestParams: [String: Any] = [
            "mobile_token": mobileToken
        ]
        if let context = context {
            requestParams["context"] = context
        }
        let requestUrl = String(format: relatedProductsUrlString, permalink)
        NXOAuth2Request.performMethod("GET", onResource: URL(string: requestUrl), usingParameters: requestParams, with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let productsContainer = try JSONDecoder().decode(DiscoverProductsContainer.self, from: responseData)
                successBlock?(productsContainer.products)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }

    func fetchCategories(successBlock: (([DiscoverCategory]) -> Void)?, failureBlock: ((Error) -> Void)?) {
        guard let account = currentUserAccount else { return }
        NXOAuth2Request.performMethod("GET", onResource: URL(string: categoriesUrlString), usingParameters: ["mobile_token": mobileToken], with: account, sendProgressHandler: nil, responseHandler: { (response, responseData, error) -> Void in
            guard error == nil, let responseData = responseData else {
                failureBlock?(error!)
                return
            }
            do {
                let categoriesContainer = try JSONDecoder().decode(DiscoverCategoriesContainer.self, from: responseData)
                successBlock?(categoriesContainer.categories)
            } catch let error {
                print(error.localizedDescription)
                failureBlock?(error)
            }
        })
    }
}
