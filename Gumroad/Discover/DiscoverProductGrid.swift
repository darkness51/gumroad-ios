//
//  DiscoverProductGrid.swift
//  Gumroad
//
//  Created by Nathan Chan on 6/17/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI

struct DiscoverProductGrid: View {
    @SwiftUI.Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var products: [DiscoverProduct]
    var onProductClick: ((DiscoverProduct) -> Void)?
    
    init(products: [DiscoverProduct], onProductClick: ((DiscoverProduct) -> Void)? = nil) {
        self.products = products
        self.onProductClick = onProductClick
    }
    
    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: horizontalSizeClass == .compact ? 2 : 4
        )
        let productWidth = horizontalSizeClass == .compact
            ? (UIScreen.main.bounds.width - (3 * 16)) / 2
            : (UIScreen.main.bounds.width - (5 * 16)) / 4
        
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(products) { product in
                ProductItem(product: product, productWidth: productWidth, onProductClick: onProductClick)
            }
        }
        .padding(16)
    }
}

struct ProductItem: View {
    @SwiftUI.Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let product: DiscoverProduct
    let productWidth: CGFloat
    let onProductClick: ((DiscoverProduct) -> Void)?
    
    var body: some View {
        if let displayPrice = product.displayPrice {
            VStack(spacing: 0) {
                if let thumbnailUrl = product.thumbnailUrl ?? product.covers?.first?.url {
                    CachedAsyncImage(url: URL(string: thumbnailUrl)) { image in
                        image
                            .resizable()
                    } placeholder: {
                        Spacer()
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: productWidth, height: productWidth)
                    .clipped()
                } else {
                    Image("product-placeholder-large")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: productWidth, height: productWidth)
                        .clipped()
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                
                VStack {
                    HStack {
                        Text(product.name)
                            .font(Font.discoverCardNameFont)
                            .lineSpacing(4)
                        Spacer()
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        CachedAsyncImage(url: URL(string: product.seller.avatarUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Spacer()
                        }
                        .frame(width: 16, height: 16)
                        .clipped()
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .inset(by: 0.5)
                            .stroke(.black, lineWidth: 1)
                        )
                        
                        Text(product.seller.name)
                            .font(Font.discoverCardDetailFont)
                        Spacer()
                    }
                }
                .foregroundColor(Color(UIColor.label))
                .padding(8)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                HStack(spacing: 0) {
                    HStack(spacing: 2) {
                        Image("star-fill")
                            .resizable()
                            .frame(width: 14, height: 14)
                        if product.ratings.count > 0 {
                            Text("\(String(format: "%.1f", product.ratings.average)) (\(product.ratings.count.truncatedNumber()))")
                        } else {
                            Text("No ratings")
                        }
                    }
                    .padding(8)
                    .foregroundColor(Color(UIColor.label))
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: productWidth / 2, alignment: .leading)
                    
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                    
                    HStack(spacing: 0) {
                        Text(displayPrice)
                            .padding(4)
                            .foregroundColor(Color.black)
                            .background(
                                Image("price-tag-left\(displayPrice.count > 2 ? "-long" : "")")
                                    .resizable()
                                    .frame(height: 22)
                            )
                        Image("price-tag-right")
                            .resizable()
                            .frame(width: 10, height: 22)
                        Spacer()
                    }
                    .padding(8)
                }
                .font(Font.discoverCardDetailFont)
                .frame(height: 38)
            }
            .frame(width: productWidth)
            .background(Color(UIColor(named: "GumroadBackgroundColor")!))
            .cornerRadius(4)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .inset(by: 0.5)
                    .stroke(Color(UIColor(named: "GumroadBorderColor")!), lineWidth: 1)
            )
            .onTapGesture {
                onProductClick?(product)
            }
        }
    }
}
