//
//  GRDEpubWebView.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 3/18/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import UIKit
import WebKit

class GRDEpubWebView: GRDWebView {
    
    override func commonInit() {
        super.commonInit()
        self.accessibilityLabel = "epubWebView"
    }
    
    // MARK: - Custom methods
    
    override func generateCustomCSSIncludeTag() -> String? {
        let cssFilePath = Bundle.main.path(forResource: "custom_epub_styling", ofType: "css")
        let cssTemplate = "<link rel='stylesheet' type='text/css' href='%@' />"
        var cssInternalIncludeTag = String(format: cssTemplate, cssFilePath!)
        let cssExternalIncludeTag = String(format: cssTemplate, GRDNetworkRequest.shared.externalEpubCSSStylingUrlString)
        cssInternalIncludeTag.append(cssExternalIncludeTag)
        return cssInternalIncludeTag
    }
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
        if let epubViewController = self.superview?.next as? GRDEPubViewController, let url = lastRequest?.url {
            epubViewController.updatePageIndex(url)
        }
    }
}
