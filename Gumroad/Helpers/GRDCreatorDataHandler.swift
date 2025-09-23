//
//  DataHandler.swift
//  iOSCreator
//
//  Created by Benjamin Reynolds on 6/10/15.
//  Copyright (c) 2015 GRD. All rights reserved.
//

import Foundation

// This class contains a variety of static methods for processing and formatting analytics data
open class GRDCreatorDataHandler {

    enum TimeRange: String, CaseIterable {
        case Today = "Today"
        case Monthly = "Monthly"
        case Alltime = "Alltime"
    }

    // iterates over an NSArray of purchases and formats it nicely as a List of swift Dictionaries
    public static func parsePurchases(_ purchases : NSArray) -> [ [String : String] ] {
        var allPurchases : [ [String : String] ] = []
        var newPurchase = [String : String]()
        for purchase : Any in purchases {
            if let purchaseDictionary = purchase as? NSDictionary {
                for (key, value) in purchaseDictionary {
                    if let purchaseKey = key as? String {
                        let purchaseValueString = "\(value)"
                        newPurchase[purchaseKey] = purchaseValueString
                    }
                }
                allPurchases.append(newPurchase)
            }
        }
        return allPurchases
    }

    // Conforms internal timerange representation to API's "day", "month", and "all" params
    public static func convertTimeRangeOptionToAPIRange(_ timeRangeOption : String) -> String {
        switch timeRangeOption {
        case GRDCreatorDataHandler.TimeRange.Today.rawValue:
            return "day"
        case GRDCreatorDataHandler.TimeRange.Monthly.rawValue:
            return "month"
        default:
            return "all"
        }
    }

    // formatted as yyyy-MM-dd
    public static func getFormattedStartDateString(_ timeRangeOption : String) -> String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var startDate = today
        if timeRangeOption == TimeRange.Today.rawValue {
            let secondsPerDay = 86400.0
            startDate = today.addingTimeInterval(-1 * secondsPerDay)

        } else if timeRangeOption == TimeRange.Monthly.rawValue {
            let secondsPerMonth = 2629743.83
            startDate = today.addingTimeInterval(-1 * secondsPerMonth)

        } else if timeRangeOption == TimeRange.Alltime.rawValue {
            let secondsPerYear = 2629743.83*12
            startDate = today.addingTimeInterval(-1 * secondsPerYear)
        }
        return formatter.string(from: startDate)
    }

    // end date is always today
    public static func getFormattedEndDateString(_ timeRangeOption : String) -> String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: today)
    }

    public static func getCurrentDateTimeWithTimezone() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return dateFormatter.string(from: now)
    }
}
