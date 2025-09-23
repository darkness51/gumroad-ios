//
//  SaleInfo.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/14/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import Foundation

struct Sale: Codable {
    var purchaseId: String?
    var productName: String?
    var email: String?
    var fullName: String?
    var shippingAddress: [String: String]?
    var quantity: Int?
    var sku: String?
    var orderNumber: Int?
    var isShipped: Bool?
    var trackingURL: String?
    var currencySymbol: String?
    var amountRefundableInCurrency: String?
    var refundFeeNoticeShown: Bool?
    var productRating: Int?
    var isRefunded: Bool?
    var isPartiallyRefunded: Bool?
    var ppp: [String: String]?
    var offerCode: [String: String]?
    var affiliate: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case purchaseId = "purchase_id"
        case productName = "name"
        case email = "purchase_email"
        case fullName = "full_name"
        case shippingAddress = "shipping_address"
        case quantity = "quantity"
        case sku = "sku_id"
        case orderNumber = "order_id"
        case isShipped = "shipped"
        case trackingURL = "tracking_url"
        case currencySymbol = "currency_symbol"
        case amountRefundableInCurrency = "amount_refundable_in_currency"
        case refundFeeNoticeShown = "refund_fee_notice_shown"
        case productRating = "product_rating"
        case isRefunded = "refunded"
        case isPartiallyRefunded = "partially_refunded"
        case ppp = "ppp"
        case offerCode = "offer_code"
        case affiliate = "affiliate"
    }
}
