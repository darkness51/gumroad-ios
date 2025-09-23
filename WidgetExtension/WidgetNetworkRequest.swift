//
//  WidgetNetworkRequest.swift
//  WidgetExtension
//
//  Created by Nathan Chan on 10/17/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import Foundation
import AFNetworking
import NXOAuth2Client

class WidgetNetworkRequest: NSObject {
    
    static let shared = WidgetNetworkRequest()
    
    var fetchOAuthApplicationInformation: Dictionary<String, String> {
        return [
            "client_id": ROT13.encode(Environment.oauthClientID),
            "secret_id": ROT13.encode(Environment.oauthSecretID),
            "authorization_url": "\(Environment.rootURLString)/oauth/authorize",
            "token_url": "\(Environment.rootURLString)/oauth/token",
            "redirect_uri": Environment.rootURLString
        ]
    }
    
    var revenueTotalsUrlString: String {
        return "\(Environment.apiURLString)/analytics/revenue_totals.json"
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
}
