//
//  HomeViewController.swift
//  iOSCreator
//
//  Created by Nathan Chan on 10/2/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit
import SwiftUI

class HomeViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .creator

    @IBOutlet weak var homeTitleLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var revenueLabel: UILabel!
    @IBOutlet weak var customerLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noSalesLabel: UILabel!

    private var searchOverlay: SearchOverlayView?
    private var isSearchOverlayVisible = false

    var purchasesData: [[String: String]] = [] {
        didSet {
            tableView.reloadData()
            noSalesLabel.isHidden = !purchasesData.isEmpty
        }
    }
    let refreshControl = UIRefreshControl()
    var spinnerImageViewHeightConstraint: NSLayoutConstraint!
    var timeRangeSelectedIndex = 0

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        topView.clipsToBounds = true
        let topBorder = CALayer()
        topBorder.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        topBorder.frame = CGRect(x: 0, y: 0, width: topView.frame.size.width, height: 1)
        topBorder.borderWidth = 1
        topView.layer.addSublayer(topBorder)
        let bottomBorder = CALayer()
        bottomBorder.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        bottomBorder.frame = CGRect(x: 0, y: topView.frame.size.height - 0.25, width: topView.frame.size.width, height: 0.25)
        bottomBorder.borderWidth = 0.25
        topView.layer.addSublayer(bottomBorder)
        topView.layer.masksToBounds = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        let frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1 / UIScreen.main.scale)
        let line = UIView(frame: frame)
        tableView.tableHeaderView = line
        line.backgroundColor = tableView.separatorColor

        searchBar.isHidden = true
        searchButton.setBackgroundImage(UIImage(named: "discover-tab-unselected"), for: .normal)
        searchButton.setBackgroundImage(UIImage(named: "discover-tab-selected"), for: .selected)
        noSalesLabel.isHidden = true
        noSalesLabel.text = "No sales found"

        refreshData()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: NSNotification.Name(rawValue: GRDNotificationStrings.pushNotificationReceivedNotificationString()), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.willEnterForegroundNotification, object: nil)

        let spinnerImageView = UIImageView(image: UIImage(named: "spinner"))
        let spinnerRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        spinnerRotateAnimation.fromValue = 0.0
        spinnerRotateAnimation.toValue = CGFloat(.pi * 2.0)
        spinnerRotateAnimation.duration = 1
        spinnerRotateAnimation.repeatCount = .greatestFiniteMagnitude
        spinnerRotateAnimation.isRemovedOnCompletion = false
        spinnerImageView.layer.add(spinnerRotateAnimation, forKey: nil)
        refreshControl.addSubview(spinnerImageView)
        spinnerImageView.translatesAutoresizingMaskIntoConstraints = false
        spinnerImageView.centerXAnchor.constraint(equalTo: refreshControl.centerXAnchor).isActive = true
        spinnerImageView.topAnchor.constraint(equalTo: refreshControl.topAnchor, constant: 17.5).isActive = true
        spinnerImageViewHeightConstraint = spinnerImageView.heightAnchor.constraint(equalToConstant: 30)
        spinnerImageViewHeightConstraint.isActive = true
        spinnerImageView.widthAnchor.constraint(equalTo: spinnerImageView.heightAnchor).isActive = true
        refreshControl.tintColor = .clear
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshExistingTimeRangeData), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide search overlay when returning to home tab
        if isSearchOverlayVisible {
            hideSearchOverlay()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: GRDNotificationStrings.pushNotificationReceivedNotificationString()), object: nil)
    }

    @objc func refreshData() {
        for button in stackView.arrangedSubviews.compactMap({ $0 as? UIButton }) {
            button.isSelected = false
        }

        timeRangeSelectedIndex = UserDefaults.standard.integer(forKey: timeRangeSelectedIndexUserDefaultsKey)
        (stackView.arrangedSubviews[timeRangeSelectedIndex] as? UIButton)?.isSelected = true
        updateData(with: GRDCreatorDataHandler.TimeRange.allCases[timeRangeSelectedIndex])
    }

    @objc func refreshExistingTimeRangeData() {
        updateData(with: GRDCreatorDataHandler.TimeRange.allCases[timeRangeSelectedIndex])
    }

    func updateData(with timeRange: GRDCreatorDataHandler.TimeRange) {
        timeRangeSelectedIndex = UserDefaults.standard.integer(forKey: timeRangeSelectedIndexUserDefaultsKey)

        GRDNetworkRequest.shared.fetchCreatorAnalytics(timeRange.rawValue, successBlock: { [self] (response, responseObject) -> Void in
            guard let data = responseObject as? [String: Any] else { return }

            if let revenueString = data["formatted_revenue"] as? String,
                let salesCountInt = data["sales_count"] as? Int,
                let purchasesNSArray = data["purchases"] as? NSArray
            {
                purchasesData = GRDCreatorDataHandler.parsePurchases(purchasesNSArray)

                revenueLabel.text = revenueString

                if salesCountInt == 1 {
                    customerLabel.text = "from \(salesCountInt) sale"
                } else {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    let formattedValue = numberFormatter.string(from: NSNumber(value: salesCountInt))
                    customerLabel.text = "from \(formattedValue ?? "\(salesCountInt)") sales"
                }
            }
            revenueLabel.isHidden = false
            customerLabel.isHidden = false
            activityIndicator.isHidden = true
            refreshControl.endRefreshing()
        }, failureBlock: { [self] (error) -> Void in
            revenueLabel.isHidden = false
            customerLabel.isHidden = false
            activityIndicator.isHidden = true
            refreshControl.endRefreshing()
        })
    }

    @IBAction func settingsButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let settingsView = UIHostingController(rootView: SettingsUIView(onLogoutCompleted: { self.dismiss(animated: false)}))
        self.present(settingsView , animated: true, completion: nil)
    }

    @IBAction func datetabButtonClicked(_ sender: UIButton) {
        if !sender.isSelected {
            for button in stackView.arrangedSubviews.compactMap({ $0 as? UIButton }) {
                if button != sender {
                    button.isSelected = false
                }
            }
            sender.isSelected = true
            revenueLabel.isHidden = true
            customerLabel.isHidden = true
            activityIndicator.isHidden = false
            purchasesData = []

            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            UserDefaults.standard.set(sender.tag, forKey: timeRangeSelectedIndexUserDefaultsKey)

            updateData(with: GRDCreatorDataHandler.TimeRange.allCases[sender.tag])
        }
    }

    @IBAction func searchButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if isSearchOverlayVisible {
            hideSearchOverlay()
        } else {
            showSearchOverlay()
        }
    }

    private func showSearchOverlay() {
        searchOverlay = SearchOverlayView()
        searchOverlay?.delegate = self
        // Pass the existing table view and top view to reuse the exact same setup
        searchOverlay?.show(in: view, with: purchasesData, tableView: tableView, topView: topView)
        isSearchOverlayVisible = true
        searchButton.isSelected = true
    }

    private func hideSearchOverlay() {
        searchOverlay?.hide()
        searchOverlay = nil
        isSearchOverlayVisible = false
        searchButton.isSelected = false
    }
}

