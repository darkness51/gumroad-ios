//
//  GRDWebView.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 6/8/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import UIKit
import WebKit

class GRDWebView: WKWebView {
    
    var lastRequest : URLRequest?
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        configuration.userContentController = contentController
        configuration.dataDetectorTypes = .all
        super.init(frame: frame, configuration: configuration)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.bounces = false
        navigationDelegate = self
    }
    
    func insertCSSString(into webView: WKWebView) {
        guard let cssString = generateCustomCSSIncludeTag() else { return }
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    func generateCustomCSSIncludeTag() -> String? {
        return nil
    }
    
    deinit {
        navigationDelegate = nil
    }
    
}

// MARK: - WKNavigationDelegate

extension GRDWebView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        insertCSSString(into: webView)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
        guard url.scheme == "file" else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return decisionHandler(.cancel)
        }
        if let _request = lastRequest, _request.url == url {
            if navigationAction.navigationType == .other {
                lastRequest = nil
            }
            return decisionHandler(.cancel)
        }
        lastRequest = navigationAction.request
        return decisionHandler(.allow)
    }
    
}
