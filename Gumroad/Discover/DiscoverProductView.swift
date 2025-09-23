//
//  DiscoverProductView.swift
//  Gumroad
//
//  Created by Nathan Chan on 4/23/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI
import StoreKit
import AVKit

struct DiscoverProductView: View {
    @SwiftUI.Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var onBackClick: (() -> Void)?
    var onSellerClick: ((DiscoverProductSeller, DiscoverRecommendationType?) -> Void)?
    var onProductClick: ((DiscoverProduct) -> Void)?
    var product: DiscoverProduct
    
    @State var productDetail: DiscoverProductDetailContainer? = nil
    @State private var webViewHeight: CGFloat = .zero
    @State var storeProduct: StoreKit.Product? = nil
    @StateObject private var store = Store()
    @State private var isShowingError = false
    @State private var isLoadingIAP = false
    @State private var errorTitle = ""
    @State private var isPurchaseButtonDisabled = false
    @State private var relatedProducts: [DiscoverProduct] = []
    
    @State private var webView = WebView()
    
    func executeJavaScript(_ script: String) {
        webView.executeJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript execution error: \(error.localizedDescription)")
            } else {
                print("JavaScript execution result: \(String(describing: result))")
            }
        }
    }
    
    var body: some View {
        ZStack {
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
                
                let displayPrice = storeProduct?.displayPrice.stripCentsIfNeeded() ?? product.displayPrice
                if let productDetail = productDetail {
                    ScrollView {
                        VStack(spacing: 0) {
                            switch productDetail.product.covers.count {
                            case 0:
                                Image("product-placeholder-large")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                    .clipped()
                            default:
                                ImageCarouselView(numberOfImages: productDetail.product.covers.count) {
                                    ForEach(0..<productDetail.product.covers.count, id: \.self) { i in
                                        switch productDetail.product.covers[i].type {
                                        case "video":
                                            if let videoUrl = URL(string: productDetail.product.covers[i].url) {
                                                VideoPlayer(player: AVPlayer(url: videoUrl))
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: UIScreen.main.bounds.width)
                                                    .clipped()
                                            } else {
                                                Image("product-placeholder-large")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                                    .clipped()
                                            }
                                        case "oembed":
                                            OEmbedVideoView(urlString: productDetail.product.covers[i].url)
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: UIScreen.main.bounds.width)
                                                .clipped()
                                        case "image":
                                            AsyncImage(url: URL(string: productDetail.product.covers[i].url)) { image in
                                                image
                                                    .resizable()
                                            } placeholder: {
                                                VStack {
                                                    Spacer()
                                                    ProgressView()
                                                    Spacer()
                                                }
                                            }
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: UIScreen.main.bounds.width)
                                            .clipped()
                                        default:
                                            Image("product-placeholder-large")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                                .clipped()
                                        }
                                    }
                                }
                                .frame(height: UIScreen.main.bounds.width * CGFloat(productDetail.product.covers.first!.height) / CGFloat(productDetail.product.covers.first!.width), alignment: .center)
                                .clipped()
                            }
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                            
                            HStack {
                                Text(product.name)
                                    .lineSpacing(4)
                                Spacer()
                            }
                            .padding(16)
                            .font(Font.discoverProductTitleFont)
                            .foregroundColor(Color(UIColor.label))
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                            
                            HStack(spacing: 0) {
                                if let displayPrice = displayPrice {
                                    HStack(spacing: 0) {
                                        Text(displayPrice)
                                            .padding(.vertical, 8)
                                            .padding(.leading, 10)
                                            .padding(.trailing, 8)
                                            .foregroundColor(Color.black)
                                            .background(
                                                Image("price-tag-left\(displayPrice.count > 2 ? "-long" : "")")
                                                    .resizable()
                                                    .frame(height: 40)
                                            )
                                        Image("price-tag-right")
                                            .resizable()
                                            .frame(width: 20, height: 40)
                                    }
                                    .padding(16)
                                    
                                    Rectangle()
                                        .frame(width: 1)
                                        .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                                }
                                
                                VStack {
                                    HStack(spacing: 8) {
                                        AsyncImage(url: URL(string: product.seller.avatarUrl)) { image in
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
                                        Text(product.seller.name)
                                            .underline()
                                        Spacer()
                                    }
                                    .onTapGesture {
                                        onSellerClick?(product.seller, product.recommendationType)
                                    }
                                    
                                    if let collaboratingUser = productDetail.product.collaboratingUser {
                                        HStack(spacing: 8) {
                                            Text("with")
                                            AsyncImage(url: URL(string: collaboratingUser.avatarUrl)) { image in
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
                                            Text(collaboratingUser.name)
                                                .underline()
                                            Spacer()
                                        }
                                        .onTapGesture {
                                            onSellerClick?(collaboratingUser, product.recommendationType)
                                        }
                                    }
                                }
                                .padding(16)
                                
                                Spacer()
                            }
                            .font(Font.discoverProductDetailFont)
                            .foregroundColor(Color(UIColor.label))
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                            
                            HStack(spacing: 4) {
                                if product.ratings.count > 0 {
                                    HStack(spacing: 0) {
                                        ForEach(1...5, id: \.self) { i in
                                            let starImageName = (product.ratings.average > Double(i) - 0.5) ? "star-fill" :
                                            (product.ratings.average > Double(i) - 1) ? "star-half" : "star"
                                            Image(starImageName)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                }
                                Text("\(product.ratings.count) rating\(product.ratings.count == 1 ? "" : "s")")
                                    .font(Font.discoverProductDetailFont)
                                    .foregroundColor(Color(UIColor.label))
                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                            
                            if let html = productDetail.product.descriptionHtml {
                                HTMLView(htmlContent: html, height: $webViewHeight)
                                    .frame(height: webViewHeight)
                                    .padding(16)
                            }
                            
                            if let salesCount = productDetail.product.salesCount {
                                SaleInfoNotificationView("\(salesCount.withCommas()) sales")
                                    .padding(16)
                            }
                            
                            let summary = productDetail.product.summary
                            let attributes = productDetail.product.attributes
                            if summary != nil || !attributes.isEmpty {
                                SaleInfoSection {
                                    if let summary = summary {
                                        SaleInfoHeader(title: summary)
                                    }
                                    ForEach(attributes, id: \.name) { attribute in
                                        if attribute.value.isEmpty {
                                            SaleInfoPropertyText(attribute.name, bolded: true)
                                        } else {
                                            SaleInfoPropertyNameValue(name: attribute.name, value: attribute.value)
                                        }
                                    }
                                }
                                .padding(.bottom, 16)
                            }
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                            
                            if let percentages = productDetail.product.ratings.percentages,
                               percentages.count > 0 {
                                HStack {
                                    Text("Ratings")
                                        .font(Font.discoverProductSectionTitleFont)
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Image("star-fill")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                        Text("\(String(format: "%.1f", productDetail.product.ratings.average)) (\("\(product.ratings.count) rating\(product.ratings.count == 1 ? "" : "s")"))")
                                            .font(Font.discoverProductDetailFont)
                                    }
                                }
                                .padding(16)
                                .foregroundColor(Color(UIColor.label))
                                
                                VStack(spacing: 12) {
                                    Grid(alignment: .leading) {
                                        ForEach(0..<5, id: \.self) { index in
                                            GridRow {
                                                let percentage = percentages[4 - index]
                                                Text("\(5 - index) star\(index == 4 ? "" : "s")")
                                                ProgressView(value: Double(percentage) / 100)
                                                    .padding(.horizontal, 8)
                                                    .progressViewStyle(RatingsProgressViewStyle(myColor: Color(UIColor.gumroadPink)))
                                                Text("\(percentage)%")
                                            }
                                            .font(Font.discoverProductSectionDetailFont)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                .foregroundColor(Color(UIColor.label))
                            }
                            
                            if relatedProducts.count > 0 {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                                    
                                    HStack {
                                        Text("More like this")
                                            .font(Font.discoverProductSectionTitleFont)
                                            .foregroundColor(Color(UIColor.label))
                                        Spacer()
                                    }
                                    .padding(16)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            let productWidth = horizontalSizeClass == .compact
                                                ? (UIScreen.main.bounds.width - (3 * 16)) / 1.5
                                                : (UIScreen.main.bounds.width - (5 * 16)) / 3.5
                                            
                                            ForEach(relatedProducts) { product in
                                                ProductItem(product: product, productWidth: productWidth, onProductClick: onProductClick)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            Spacer()
                        }
                    }
                } else {
                    Spacer()
                }
                
                if let productDetail = productDetail,
                   let displayPrice = displayPrice {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                    
                    // Pixel tracking
                    webView
                        .frame(height: 0)
                        .onAppear {
                            webView.loadURL("\(Environment.rootURLString)/links/\(product.permalink)/in_app")
                        }
                    
                    HStack {
                        if let purchase = productDetail.purchase {
                            Text("You've purchased this product")
                        } else {
                            HStack(spacing: 0) {
                                Text(displayPrice)
                                    .padding(.vertical, 8)
                                    .padding(.leading, 10)
                                    .padding(.trailing, 8)
                                    .foregroundColor(Color.black)
                                    .background(
                                        Image("price-tag-left\(displayPrice.count > 2 ? "-long" : "")")
                                            .resizable()
                                            .frame(height: 40)
                                    )
                                Image("price-tag-right")
                                    .resizable()
                                    .frame(width: 20, height: 40)
                            }
                        }
                        Spacer(minLength: 20)
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if let purchase = productDetail.purchase {
                                logEvent("discover_view_content_click", params: ["permalink": product.permalink])
                                if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate,
                                   let urlRedirectToken = productDetail.purchase?.urlRedirectToken {
                                    logEvent("discover_deeplink_from_view_content", params: ["permalink": product.permalink])
                                    CoreDataManager.shared.setUrlRedirectToken(urlRedirectToken)
                                    appDelegate.openProduct(with: urlRedirectToken)
                                }
                            } else {
                                Task {
                                    isPurchaseButtonDisabled = true
                                    isLoadingIAP = true
                                    logEvent("discover_purchase_click", params: ["permalink": product.permalink])
                                    executeJavaScript("window.tracking.ctaClick();")
                                    await purchase()
                                }
                            }
                        }) {
                            Text(productDetail.purchase == nil ? "I want this!" : "View content")
                                .foregroundColor(Color(UIColor(named: "GumroadBackgroundColor")!))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(UIColor(named: "GumroadLabelColor")!))
                                )
                        }
                        .disabled(isPurchaseButtonDisabled)
                    }
                    .padding(16)
                    .font(Font.discoverProductDetailFont)
                    .background(Color(UIColor(named: "GumroadBackgroundColor")!))
                }
            }
            
            if isLoadingIAP {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                SpinnerView()
            }
        }
        .background(Color(UIColor(named: "GumroadBackgroundColor")!))
        .onAppear() {
            logEvent("discover_product_view", params: ["permalink": product.permalink])
            
            GRDNetworkRequest.shared.fetchProductDetails(permalink: product.permalink,
            successBlock: { productDetail in
                print(productDetail)
                self.productDetail = productDetail
                Task {
                    let storeProducts = await store.fetchStoreKitProducts(for: [self.product])
                    storeProduct = storeProducts.first
                }
                
                GRDNetworkRequest.shared.relatedProducts(permalink: product.permalink,
                successBlock: { relatedProducts in
                    var products = relatedProducts
                    Task {
                        let relatedStoreProducts = await store.fetchStoreKitProducts(for: products)
                        products.indices.forEach({ index in
                            products[index].prepareForDisplay(with: relatedStoreProducts)
                            products[index].recommendationType = .moreLikeThis
                        })
                        self.relatedProducts = products
                    }
                }, failureBlock: { error in
                    logEvent("discover_related_products_error", params: ["error": error.localizedDescription])
                })
                
                GRDNetworkRequest.shared.productPageView(
                    permalink: productDetail.product.permalink,
                    successBlock: nil,
                    failureBlock: nil
                )
            }, failureBlock: { error in
                logEvent("discover_product_view_error", params: ["error": error.localizedDescription])
            })
        }
        .alert(isPresented: $isShowingError, content: {
            Alert(title: Text(errorTitle), message: nil, dismissButton: .cancel(Text("Ok")))
        })
    }
    
    func purchase() async {
        let result = try? await storeProduct?.purchase()

        switch result {
        case let .success(.verified(transaction)):
            let transactionId = String(transaction.id)
            let pendingOrder = DiscoverPendingOrder(
                permalink: product.permalink,
                recommendationType: product.recommendationType,
                purchaseType: productDetail?.product.purchaseType,
                retryCount: 0
            )
            if var discoverPendingOrderDictionary = UserDefaults.standard.getDiscoverPendingOrderDictionary() {
                discoverPendingOrderDictionary[transactionId] = pendingOrder
                UserDefaults.standard.setDiscoverPendingOrderDictionary(discoverPendingOrderDictionary)
            } else {
                UserDefaults.standard.setDiscoverPendingOrderDictionary([transactionId: pendingOrder])
            }
            
            print(transaction)
            GRDNetworkRequest.shared.orderProduct(
                transactionId: transactionId,
                permalink: pendingOrder.permalink,
                recommendationType: pendingOrder.recommendationType,
                purchaseType: pendingOrder.purchaseType,
                successBlock: { (response, responseObject) -> Void in
                    if let data = responseObject as? [String: Any],
                       let purchaseData = data["purchase"] as? [String: Any],
                       let success = purchaseData["success"] as? Bool {
                        if success {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            logEvent("discover_purchase_success", params: ["transactionId": transactionId, "permalink": product.permalink])
                            if let jsonData = try? JSONSerialization.data(withJSONObject: purchaseData) {
                                executeJavaScript("window.tracking.productPurchase(\(String(data: jsonData, encoding: .utf8)!)")
                            }
                            Task {
                                await transaction.finish()
                                
                                if var discoverPendingOrderDictionary = UserDefaults.standard.getDiscoverPendingOrderDictionary() {
                                    discoverPendingOrderDictionary.removeValue(forKey: transactionId)
                                    UserDefaults.standard.setDiscoverPendingOrderDictionary(discoverPendingOrderDictionary)
                                }
                                
                                if let purchaseId = purchaseData["id"] as? String {
                                    productDetail?.purchase = DiscoverPurchase(id: purchaseId, urlRedirectToken: purchaseData["redirect_token"] as? String)
                                }
                                
                                if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate,
                                   let urlRedirectToken = productDetail?.purchase?.urlRedirectToken {
                                    logEvent("discover_deeplink_from_purchase", params: ["permalink": product.permalink])
                                    CoreDataManager.shared.setUrlRedirectToken(urlRedirectToken)
                                    appDelegate.openProduct(with: urlRedirectToken)
                                }
                            }
                        } else if let errorMessage = purchaseData["error_message"] as? String {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            logEvent("discover_purchase_failure", params: ["error_message": errorMessage])
                            errorTitle = errorMessage
                            isShowingError = true
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            logEvent("discover_purchase_failure", params: ["error_message": "Sorry, something went wrong. Try again later."])
                            errorTitle = "Sorry, something went wrong. Try again later."
                            isShowingError = true
                        }
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        logEvent("discover_purchase_failure", params: ["error_message": "Something wrong with responseObject."])
                        errorTitle = "Sorry, something went wrong. Try again later."
                        isShowingError = true
                    }
                    isPurchaseButtonDisabled = false
                    isLoadingIAP = false
                }, failureBlock: { (error) -> Void in
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    logEvent("discover_purchase_failure", params: ["error_message": error.localizedDescription])
                    errorTitle = "Sorry, something went wrong. Try again later."
                    isShowingError = true
                    isPurchaseButtonDisabled = false
                    isLoadingIAP = false
                })
        case .success(.unverified(_, _)):
            logEvent("discover_purchase_failure", params: ["error_message": "Unverified App Store transaction."])
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
            isPurchaseButtonDisabled = false
            isLoadingIAP = false
        default:
            isPurchaseButtonDisabled = false
            isLoadingIAP = false
            break
        }
    }
}
