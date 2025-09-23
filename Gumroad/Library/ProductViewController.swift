//
//  ProductViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/8/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import CoreData
import AVKit
import SwiftUI

class ProductViewController: FileOpenableViewController, StoryboardIdentifiable, WKUIDelegate {
    static var storyboardName: StoryboardName = .library
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewImage: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var spinnerImageView: UIImageView!
    var product: Product?
    var files: [File] = []
    var posts: [Installment] = []
    var fetchedFilesResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var fetchedInstallmentsResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var productRefreshCount = 0
    
    var moreLikeThisEnabledForUser = false
    var moreLikeThisViewController: UIHostingController<AnyView>?
    
    var hasLoadedWebView = false {
        didSet {
            loadingView.isHidden = hasLoadedWebView && hasLoadedProductHeaderView && hasLoadedProductData
        }
    }
    var hasLoadedProductHeaderView = false {
        didSet {
            loadingView.isHidden = hasLoadedWebView && hasLoadedProductHeaderView && hasLoadedProductData
        }
    }
    var hasLoadedProductData = true {
        didSet {
            loadingView.isHidden = hasLoadedWebView && hasLoadedProductHeaderView && hasLoadedProductData
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
        if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate {
            stackViewBottomConstraint.constant = appDelegate.isMiniPlayerShown() ? -MiniPlayerView.BASE_HEIGHT : 0
            stackView.layoutIfNeeded()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let spinnerRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        spinnerRotateAnimation.fromValue = 0.0
        spinnerRotateAnimation.toValue = CGFloat(.pi * 2.0)
        spinnerRotateAnimation.duration = 1
        spinnerRotateAnimation.repeatCount = .greatestFiniteMagnitude
        spinnerRotateAnimation.isRemovedOnCompletion = false
        spinnerImageView.layer.add(spinnerRotateAnimation, forKey: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.productViewController = self
        
        setupLeftEdgeSwipeGesture()
        
        guard let product = product else {
            navigationController?.popViewController(animated: true)
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(syncAudioInfoWithWebView), name: NSNotification.Name(rawValue: GRDNotificationStrings.audioInfoForWebViewNotificationString()), object: nil)
        
        fetchedFilesResultsController = CoreDataManager.shared.fetchedResultsController(forProductFiles: product)
        fetchedInstallmentsResultsController = CoreDataManager.shared.fetchedResultsController(forInstallments: product)
        do {
            try fetchedFilesResultsController?.performFetch()
            try fetchedInstallmentsResultsController?.performFetch()
        } catch let error {
            print(error.localizedDescription)
        }
        
        webView.navigationDelegate = self
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "jsMessage")
        let javaScriptPolyfills = """
            if (!Object.hasOwn) {
              Object.hasOwn = function(obj, prop) { return obj.hasOwnProperty(prop) };
            }
            if (typeof globalThis === "undefined") {
              var globalThis = Function("return this")();
            }
        """.replacingOccurrences(of: "\n", with: "")
        contentController.addUserScript(WKUserScript(source: javaScriptPolyfills, injectionTime: .atDocumentStart, forMainFrameOnly: false))

        files = fetchedFilesResultsController?.fetchedObjects as? [File] ?? []
        posts = fetchedInstallmentsResultsController?.fetchedObjects as? [Installment] ?? []
        
        if let urlRedirectToken = product.url_redirect_token {
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
            webView.isHidden = true
            webView.load(URLRequest(url: URL(string: "\(Environment.rootURLString)/d/\(urlRedirectToken)?display=mobile_app")!, timeoutInterval: TimeInterval(webViewTimeoutInSeconds)))
        } else {
            emptyView.isHidden = true
            webView.isHidden = true
        }
        
        if moreLikeThisEnabledForUser, let permalink = product.unique_permalink {
            GRDNetworkRequest.shared.relatedProducts(permalink: permalink,
                                                     context: "library",
                                                     successBlock: { [weak self] relatedProducts in
                guard let self = self else { return }
                
                setupProductHeaderView(showTabButtons: relatedProducts.count > 0)
                
                var products = relatedProducts
                Task {
                    let relatedStoreProducts = await Store().fetchStoreKitProducts(for: products)
                    products.indices.forEach({ index in
                        products[index].prepareForDisplay(with: relatedStoreProducts)
                        products[index].recommendationType = .library
                    })
                    
                    if products.count > 0 {
                        DispatchQueue.main.async {
                            let productGrid =
                                ScrollViewReader { proxy in
                                    ScrollView(showsIndicators: false) {
                                        DiscoverProductGrid(products: products, onProductClick: self.onProductClick)
                                    }
                                }
                                .background(Color(UIColor(named: "GumroadTopViewColor")!))
                            let hostingController = UIHostingController(rootView: AnyView(productGrid))
                            self.addChild(hostingController)
                            self.view.insertSubview(hostingController.view, belowSubview: self.webView)
                            hostingController.didMove(toParent: self)
                            
                            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                            NSLayoutConstraint.activate([
                                hostingController.view.topAnchor.constraint(equalTo: self.emptyView.topAnchor),
                                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                            ])
                            
                            hostingController.view.isHidden = true
                            self.moreLikeThisViewController = hostingController
                        }
                    }
                }
                logEvent("discover_related_products_loaded", params: ["count": relatedProducts.count])
            }, failureBlock: { [weak self] error in
                self?.setupProductHeaderView(showTabButtons: false)
                logEvent("discover_related_products_error", params: ["error": error.localizedDescription])
            })
        } else {
            self.setupProductHeaderView(showTabButtons: false)
        }
    }
    
    func setupProductHeaderView(showTabButtons: Bool) {
        guard let product = product else { return }
        let productHeaderView = ProductHeaderView(product: product, showTabButtons: showTabButtons) { [weak self] newTab in
            self?.webView.isHidden = newTab == .moreLikeThis
            self?.moreLikeThisViewController?.view.isHidden = newTab == .content
        }
        let hostingController = UIHostingController(rootView: productHeaderView)
        hostingController.view.backgroundColor = .clear
        
        if let headerView = hostingController.view {
            stackView.insertArrangedSubview(headerView, at: 0)
            
            headerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            ])
        }
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        
        hasLoadedProductHeaderView = true
    }
    
