 //
//  GRDWatchDataCache.swift
//  iOSCreator
//
//  Created by Benjamin Reynolds on 6/18/15.
//  Copyright (c) 2015 GRD. All rights reserved.
//

import Foundation

open class GRDRemoteWatchDataCache {
    static let sharedInstance = GRDRemoteWatchDataCache()

    fileprivate var cachedRevenue : [String : String]?
    fileprivate var cachedRevenueInCents : [String : Int]?
    fileprivate var cachedSales : [String : Int]?
    fileprivate var cachedCustomers : [String : [[String : String]]]?

    fileprivate var cachedRevenueExpirationDate : [String : Date]?
    fileprivate var cachedRevenueInCentsExpirationDate : [String : Date]?
    fileprivate var cachedSalesExpirationDate : [String : Date]?
    fileprivate var cachedCustomersExpirationDate : [String : Date]?

    enum AnalyticsDataType {
        case revenue
        case revenueInCents
        case sales
        case customers
    }

    fileprivate init() {
        // initialize cache storage
        cachedSales = [String : Int]()
        cachedRevenue = [String : String]()
        cachedRevenueInCents = [String : Int]()
        cachedCustomers = [String : [[String : String]]]()

        cachedSalesExpirationDate = [String : Date]()
        cachedRevenueExpirationDate = [String : Date]()
        cachedRevenueInCentsExpirationDate = [String : Date]()
        cachedCustomersExpirationDate = [String : Date]()
    }

    // PUBLIC INTERFACE

    // by default, the cache is valid for 3 minutes (180 seconds)
    func updateSales(_ salesCount : Int, timeRangeOption: String, cacheTimeToLive: TimeInterval = 180) {
        cachedSales?[timeRangeOption] = salesCount
        cachedSalesExpirationDate?[timeRangeOption] = Date(timeIntervalSinceNow: cacheTimeToLive)
    }
    func updateRevenue(_ revenue : String, timeRangeOption: String, cacheTimeToLive: TimeInterval = 180) {
        cachedRevenue?[timeRangeOption] = revenue
        cachedRevenueExpirationDate?[timeRangeOption] = Date(timeIntervalSinceNow: cacheTimeToLive)
    }
    func updateRevenueInCents(_ revenueInCents : Int, timeRangeOption: String, cacheTimeToLive: TimeInterval = 180) {
        cachedRevenueInCents?[timeRangeOption] = revenueInCents
        cachedRevenueInCentsExpirationDate?[timeRangeOption] = Date(timeIntervalSinceNow: cacheTimeToLive)
    }
    func updateCustomers(_ customersInfo : [[String : String]], timeRangeOption: String, cacheTimeToLive : TimeInterval = 180) {
        cachedCustomers?[timeRangeOption] = customersInfo
        cachedCustomersExpirationDate?[timeRangeOption] = Date(timeIntervalSinceNow: cacheTimeToLive)
    }

    // only returns the requested data if it's still valid, otherwise returns nil
    func getCachedData(_ analyticsDataType: AnalyticsDataType, timeRangeOption: String) -> AnyObject? {
        if checkDataValidity(analyticsDataType, timeRangeOption: timeRangeOption) {
            switch analyticsDataType {
            case .sales:
                return cachedSales?[timeRangeOption] as AnyObject
            case .revenue:
                return cachedRevenue?[timeRangeOption] as AnyObject
            case .revenueInCents:
                return cachedRevenueInCents?[timeRangeOption] as AnyObject
            case .customers:
                return cachedCustomers?[timeRangeOption] as AnyObject
            }
        }
        return nil
    }

    // This should be called whenever the user is logged out to prevent the Watch app from accessing unauthorized information
    func invalidateCache(_ timeRangeOption : String? = nil) {
        var timesToClear = [String]()
        if let timeRange = timeRangeOption {
            timesToClear.append(timeRange)

            for element in timesToClear {
                cachedSales?.removeValue(forKey: element)
                cachedRevenue?.removeValue(forKey: element)
                cachedCustomers?.removeValue(forKey: element)
                cachedSalesExpirationDate?.removeValue(forKey: element)
                cachedRevenueExpirationDate?.removeValue(forKey: element)
                cachedCustomersExpirationDate?.removeValue(forKey: element)
            }

        } else {
            cachedSales?.removeAll(keepingCapacity: false)
            cachedRevenue?.removeAll(keepingCapacity: false)
            cachedCustomers?.removeAll(keepingCapacity: false)
            cachedSalesExpirationDate?.removeAll(keepingCapacity: false)
            cachedRevenueExpirationDate?.removeAll(keepingCapacity: false)
            cachedCustomersExpirationDate?.removeAll(keepingCapacity: false)
        }
    }

    fileprivate func checkDataValidity(_ analyticsDataType: AnalyticsDataType, timeRangeOption: String) -> Bool {
        let now = Date()
        var then : Date?

        switch analyticsDataType {
        case AnalyticsDataType.sales:
            then = cachedSalesExpirationDate?[timeRangeOption]

        case AnalyticsDataType.revenue:
            then = cachedRevenueExpirationDate?[timeRangeOption]

        case AnalyticsDataType.revenueInCents:
            then = cachedRevenueInCentsExpirationDate?[timeRangeOption]

        case AnalyticsDataType.customers:
            then = cachedCustomersExpirationDate?[timeRangeOption]
        }

        if then?.compare(now) == ComparisonResult.orderedDescending {
            // expiration date hasn't happened yet. data is valid
            return true
        }
        return false
    }
}
