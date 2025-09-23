//
//  SaleDrawerView.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/13/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import SwiftUI

struct SaleDrawerView: View {
    
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    
    var saleId: String
    var inAppPurchasePlatform: String?
    @State var isLoading = true
    @State var fetchSaleError = false
    @State var sale = Sale()
    @State var refundAmountInput = ""
    @State var showRefundAlert = false
    @State var refundSaleSuccess = false
    @State var refundSaleMessage = ""
    @State var refundSaleInProgress = false
    
    var body: some View {
        VStack {
            VStack {
                Spacer()
                ZStack {
                    HStack {
                        Button(action: closeClicked) {
                            Image("cancel-white")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        Spacer()
                    }
                    Text(fetchSaleError ? "Network error" : sale.productName ?? "")
                        .font(Font.bannerTitleFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 40)
                }
            }
            .padding(16)
            .frame(height: 80)
            .background(Color.black)
            
            ZStack {
                if isLoading {
                    VStack {
                        ProgressView()
                            .padding(20)
                        Spacer()
                    }
                } else if fetchSaleError {
                    VStack {
                        Text("Sorry, something went wrong. Try again later.")
                            .font(Font.saleDrawerHeaderFont)
                            .padding(20)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let ppp = sale.ppp,
                               let discount = ppp["discount"],
                               let country = ppp["country"] {
                                SaleInfoNotificationView("This customer received a purchasing power parity discount of \(discount) because they are located in \(country).")
                                    .padding(.horizontal, 16)
                            }
                            if let offerCode = sale.offerCode,
                               let code = offerCode["code"],
                               let discount = offerCode["displayed_amount_off"] {
                                SaleInfoNotificationView("A discount code (\(code)) was used to get \(discount) off.")
                                    .padding(.horizontal, 16)
                            }
                            if let affiliate = sale.affiliate,
                               let email = affiliate["email"],
                               let amount = affiliate["amount"] {
                                SaleInfoNotificationView("An affiliate (\(email)) helped you make this sale and received \(amount).")
                                    .padding(.horizontal, 16)
                            }
                            
                            if let email = sale.email {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Email")
                                    SaleInfoPropertyText(email, bolded: true)
                                }
                            }
                            
                            if let fullName = sale.fullName {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Full name")
                                    SaleInfoPropertyText(fullName, bolded: true)
                                }
                            }
                            
                            if let shippingAddress = sale.shippingAddress {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Shipping address")
                                    SaleInfoPropertyText("\(shippingAddress["full_name"] ?? "")\n\(shippingAddress["street_address"] ?? "")\n\(shippingAddress["city"] ?? ""), \(shippingAddress["state"] ?? "") \(shippingAddress["zip_code"] ?? "")\n\(shippingAddress["country"] ?? "")")
                                }
                            }
                            
                            if let quantity = sale.quantity {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Order information")
                                    if let sku = sale.sku {
                                        SaleInfoPropertyNameValue(name: "SKU", value: sku)
                                    }
                                    if let orderNumber = sale.orderNumber {
                                        SaleInfoPropertyNameValue(name: "Order number", value: String(orderNumber))
                                    }
                                    SaleInfoPropertyNameValue(name: "Quantity", value: String(quantity))
                                }
                            }
                            
                            if let rating = sale.productRating {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Rating")
                                    SaleInfoRatingView(rating: rating)
                                }
                            }
                            
                            if let isShipped = sale.isShipped {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Tracking information")
                                    
                                    if isShipped {
                                        if let trackingURLString = sale.trackingURL,
                                           let trackingURL = URL(string: trackingURLString),
                                           UIApplication.shared.canOpenURL(trackingURL) {
                                            SaleInfoSectionSeparator()
                                            SaleInfoButton("Track shipment") {
                                                UIApplication.shared.open(trackingURL)
                                            }
                                        } else {
                                            SaleInfoSuccessView("Shipped")
                                        }
                                    } else {
                                        SaleInfoPropertyText("Not shipped")
                                    }
                                }
                            }
                            
