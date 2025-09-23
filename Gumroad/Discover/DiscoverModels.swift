//
//  DiscoverModels.swift
//  Gumroad
//
//  Created by Nathan Chan on 5/16/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import Foundation
import SwiftUI
import StoreKit

struct DiscoverProductsContainer: Codable {
    let products: [DiscoverProduct]
}

struct DiscoverProduct: Codable, Identifiable, Equatable {
    let id: String
    let permalink: String
    let name: String
    let inAppPurchaseId: String
    let thumbnailUrl: String?
    let seller: DiscoverProductSeller
    let covers: [DiscoverProductCover]?
    let ratings: DiscoverProductRating
    var displayPrice: String?
    var recommendationType: DiscoverRecommendationType?

    enum CodingKeys: String, CodingKey {
        case id, permalink, name, seller, covers, ratings
        case inAppPurchaseId = "in_app_purchase_id"
        case thumbnailUrl = "thumbnail_url"
    }
    
    mutating func prepareForDisplay(with storeProducts: [StoreKit.Product]) {
        displayPrice = storeProducts.first(where: { $0.id == inAppPurchaseId })?.displayPrice.stripCentsIfNeeded()
    }
    
    var priceInt: Int {
        guard let lastComponent = inAppPurchaseId.components(separatedBy: "_").last,
              let price = Int(lastComponent) else {
            return 0
        }
        return price
    }
    
    static func == (lhs: DiscoverProduct, rhs: DiscoverProduct) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DiscoverProductSeller: Codable {
    let id: String
    let name: String
    let profileUrl: String
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case profileUrl = "profile_url"
        case avatarUrl = "avatar_url"
    }
}

struct DiscoverProductCover: Codable {
    let url: String
    let width: Int
    let height: Int
    let type: String
}

struct DiscoverProductRating: Codable {
    let average: Double
    let count: Int
    let percentages: [Int]?
}

struct DiscoverProductDetailContainer: Codable {
    let product: DiscoverProductDetail
    var purchase: DiscoverPurchase?
}

struct DiscoverProductDetail: Codable, Identifiable {
    let id: String
    let permalink: String
    let name: String
    let seller: DiscoverProductSeller
    let collaboratingUser: DiscoverProductSeller?
    let covers: [DiscoverProductCover]
    let mainCoverId: String?
    let thumbnailUrl: String?
    let quantityRemaining: Int?
    let longUrl: String
    let isSalesLimited: Bool
    let ratings: DiscoverProductRating
    let customButtonTextOption: String?
    let descriptionHtml: String?
    let isComplianceBlocked: Bool
    let isPublished: Bool
    let isStreamOnly: Bool
    let salesCount: Int?
    let summary: String?
    let attributes: [DiscoverProductAttribute]
    let purchaseType: String
    let inAppPurchaseId: String

    enum CodingKeys: String, CodingKey {
        case id, permalink, name, seller, covers, ratings, summary, attributes
        case collaboratingUser = "collaborating_user"
        case mainCoverId = "main_cover_id"
        case thumbnailUrl = "thumbnail_url"
        case quantityRemaining = "quantity_remaining"
        case longUrl = "long_url"
        case isSalesLimited = "is_sales_limited"
        case customButtonTextOption = "custom_button_text_option"
        case descriptionHtml = "description_html"
        case isComplianceBlocked = "is_compliance_blocked"
        case isPublished = "is_published"
        case isStreamOnly = "is_stream_only"
        case salesCount = "sales_count"
        case purchaseType = "purchase_type"
        case inAppPurchaseId = "in_app_purchase_id"
    }
}

struct DiscoverProductAttribute: Codable {
    let name: String
    let value: String
}

struct DiscoverSellerDetailContainer: Codable {
    let seller: DiscoverSellerDetail
}

struct DiscoverSellerDetail: Codable, Identifiable {
    let id: String
    let name: String
    let bio: String?
    let subdomain: String
    let profileUrl: String
    let avatarUrl: String
    let twitterHandle: String?
    let products: [DiscoverProduct]

    enum CodingKeys: String, CodingKey {
        case name, bio, subdomain, products
        case id = "external_id"
        case profileUrl = "profile_url"
        case avatarUrl = "avatar_url"
        case twitterHandle = "twitter_handle"
    }
}

struct DiscoverPurchase: Codable {
    let id: String
    let urlRedirectToken: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case urlRedirectToken = "redirect_token"
    }
}

enum DiscoverRecommendationType: String, Codable {
    case productsForYou = "products_for_you"
    case staffPicks = "staff_picks"
    case search = "search"
    case moreLikeThis = "more_like_this"
    case library = "library"
}

struct DiscoverCategoriesContainer: Codable {
    let categories: [DiscoverCategory]
    
    enum CodingKeys: String, CodingKey {
        case categories = "taxonomies_for_nav"
    }
}

struct DiscoverCategory: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let slug: String
    let parentId: String?

    enum CodingKeys: String, CodingKey {
        case label, slug
        case id = "key"
        case parentId = "parent_key"
    }
    
    static func == (lhs: DiscoverCategory, rhs: DiscoverCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DiscoverSearchContainer: Codable {
    let products: [DiscoverProduct]
    let tags: [DiscoverTag]
    let filetypes: [DiscoverFileType]
}

struct DiscoverTag: Codable {
    let key: String
}

struct DiscoverFileType: Codable {
    let key: String
}
