//
//  SaleDrawerCustomViews.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/15/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import SwiftUI

struct SaleInfoSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color(UIColor(named: "GumroadBorderColor")!), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct SaleInfoSectionSeparator: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
    }
}

struct SaleInfoHeader: View {
    let title: String
    
    init(title: String) {
        self.title = title
    }

    var body: some View {
        HStack {
            Text(title)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(Font.saleDrawerHeaderFont)
            Spacer()
        }
        .padding(12)
        .background(Color(UIColor(named: "GumroadBackgroundColor")!))
    }
}

struct SaleInfoPropertyText: View {
    let text: String
    let bolded: Bool
    
    init(_ text: String, bolded: Bool = false) {
        self.text = text
        self.bolded = bolded
    }

    var body: some View {
        SaleInfoSectionSeparator()
        HStack {
            Text(verbatim: text)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(bolded ? Font.saleDrawerPropertyNameFont : Font.saleDrawerPropertyValueFont)
                .lineSpacing(3)
            Spacer()
        }
        .padding(12)
        .background(Color(UIColor(named: "GumroadBackgroundColor")!))
    }
}

struct SaleInfoPropertyNameValue: View {
    let name: String
    let value: String
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    var body: some View {
        SaleInfoSectionSeparator()
        HStack {
            Text(name)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(Font.saleDrawerPropertyNameFont)
            Spacer()
            Text(value)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                .font(Font.saleDrawerPropertyValueFont)
        }
        .padding(12)
        .background(Color(UIColor(named: "GumroadBackgroundColor")!))
    }
}

struct SaleInfoRatingView: View {
    let rating: Int
    
    init(rating: Int) {
        self.rating = rating
    }

    var body: some View {
        SaleInfoSectionSeparator()
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                Image("star\(index < rating ? "-fill" : "")")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(UIColor(named: "GumroadBackgroundColor")!))
    }
}

struct SaleInfoSuccessView: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        SaleInfoSectionSeparator()
        VStack(spacing: 0) {
            HStack {
                Image("solid-check-circle")
                    .resizable()
                    .frame(width: 18, height: 18)
                Text(text)
                    .foregroundColor(Color(UIColor.label))
                    .font(Font.saleDrawerPropertyValueFont)
                Spacer()
            }
            .padding(14)
        }
        .cornerRadius(4)
        .background(Color(UIColor(named: "GumroadGreenColor")!))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color(red: 0.14, green: 0.63, blue: 0.58), lineWidth: 1)
        )
        .padding(12)
    }
}

struct SaleInfoNotificationView: View {
    let text: String
    let urlText: String?
    let urlString: String?
    
    init(_ text: String, urlText: String? = nil, urlString: String? = nil) {
        self.text = text
        self.urlText = urlText
        self.urlString = urlString
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Image("info-circle-fill")
                    .resizable()
                    .frame(width: 18, height: 18)
                if let urlText = urlText,
                   let urlString = urlString,
                   let url = URL(string: urlString),
                   UIApplication.shared.canOpenURL(url) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(text)
                                .foregroundColor(Color(UIColor.label))
                                .font(Font.saleDrawerPropertyValueFont)
                                .lineSpacing(3)
                                .padding(.vertical, 3)
                            Spacer()
                        }
                        HStack {
                            Link(destination: url) {
                                Text(urlText)
                                    .foregroundColor(Color(UIColor.label))
                                    .font(Font.saleDrawerPropertyValueFont)
                                    .underline()
                                    .lineSpacing(3)
                                    .padding(.vertical, 3)
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                } else {
                    Text(text)
                        .foregroundColor(Color(UIColor.label))
                        .font(Font.saleDrawerPropertyValueFont)
                        .lineSpacing(3)
                        .padding(.vertical, 3)
                }
                Spacer()
            }
            .padding(12)
        }
        .cornerRadius(4)
        .background(Color(UIColor(named: "GumroadBlueColor")!))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color(red: 0.56, green: 0.66, blue: 0.93), lineWidth: 1)
        )
    }
}

struct SaleInfoButton: View {
    let text: String
    var isLoading: Bool
    let onClick: (() -> Void)
    
    init(_ text: String, isLoading: Bool = false, onClick: @escaping () -> Void) {
        self.text = text
        self.isLoading = isLoading
        self.onClick = onClick
    }
    
    var body: some View {
        Button(action: onClick) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.systemBackground)))
                        .padding(13)
                } else {
                    Text(text)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .font(Font.saleDrawerHeaderFont)
                        .padding(16)
                }
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor(named: "GumroadLabelColor")!))
            )
            .padding(12)
        }
        .disabled(isLoading)
    }
}

struct SaleRefundTextbox: View {
    let currency: String
    let placeholder: String
    @Binding var refundAmount: String
    
    init(currency: String, placeholder: String, refundAmount: Binding<String>) {
        self.currency = currency
        self.placeholder = placeholder
        self._refundAmount = refundAmount
    }
    
    var body: some View {
        SaleInfoSectionSeparator()
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color(UIColor(named: "GumroadBorderColor")!), lineWidth: 1)

            HStack {
                Circle()
                    .stroke(lineWidth: 1)
                    .frame(width: 33, height: 36)
                    .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                    .overlay(
                        Text(currency)
                            .font(Font.saleDrawerHeaderFont)
                            .foregroundColor(Color(UIColor(named: "GumroadLabelColor")!))
                    )
                
                TextField(placeholder, text: $refundAmount)
                    .keyboardType(.decimalPad)
                    .font(Font.bannerTitleFont)
                    .frame(height: 36)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }
}
