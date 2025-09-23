//
//  DiscoverSellerView.swift
//  Gumroad
//
//  Created by Nathan Chan on 6/14/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI
import StoreKit

struct DiscoverSellerView: View {
    var onBackClick: (() -> Void)?
    var onProductClick: ((DiscoverProduct) -> Void)?
    var seller: DiscoverProductSeller
    var recommendationType: DiscoverRecommendationType?
    @State var sellerDetail: DiscoverSellerDetail?
    
    @State private var isFirstLoad = true
    @State private var isLoading = false
    @State var productsToDisplay: [DiscoverProduct] = []
    @State var storeProducts: [StoreKit.Product] = []
    @StateObject private var store = Store()
    
    @State private var skeletonOpacity: Double = 1.0
    
    init(seller: DiscoverProductSeller, recommendationType: DiscoverRecommendationType?) {
        self.seller = seller
        self.recommendationType = recommendationType
        _skeletonOpacity = State(initialValue: UITraitCollection.current.userInterfaceStyle == .dark ? 0.2 : 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    onBackClick?()
                }) {
                    Image("caret-left-white")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 16)
                }
                Spacer()
            }
            .frame(height: 44)
            .background(Color.black)
            
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: seller.avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Spacer()
                }
                .frame(width: 24, height: 24)
                .clipped()
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .inset(by: 0.5)
                    .stroke(.black, lineWidth: 1)
                )
                Text(seller.name)
                Spacer()
            }
            .padding(16)
            .font(Font.discoverProductDetailFont)
            .foregroundColor(Color(UIColor.label))
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if let bio = sellerDetail?.bio.nilIfEmpty {
                        HStack {
                            Text(bio)
                                .lineSpacing(4)
                            Spacer()
                        }
                        .padding(16)
                        .font(Font.discoverProductTitleFont)
                        .foregroundColor(Color(UIColor.label))
                        
                        Rectangle()
                            .padding(.vertical, 0)
                            .frame(height: 1)
                            .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                    }
                    
                    if isLoading {
                        Image("skeleton-discover")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width)
                            .clipped()
                            .opacity(skeletonOpacity)
                            .onAppear {
                                skeletonOpacity = UITraitCollection.current.userInterfaceStyle == .dark ? 0.2 : 1.0 // required to reset animation
                                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                    skeletonOpacity = UITraitCollection.current.userInterfaceStyle == .dark ? 0.05 : 0.5
                                }
                            }
                    } else {
                        DiscoverProductGrid(products: productsToDisplay, onProductClick: onProductClick)
                    }
                }
            }
        }
        .background(Color(UIColor(named: "GumroadTopViewColor")!))
        .onAppear {
            if isFirstLoad {
                isFirstLoad = false
                isLoading = true
                
                logEvent("discover_seller_view", params: ["seller": seller.id])
                
                GRDNetworkRequest.shared.fetchSellerDetails(id: seller.id, successBlock: { sellerDetail in
                    self.sellerDetail = sellerDetail
                    var products = sellerDetail.products
                    Task {
                        storeProducts = await store.fetchStoreKitProducts(for: products)
                        products.indices.forEach({ index in
                            products[index].prepareForDisplay(with: storeProducts)
                            products[index].recommendationType = recommendationType
                        })
                        self.productsToDisplay = products
                        isLoading = false
                    }
                }, failureBlock: { _ in
                    self.productsToDisplay = []
                    isLoading = false
                })
            }
        }
    }
}
