//
//  GRDEPubViewController.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 2/18/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import UIKit
import WebKit
import KFEpubKit

class GRDEPubViewController: UIViewController {
    weak var webView: GRDEpubWebView?
    var epubContentUrl: URL?
    var epubContentModel: KFEpubContentModel?
    var epubController: KFEpubController?
    var pageIndex: Int = 0
    var file: File?

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityLabel = "epubViewController"
        self.webView?.removeFromSuperview()
        let webView = GRDEpubWebView()
        self.view.addSubview(webView)
        self.setupWebviewConstraints(webView: webView)
        self.webView = webView
        if let webView = self.webView, let contentURL = self.epubContentUrl {
            webView.load(URLRequest(url: contentURL))
        }
    }

    func updatePageIndex(_ newUrl: URL) {
        if let epubContentModel = self.epubContentModel {
            let manifest = epubContentModel.manifest as NSDictionary
            let spine : Array<String> = epubContentModel.spine as! Array<String>
            var index = 0
            for spineValue in spine {
                guard let manifestValue = manifest[spineValue] as? NSDictionary,
                      let contentFile = manifestValue["href"] as? String else {
                    index += 1
                    continue
                }
                let contentURL = self.epubController?.epubContentBaseURL.appendingPathComponent(contentFile)
                if (newUrl.path == contentURL!.path) {
                    break
                }
                index += 1
            }
            if let file = self.file {
                file.updateResumeLocation(index)
                // This is necessary since we don't get page change notifications when the user clicks on a toc item:
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: GRDEPubPageViewController.notificationCenterObserverName()), object: spine[index])
            }
            self.pageIndex = index
        }
    }
    
    // MARK: - Constraint setup
    
    func setupWebviewConstraints(webView: WKWebView) {
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self.view, attribute: .height, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0))
    }
}
