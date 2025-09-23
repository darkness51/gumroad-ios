//
//  SwiftUIExtensions.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/13/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

extension Font {
    static let bannerTitleFont = Font.custom("Mabry Pro", size: 16)
    static let saleDrawerHeaderFont = Font.custom("Mabry Pro", size: 14)
    static let saleDrawerPropertyNameFont = Font.custom("Mabry Pro Bold", size: 12)
    static let saleDrawerPropertyValueFont = Font.custom("Mabry Pro", size: 12)
    static let settingsHeaderFont = Font.custom("Mabry Pro", size: 20)
    static let settingsTextFont = Font.custom("Mabry Pro", size: 14)
    static let settingsButtonFont = Font.custom("Mabry Pro", size: 16)
    static let discoverCardTitleFont = Font.custom("Mabry Pro", size: 20)
    static let discoverCardButtonFont = Font.custom("Mabry Pro", size: 16)
    static let discoverCardNameFont = Font.custom("Mabry Pro", size: 14)
    static let discoverCardDetailFont = Font.custom("Mabry Pro", size: 12)
    static let discoverProductTitleFont = Font.custom("Mabry Pro", size: 24)
    static let discoverProductDetailFont = Font.custom("Mabry Pro", size: 16)
    static let discoverProductSectionTitleFont = Font.custom("Mabry Pro", size: 20)
    static let discoverProductSectionDetailFont = Font.custom("Mabry Pro", size: 14)
    static let searchBarFont = Font.custom("Mabry Pro", size: 16)
    static let pillButtonFont = Font.custom("Mabry Pro", size: 14)
    static let drawerTitleFont = Font.custom("Mabry Pro Bold", size: 16)
    static let drawerSubtitleFont = Font.custom("Mabry Pro", size: 16)
    static let drawerCloseFont = Font.custom("Mabry Pro", size: 14)
}

struct WebView: UIViewRepresentable {
    let webView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No update logic needed
    }
    
    func loadURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func executeJavaScript(_ script: String, completion: @escaping (Any?, Error?) -> Void) {
        webView.evaluateJavaScript(script) { result, error in
            completion(result, error)
        }
    }
}

struct HTMLView: UIViewRepresentable {
    let htmlContent: String
    var baseURL: URL? = nil
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLView
        
        init(_ parent: HTMLView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if webView.scrollView.contentSize.height > 8 { // empty html causing height to be set to 8 when it's not fully loaded yet
                self.parent.height = webView.scrollView.contentSize.height
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // webView.scrollView.contentSize intermittently does not update right away, so adding this delay to ensure it is ready
                    self.parent.height = webView.scrollView.contentSize.height
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if let url = navigationAction.request.url,
               !["//cdn.iframe.ly", "https://www.youtube.com/embed/", "https://platform.twitter.com/"].contains(where: url.absoluteString.contains),
               await UIApplication.shared.open(url) {
                return .cancel
            } else {
                return .allow
            }
        }
    }
}

struct OEmbedVideoView: UIViewRepresentable {
    var urlString: String
    
    func makeUIView(context: Context) -> WKWebView  {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        uiView.scrollView.isScrollEnabled = false
        uiView.load(.init(url: url))
    }
}


struct RatingsProgressViewStyle: ProgressViewStyle {
    var myColor: Color

    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .accentColor(myColor)
            .frame(height: 20.0)
            .scaleEffect(x: 1, y: 5, anchor: .center)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(UIColor.label), lineWidth: 1)
            )
    }
}

struct SpinnerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let spinnerImageView = UIImageView(image: UIImage(named: "spinner"))
        spinnerImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(spinnerImageView)
        
        NSLayoutConstraint.activate([
            spinnerImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinnerImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinnerImageView.widthAnchor.constraint(equalToConstant: 75),
            spinnerImageView.heightAnchor.constraint(equalToConstant: 75)
        ])
        
        let spinnerRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        spinnerRotateAnimation.fromValue = 0.0
        spinnerRotateAnimation.toValue = CGFloat(.pi * 2.0)
        spinnerRotateAnimation.duration = 1
        spinnerRotateAnimation.repeatCount = .greatestFiniteMagnitude
        spinnerRotateAnimation.isRemovedOnCompletion = false
        spinnerImageView.layer.add(spinnerRotateAnimation, forKey: nil)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update logic needed
    }
}