                            if let iapPlatform = inAppPurchasePlatform {
                                SaleInfoSection {
                                    SaleInfoHeader(title: "Refund")
                                    SaleInfoPropertyText("In-app purchases cannot be refunded directly. The buyer can request a refund from \(iapPlatform).")
                                }
                            } else if let currencySymbol = sale.currencySymbol,
                                      let amountRefundableInCurrencyString = sale.amountRefundableInCurrency {
                                let isFullRefund = refundAmountInput.isEmpty || refundAmountInput == amountRefundableInCurrencyString
                                SaleInfoSection {
                                    if refundSaleSuccess {
                                        SaleInfoNotificationView(isFullRefund ? "Refunded" : "Partially refunded")
                                            .padding(12)
                                    } else if let isRefunded = sale.isRefunded, isRefunded {
                                        SaleInfoNotificationView("Refunded")
                                            .padding(12)
                                    } else if let amountRefundableInCurrency = Double(amountRefundableInCurrencyString),
                                              amountRefundableInCurrency > 0 {
                                        SaleInfoHeader(title: "Refund")
                                        SaleRefundTextbox(currency: currencySymbol, placeholder: amountRefundableInCurrencyString, refundAmount: $refundAmountInput)
                                        if !refundSaleMessage.isEmpty {
                                            HStack {
                                                Text(refundSaleMessage)
                                                    .font(Font.saleDrawerPropertyValueFont)
                                                    .foregroundColor(.red)
                                                    .padding(.horizontal, 16)
                                                    .padding(.top, 12)
                                                Spacer()
                                            }
                                        }
                                        SaleInfoButton(isFullRefund ? "Refund fully" : "Issue partial refund", isLoading: refundSaleInProgress) {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showRefundAlert = true
                                        }
                                        if let refundFeeNoticeShown = sale.refundFeeNoticeShown, !refundFeeNoticeShown {
                                            SaleInfoNotificationView("Going forward, Gumroad does not return the payment processor fees when a payment is refunded.", urlText: "Learn more", urlString: "https://help.gumroad.com/article/47-how-to-refund-a-customer")
                                                .padding(.horizontal, 12)
                                                .padding(.bottom, 12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            
            Spacer()
        }
        .background(Color(UIColor(named: "GumroadBackgroundColor")!))
        .onAppear() {
            GRDNetworkRequest.shared.fetchSale(with: saleId, successBlock: { [self] (response, responseObject) -> Void in
                self.isLoading = false
                if let data = responseObject as? [String: Any],
                   let saleDict = data["purchase"] as? [String: Any] {
                    do {
                        let saleData = try JSONSerialization.data(withJSONObject: saleDict)
                        sale = try JSONDecoder().decode(Sale.self, from: saleData)
                        print(saleDict)
                        print(sale)
                    } catch {
                        print("Error decoding JSON: \(error)")
                        self.fetchSaleError = true
                    }
                } else {
                    self.fetchSaleError = true
                    return
                }
            }, failureBlock: { [self] (error) -> Void in
                self.isLoading = false
                self.fetchSaleError = true
            })
        }
        .alert(isPresented: $showRefundAlert) {
            Alert(
                title: Text("Purchase refund"),
                message: Text("Would you like to confirm this purchase refund?"),
                primaryButton: .cancel(Text("Cancel")),
                secondaryButton: .default(Text("Confirm refund")) {
                    if let purchaseId = sale.purchaseId,
                       let amountRefundableInCurrency = sale.amountRefundableInCurrency {
                        refundSaleInProgress = true
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // dismiss keyboard
                        GRDNetworkRequest.shared.refundSale(
                            purchaseId: purchaseId,
                            amount: (refundAmountInput.isEmpty ? amountRefundableInCurrency : refundAmountInput),
                            successBlock: { [self] (response, responseObject) -> Void in
                                if let data = responseObject as? [String: Any],
                                   let success = data["success"] as? Bool,
                                   let message = data["message"] as? String {
                                    refundSaleSuccess = success
                                    refundSaleMessage = message
                                    if refundSaleSuccess {
                                        logEvent("refunded_sale", params: ["purchase_id": purchaseId])
                                    }
                                } else {
                                    refundSaleSuccess = false
                                    refundSaleMessage = "Sorry, something went wrong. Try again later."
                                }
                                UINotificationFeedbackGenerator().notificationOccurred(refundSaleSuccess ? .success : .error)
                                refundSaleInProgress = false
                            }, failureBlock: { [self] (error) -> Void in
                                refundSaleSuccess = false
                                refundSaleMessage = "Sorry, something went wrong. Try again later."
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                refundSaleInProgress = false
                            })
                    }
                }
            )
        }
    }
    
    func closeClicked() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presentationMode.wrappedValue.dismiss()
    }
}
