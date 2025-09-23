//
//  ProductHeaderView.swift
//  Gumroad
//
//  Created by Nathan Chan on 9/8/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI

struct ProductHeaderView: View {
    var product: Product
    var showTabButtons: Bool
    var onTabChange: (ProductHeaderTab) -> Void
    
    @State var selectedProductHeaderTab: ProductHeaderTab = .content
    @State var hasSeenLibraryMoreLikeThis = UserDefaults.standard.bool(forKey: hasSeenLibraryMoreLikeThisUserDefaultsKey)
    
    enum ProductHeaderTab {
        case content, moreLikeThis
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(product.name ?? "")
                        .font(Font.discoverProductTitleFont)
                        .foregroundColor(Color(UIColor.label))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    HStack(spacing: 8) {
                        if let profile_url = product.creator_profile_picture_url,
                           let imageURL = URL(string: profile_url) {
                            AsyncImage(url: imageURL) { image in
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
                        } else {
                            Image("empty-profile")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipped()
                        }
                        if let urlString = product.creator_profile_url,
                           let url = URL(string: urlString),
                           UIApplication.shared.canOpenURL(url) {
                            Link(destination: url) {
                                Text(product.creator_name ?? "")
                                    .font(Font.discoverProductDetailFont)
                                    .foregroundColor(Color(UIColor.label))
                                    .underline()
                            }
                        } else {
                            Text(product.creator_name ?? "")
                                .font(Font.discoverProductDetailFont)
                                .foregroundColor(Color(UIColor.label))
                        }
                        Spacer()
                    }
                }
                
                if showTabButtons {
                    HStack(spacing: 0) {
                        PillButton(title: "Content", isSelected: selectedProductHeaderTab == .content) {
                            selectedProductHeaderTab = .content
                            onTabChange(.content)
                        }
                        PillButton(title: "More like this", isSelected: selectedProductHeaderTab == .moreLikeThis) {
                            selectedProductHeaderTab = .moreLikeThis
                            onTabChange(.moreLikeThis)
                            UserDefaults.standard.set(true, forKey: hasSeenLibraryMoreLikeThisUserDefaultsKey)
                            hasSeenLibraryMoreLikeThis = true
                        }
                        .overlay(
                            GeometryReader { geometry in
                                if !hasSeenLibraryMoreLikeThis {
                                    Image("new")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .position(x: geometry.size.width + 5, y: 10)
                                }
                            }
                        )
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
        }
        .background(Color(UIColor(named: "GumroadTopViewColor")!))
        .frame(maxWidth: .infinity)
    }
}
