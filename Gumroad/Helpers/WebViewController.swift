//
//  WebViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/8/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var onCurrentURLChange: ((URL) -> Void)? = nil

    init() {
        super.init(nibName: nil, bundle: nil)
        self.webView = WKWebView(frame: .zero)
        self.webView.navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = self.view.bounds
        self.view.addSubview(webView)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeTapped))
        closeButton.tintColor = UIColor(named: "GumroadLabelColor")
        self.navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            onCurrentURLChange?(url)
        }
    }
}