    @objc func syncAudioInfoWithWebView(_ notification: NSNotification) {
        if let file = notification.userInfo?["file"] as? File, let isPlaying = notification.userInfo?["isPlaying"] as? Bool, let fileId = file.external_id, let latestMediaLocation = file.resume_location {
            let latestMediaLocation = isPlaying && Int(truncating: latestMediaLocation) < 1 ? 1 : latestMediaLocation
            let script = """
                window.dispatchEvent(new CustomEvent("mobile_app_audio_player_info", { detail: { fileId: "\(fileId)", isPlaying: \(isPlaying), latestMediaLocation: "\(latestMediaLocation)" } }));
            """.replacingOccurrences(of: "\n", with: "")
            self.webView.evaluateJavaScript(script,
                completionHandler: { (response, error) -> Void in
                if let error = error { print("JS evaluation error: \(error)") }
            })
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: MiniPlayerView.miniPlayerUpdatedNotificationString), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: GRDNotificationStrings.audioInfoForWebViewNotificationString()), object: nil)
    }
    
    @IBAction func backButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        navigationController?.popViewController(animated: true)
    }
}

extension ProductViewController: WKNavigationDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        hasLoadedWebView = false
    }
    
    func handleWebViewError(error: Error) {
        let errorAlert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { UIAlertAction in
            self.hasLoadedWebView = true
            self.navigationController?.popViewController(animated: true)
        }))
        present(errorAlert, animated: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleWebViewError(error: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        handleWebViewError(error: error)
    }
    
    func setFileEmbedClickEventHandlers() {
        let script = """
            document.addEventListener("click", (e) => {
              const el = e.target.closest("[data-event-name*='_click']:not([data-event-name='send_to_kindle_click']):not([data-event-name='post_click']), .js-read");
              if (!el) return;
              e.preventDefault();
              e.stopPropagation();
              const dataAttrs = el.dataset;
              if (dataAttrs.resourceId) {
                window.webkit.messageHandlers.jsMessage.postMessage({
                  type: "click",
                  payload: {
                    resourceId: dataAttrs.resourceId,
                    isDownload: dataAttrs.eventName === "download_click",
                    type: dataAttrs.type,
                    isPlaying: dataAttrs.playing,
                    resumeAt: dataAttrs.resumeAt,
                    contentLength: dataAttrs.contentLength,
                  }
                });
              }
            }, true);
            "";
        """.replacingOccurrences(of: "\n", with: "")
        let delayInSeconds = 0.5;
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            self.webView.evaluateJavaScript(script,
                completionHandler: { (response, error) -> Void in
                if let error = error { print("JS evaluation error: \(error)") }
            })
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hasLoadedWebView = true
        let email = product?.purchase_email ?? ""

        let css = """
            .button:hover, button:hover {
              transform: unset !important;
              box-shadow: unset !important;
            }
            .button.primary:hover, button.primary:hover {
              background-color: var(--primary) !important;
              color: var(--white) !important;
            }
        """.replacingOccurrences(of: "\n", with: "")
        let script = """
            const style = document.createElement('style');
            style.innerHTML = '\(css)';
            document.head.appendChild(style);
        
            /* Show post preview natively */
            document.addEventListener("click", (e) => {
              const el = e.target.closest("[data-event-name='post_click']");
              if (!el) return;
              e.preventDefault();
              e.stopPropagation();
              window.webkit.messageHandlers.jsMessage.postMessage({
                type: "click",
                payload: {
                  resourceId: el.dataset.resourceId,
                  isPost: true,
                },
              });
            });

            const emailField = document.getElementsByName("email")[0];
            if (window.location.pathname === "/confirm" && emailField) {
              emailField.value = "\(email)";
              if (document.querySelector(".js-message")?.textContent?.length > 0) {
                  window.webkit.messageHandlers.jsMessage.postMessage({ type: "show-webview" });
              } else {
                emailField.form.submit();
              }
            } else {
              window.webkit.messageHandlers.jsMessage.postMessage({ type: "show-webview" });
            }
            "";
        """.replacingOccurrences(of: "\n", with: "")
        webView.evaluateJavaScript(script,
            completionHandler: { (response, error) -> Void in
                if let error = error { print("JS evaluation error: \(error)") }
            })
        setFileEmbedClickEventHandlers()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        defer {
           decisionHandler(.allow)
       }
        guard
            navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url,
            let scheme = url.scheme,
            ["http", "https"].contains(scheme)
        else {
            return
        }

        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    func refreshProductData(onSuccess: @escaping () -> Void) {
        if (productRefreshCount > 1) { onSuccess(); return }

        productRefreshCount += 1
        
        hasLoadedProductData = false
        GRDNetworkRequest.shared.fetchExistingPurchases(successBlock: { [weak self] _,_ in
            guard let self = self else { onSuccess(); return }
            guard let updatedProduct = CoreDataManager.shared.getProduct(with: self.product?.unique_permalink) else { onSuccess(); return }
            
            self.product = updatedProduct
            self.fetchedFilesResultsController = CoreDataManager.shared.fetchedResultsController(forProductFiles: updatedProduct)
            self.fetchedInstallmentsResultsController = CoreDataManager.shared.fetchedResultsController(forInstallments: updatedProduct)
            do {
                try self.fetchedFilesResultsController?.performFetch()
                try self.fetchedInstallmentsResultsController?.performFetch()
            } catch let error {
                print(error.localizedDescription)
            }
            self.files = self.fetchedFilesResultsController?.fetchedObjects as? [File] ?? []
            self.posts = self.fetchedInstallmentsResultsController?.fetchedObjects as? [Installment] ?? []
            
            onSuccess()
            
            self.hasLoadedProductData = true
        }, failureBlock: { [weak self] _ in
            self?.hasLoadedProductData = true
        })
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? NSDictionary else { return }
        guard let messageType = messageBody.value(forKey: "type") as? String else { return }
        if messageType == "show-webview" {
            webView.isHidden = false
        } else if messageType == "click" {
            guard let messagePayload = messageBody.value(forKey: "payload") as? NSDictionary else { return }
            guard let resourceId = messagePayload.value(forKey: "resourceId") as? String else { return }
            let isPost = messagePayload.value(forKey: "isPost") as? Int == 1
            
            if isPost {
                guard let post = posts.first(where: { $0.external_id == resourceId }) else {
                    refreshProductData {
                        guard let post = self.posts.first(where: { $0.external_id == resourceId }) else { return }
                        let vc = InstallmentViewController.instantiate()
                        vc.installment = post
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    return
                }
                let vc = InstallmentViewController.instantiate()
                vc.installment = post
                navigationController?.pushViewController(vc, animated: true)
            } else {
                guard let file = files.first(where: { $0.external_id == resourceId }) else {
                    refreshProductData {
                        guard let file = self.files.first(where: { $0.external_id == resourceId }) else { return }
                        self.openFile(file: file, messagePayload: messagePayload)
                    }
                    return
                }
                openFile(file: file, messagePayload: messagePayload)
            }
        }
    }
}
