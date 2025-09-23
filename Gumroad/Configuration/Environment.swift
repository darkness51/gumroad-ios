//
//  Environment.swift
//  Gumroad
//
//  Created by Matthew Whittaker on 12/11/19.
//  Copyright © 2019 GRD. All rights reserved.
//

import Foundation

public enum Environment {

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }

        return dict
    }()

    static let rootURLString: String = {
        guard let rootURLstring = Environment.infoDictionary["ROOT_URL"] as? String else {
            fatalError("Root URL not set in plist for this environment")
        }

        return rootURLstring
    }()

    static let apiURLString: String = {
        guard let apiURLstring = Environment.infoDictionary["API_URL"] as? String else {
            fatalError("API URL not set in plist for this environment")
        }

        return apiURLstring
    }()

    static let oauthClientID: String = {
        guard let oauthClientID = Environment.infoDictionary["OAUTH_CLIENT_ID"] as? String else {
            fatalError("Client ID not set in plist for this environment")
        }

        return oauthClientID
    }()

    static let oauthSecretID: String = {
        guard let oauthSecretID = Environment.infoDictionary["OAUTH_SECRET_ID"] as? String else {
            fatalError("Secret ID not set in plist for this environment")
        }

        return oauthSecretID
    }()

    static let mobileToken: String = {
        guard let mobileToken = Environment.infoDictionary["MOBILE_TOKEN"] as? String else {
            fatalError("Mobile Token not set in plist for this environment")
        }

        return mobileToken
    }()

    static let twitterAppId: String = {
        guard let twitterAppId = Environment.infoDictionary["TWITTER_APP_ID"] as? String else {
            fatalError("Twitter App ID not set in plist for this environment")
        }

        return twitterAppId
    }()

    static let twitterAppSecret: String = {
        guard let twitterAppSecret = Environment.infoDictionary["TWITTER_APP_SECRET"] as? String else {
            fatalError("Twitter App Secret not set in plist for this environment")
        }

        return twitterAppSecret
    }()

}
