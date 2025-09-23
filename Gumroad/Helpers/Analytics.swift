//
//  Analytics.swift
//  Gumroad
//
//  Created by Nathan Chan on 2/20/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import Foundation
import FirebaseAnalytics

func logEvent(_ eventName: String, params: [String: Any]? = nil) {
    print("Logging analytics event: \(eventName) —— params: \(params ?? [:])")
    #if NDEBUG
    Analytics.logEvent(eventName, parameters: params)
    #endif
}