extension HomeViewController: SearchOverlayDelegate {
    func searchOverlay(_ overlay: SearchOverlayView, didSelectPurchase purchase: [String: String]) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if let saleId = purchase["id"] {
            let hostingController = UIHostingController(rootView:
                                                            SaleDrawerView(
                                                                saleId: saleId,
                                                                inAppPurchasePlatform: fetchInAppPurchasePlatform(from: purchase)
                                                            ))
            self.present(hostingController, animated: true, completion: nil)
        }
    }

    func searchOverlayDidCancel(_ overlay: SearchOverlayView) {
        hideSearchOverlay()
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return purchasesData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductSaleTableViewCell.identifier) as? ProductSaleTableViewCell else {
            fatalError("The nib is not an instance of \(ProductSaleTableViewCell.identifier).")
        }
        let purchaseData = purchasesData[indexPath.row]
        cell.selectionStyle = .none
        cell.configure(
            productName: purchaseData["product_name"] ?? "",
            price: purchaseData["formatted_total_price"] ?? "",
            customerEmail: purchaseData["email"] ?? "",
            timestamp: purchaseData["timestamp"] ?? "",
            thumbnailURL: purchaseData["product_thumbnail_url"],
            isRefunded: purchaseData["refunded"] == "1",
            isPartiallyRefunded: purchaseData["partially_refunded"] == "1",
            isChargedback: purchaseData["chargedback"] == "1",
            isInAppPurchase: checkIsInAppPurchase(with: purchaseData)
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let purchaseData = purchasesData[indexPath.row]
        if let saleId = purchaseData["id"] {
            let hostingController = UIHostingController(rootView:
                                                            SaleDrawerView(
                                                                saleId: saleId,
                                                                inAppPurchasePlatform: fetchInAppPurchasePlatform(from: purchaseData)
                                                            ))
            self.present(hostingController, animated: true, completion: nil)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshControl.alpha = min(1, max(0, (-scrollView.contentOffset.y - 20) / 40))
        spinnerImageViewHeightConstraint.constant = 10 + (refreshControl.alpha * 20)
    }
}
