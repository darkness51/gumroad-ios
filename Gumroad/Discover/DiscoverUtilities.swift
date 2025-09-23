//
//  DiscoverUtilities.swift
//  Gumroad
//
//  Created by Nathan Chan on 6/18/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import Foundation
import StoreKit

@MainActor final class Store: ObservableObject {
    @Published private(set) var activeTransactions: Set<StoreKit.Transaction> = []
    private var updates: Task<Void, Never>?
    
    static let supportedCurrencyCodes = ["USD", "GBP", "EUR", "JPY", "INR", "AUD", "CAD", "HKD", "SGD", "TWD", "NZD", "BRL", "ZAR", "CHF", "ILS", "PHP", "KRW", "PLN", "CZK"] // Supported Gumroad currencies https://github.com/gumroad/gumroad/blob/05f1318e62b2c9b28f1082b0bee64950cf162255/config/currencies.json
    
    init() {
        updates = Task {
            for await update in StoreKit.Transaction.unfinished { // Note: this listens for ALL unfinished transactions
                if let transaction = try? update.payloadValue {
                    let transactionId = String(transaction.id)
                    
                    if var discoverPendingOrderDictionary = UserDefaults.standard.getDiscoverPendingOrderDictionary(),
                       var pendingOrder = discoverPendingOrderDictionary[transactionId] {
                        
                        func incrementRetryCount() async {
                            pendingOrder.retryCount += 1
                            if pendingOrder.retryCount > 2 {
                                discoverPendingOrderDictionary.removeValue(forKey: transactionId)
                                UserDefaults.standard.setDiscoverPendingOrderDictionary(discoverPendingOrderDictionary)
                                // Unfinished transaction exists but order retry limit has been exceeded. There is nothing we can do, so just finish the transaction.
                                logEvent("discover_order_retry_limit_exceeded", params: ["transactionId": transactionId, "permalink": pendingOrder.permalink])
                                await transaction.finish()
                            } else {
                                discoverPendingOrderDictionary[transactionId] = pendingOrder
                                UserDefaults.standard.setDiscoverPendingOrderDictionary(discoverPendingOrderDictionary)
                                logEvent("discover_order_increment_retry", params: ["transactionId": transactionId, "permalink": pendingOrder.permalink])
                            }
                        }
                        
                        GRDNetworkRequest.shared.orderProduct(
                            transactionId: transactionId,
                            permalink: pendingOrder.permalink,
                            recommendationType: pendingOrder.recommendationType,
                            purchaseType: pendingOrder.purchaseType,
                            successBlock: { (response, responseObject) -> Void in
                                Task {
                                    if let data = responseObject as? [String: Any],
                                       let purchaseData = data["purchase"] as? [String: Any],
                                       let success = purchaseData["success"] as? Bool {
                                        if success {
                                            logEvent("discover_purchase_success_retry", params: ["transactionId": transactionId, "permalink": pendingOrder.permalink])
                                            await transaction.finish()
                                        } else {
                                            logEvent("discover_purchase_failure_retry", params: ["error_message": purchaseData["error_message"] as? String ?? "Sorry, something went wrong. Try again later."])
                                            await incrementRetryCount()
                                        }
                                    } else {
                                        logEvent("discover_purchase_failure_retry", params: ["error_message": "Something wrong with responseObject."])
                                        await incrementRetryCount()
                                    }
                                }
                            }, failureBlock: { (error) -> Void in
                                Task {
                                    logEvent("discover_purchase_failure_retry", params: ["error_message": error.localizedDescription])
                                    await incrementRetryCount()
                                }
                            })
                    } else {
                        // Unfinished transaction exists but no pending order was stored. There is nothing we can do, so just finish the transaction to prevent retries.
                        logEvent("discover_pending_order_not_found", params: ["transactionId": transactionId])
                        await transaction.finish()
                    }
                }
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    func fetchStoreKitProducts(for products: [DiscoverProduct]) async -> [StoreKit.Product] {
        let inAppPurchaseIds = products.map { $0.inAppPurchaseId }
        
        do {
            return try await StoreKit.Product.products(for: inAppPurchaseIds)
        } catch {
            print("Error loading StoreKit products.")
            return []
        }
    }
    
    static func isCurrencySupported() async -> Bool {
        do {
            let products = try await StoreKit.Product.products(for: ["com.gumroad.product_1"])
            if let currencyCode = products.first?.priceFormatStyle.currencyCode {
                return Store.supportedCurrencyCodes.contains(currencyCode)
            }
            return false
        } catch {
            print("Error loading StoreKit products.")
            return false
        }
    }
}

struct DiscoverPendingOrder: Codable {
    let permalink: String
    let recommendationType: DiscoverRecommendationType?
    let purchaseType: String?
    var retryCount: Int
}

extension UserDefaults {
    static let discoverPendingOrderDictionaryUserDefaultsKey = "discoverPendingOrderDictionary"
    
    func getDiscoverPendingOrderDictionary() -> [String: DiscoverPendingOrder]? {
        if let data = self.data(forKey: UserDefaults.discoverPendingOrderDictionaryUserDefaultsKey) {
            let decoder = JSONDecoder()
            return try? decoder.decode([String: DiscoverPendingOrder].self, from: data)
        }
        return nil
    }
    
    func setDiscoverPendingOrderDictionary(_ dictionary: [String: DiscoverPendingOrder]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(dictionary) {
            self.set(encoded, forKey: UserDefaults.discoverPendingOrderDictionaryUserDefaultsKey)
        }
    }
}
