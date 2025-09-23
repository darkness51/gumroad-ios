//
//  LibraryViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/15/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit
import StoreKit
import CoreData
import SwiftUI

class LibraryViewController: UIViewController, StoryboardIdentifiable, FilterRowDelegate, ProductTableViewCellDelegate, ProductCarouselTableViewCellDelegate {
    static var storyboardName: StoryboardName = .library
    
    @IBOutlet weak var libraryTitleLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterTitleLabel: UILabel!
    @IBOutlet weak var filterClearButton: UIButton!
    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var filterStackView: UIStackView!
    @IBOutlet weak var filterDoneButton: UIButton!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var skeletonView: UIView!
    
    let refreshControl = UIRefreshControl()
    var spinnerImageViewHeightConstraint: NSLayoutConstraint!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var searchText: String?
    var filterViewIsVisible = false
    var scrollViewLastContentOffsetY: CGFloat = 0
    var productsToShow: [Product] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    var allProducts: [Product] = [] {
        didSet {
            if let storedrecentlyViewedProductIds = UserDefaults.standard.stringArray(forKey: recentlyViewedUserDefaultsKey) {
                recentlyViewedProductIds = storedrecentlyViewedProductIds.isEmpty ?
                    Array(allProducts
                        .filter({ $0.is_archived == 0 })
                        .compactMap({ $0.url_redirect_external_id })
                        .prefix(1)) :
                    storedrecentlyViewedProductIds
            }
        }
    }
    var recentlyViewedProductIds: [String] = [] {
        didSet {
            UserDefaults.standard.set(recentlyViewedProductIds, forKey: recentlyViewedUserDefaultsKey)
            recentlyViewedProducts = recentlyViewedProductIds.compactMap({ id in allProducts.first(where: { $0.url_redirect_external_id ?? "" == id }) })
        }
    }
    var recentlyViewedProducts: [Product] = [] {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.productCarouselCell.configure(products: self.recentlyViewedProducts)
            }
        }
    }
    
    var productCarouselCell = ProductCarouselTableViewCell()
    var resultsCell = LibraryFilterResultsTableViewCell()
    let productCarouselCellHeight: CGFloat = 230
    let resultsCellHeight: CGFloat = 40
    let productCellHeight: CGFloat = 70
    
    var moreLikeThisEnabledForUser = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        topView.clipsToBounds = true
        let topBorder = CALayer()
        topBorder.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        topBorder.frame = CGRect(x: 0, y: 0, width: topView.frame.size.width, height: 1)
        topBorder.borderWidth = 1
        topView.layer.addSublayer(topBorder)
        let bottomBorder = CALayer()
        bottomBorder.borderColor = UIColor(named: "GumroadLibraryBorderColor")?.cgColor
        bottomBorder.frame = CGRect(x: 0, y: topView.frame.size.height - 1, width: topView.frame.size.width, height: 1)
        bottomBorder.borderWidth = 1
        topView.layer.addSublayer(bottomBorder)
        topView.layer.masksToBounds = true
        
        let filterBorder = CALayer()
        filterBorder.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        filterBorder.frame = CGRect(x: 0, y: 0, width: 1, height: filterView.frame.size.height)
        filterBorder.borderWidth = 1
        filterView.layer.addSublayer(filterBorder)
        filterView.layer.masksToBounds = true
        
        updateFilterViewHeight()
        
        sortByButton.layer.borderColor = UIColor(named: "GumroadLabelColor")?.cgColor
        sortByButton.layer.borderWidth = 1
        sortByButton.layer.cornerRadius = 4
        sortByButton.setTitle(SortByType.fetchSavedType().label, for: .normal)
        let sortByButtonImage = UIImage(named: "chevron-down")?.withTintColor(UIColor(named: "GumroadLabelColor")!)
        sortByButton.setImage(sortByButtonImage, for: .normal)
        sortByButton.contentHorizontalAlignment = .left
        
        let titleWidth = sortByButton.titleLabel?.intrinsicContentSize.width ?? 0
        let imageWidth = sortByButtonImage?.size.width ?? 0
        let spacing: CGFloat = 16
        let titleInset = imageWidth - spacing
        let imageInset = sortByButton.bounds.width - imageWidth - spacing
        sortByButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -titleInset, bottom: 0, right: titleInset)
        sortByButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: imageInset, bottom: 0, right: -imageInset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.text = nil
        searchBar.searchTextField.font = UIFont(name: "Mabry Pro", size: 16)
        searchBar.searchTextField.backgroundColor = .systemBackground
        searchBar.searchTextField.textColor = UIColor.label
        searchBar.searchTextField.layer.borderWidth = 0
        let searchImage = UIImage(named: "search")
        searchBar.setImage(searchImage, for: .search, state: .normal)
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        searchBar.layer.cornerRadius = 4
        searchBar.backgroundImage = UIImage()
        searchBar.placeholder = "Search for products"
        
        filterTitleLabel.text = "Filter"
        filterClearButton.setTitle("Clear", for: .normal)
        filterDoneButton.setTitle("Done", for: .normal)
        filterDoneButton.layer.cornerRadius = 4
        
        filterViewWidthConstraint.constant = UIDevice.current.userInterfaceIdiom == .pad ? 375 : 250
        
        let nib = UINib(nibName: ProductTableViewCell.identifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: ProductTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 8))
        let tap = UITapGestureRecognizer(target: self, action: #selector(forceCloseFilterView))
        tableView.backgroundView = UIView()
        tableView.backgroundView?.addGestureRecognizer(tap)
        
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
        refreshControl.addTarget(self, action: #selector(refreshNetworkData), for: .valueChanged)
        
        emptyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(refreshNetworkData)))
        emptyLabel.text = "Your Library is empty"
        
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = UITraitCollection.current.userInterfaceStyle == .dark ? 0.05 : 0.5
        pulseAnimation.toValue = UITraitCollection.current.userInterfaceStyle == .dark ? 0.2 : 1
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        skeletonView.layer.add(pulseAnimation, forKey: nil)
        
        productCarouselCell.delegate = self
        productCarouselCell.selectionStyle = .none
        productCarouselCell.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        resultsCell.selectionStyle = .none
    
        fetchedResultsController = CoreDataManager.shared.fetchedResultsControllerForLibrary()
        refreshLocalData(hasRefreshedNetwork: false)
        refreshNetworkData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNetworkData), name: UIApplication.willEnterForegroundNotification, object: nil)

        let openCount = UserDefaults.standard.integer(forKey: appOpenCountUserDefaultsKey)
        if [5, 10, 20].contains(openCount) {
            SKStoreReviewController.requestReview()
        }
        
        GRDNetworkRequest.shared.featureFlagCheck(id: "ios_library_more_like_this", successBlock: { (enabledForUser) -> Void in
            print("featureFlagCheck ios_library_more_like_this enabledForUser: \(enabledForUser)")
            self.moreLikeThisEnabledForUser = enabledForUser
        }, failureBlock: { (error) -> Void in
            print("featureFlagCheck error: \(error.localizedDescription)")
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        recentlyViewedProductIds = UserDefaults.standard.stringArray(forKey: recentlyViewedUserDefaultsKey) ?? []
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func updateFilterViewHeight() {
        if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate {
            filterViewHeightConstraint.constant = appDelegate.isMiniPlayerShown()
            ? (view.bounds.height - MiniPlayerView.getHeight() + (tabBarController?.tabBar.frame.size.height ?? 0))
            : view.bounds.height
            filterView.layoutIfNeeded()
        }
    }
    
    @objc func refreshNetworkData() {
        GRDNetworkRequest.shared.fetchExistingPurchases(successBlock: { [weak self] _,_ in
            self?.refreshLocalData(hasRefreshedNetwork: true)
            self?.refreshControl.endRefreshing()
            self?.skeletonView.isHidden = true
        }, failureBlock: { [weak self] _ in
            self?.refreshControl.endRefreshing()
            self?.skeletonView.isHidden = true
        })
    }
    
    func refreshLocalData(hasRefreshedNetwork: Bool, autoScrollAfterComplete: Bool = true) {
        do {
            try fetchedResultsController?.performFetch()
        } catch let error {
            print(error.localizedDescription)
        }
        allProducts = fetchedResultsController?.fetchedObjects as? [Product] ?? []
        if allProducts.isEmpty {
            skeletonView.isHidden = hasRefreshedNetwork
            emptyView.isHidden = !hasRefreshedNetwork
        } else {
            DispatchQueue.main.async {
                self.emptyView.isHidden = true
                self.applySearchAndFilters(shouldRedrawFilterRows: true, hasRefreshedNetwork: hasRefreshedNetwork, autoScrollAfterComplete: autoScrollAfterComplete)
                self.attemptShowingProductForSavedUrlRedirectToken()
            }
        }
        (tabBarController as? MainTabViewController)?.loadingView.isHidden = true
    }
    
    func applySearchAndFilters(shouldRedrawFilterRows: Bool = false, hasRefreshedNetwork: Bool = false, userTriggered: Bool = false, autoScrollAfterComplete: Bool = true) {
        let unarchivedProducts = allProducts.filter({ $0.is_archived == 0 })
        let archivedProducts = allProducts.filter({ $0.is_archived == 1 })
        var productsToShow: [Product] = []
        var isShowingArchivedOnly = false
        
        if !hasRefreshedNetwork,
            !archivedProducts.isEmpty,
            let archivedFilterRow = filterStackView.arrangedSubviews
            .compactMap({ $0 as? FilterRow })
            .first(where: { $0.type == .archived }),
            archivedFilterRow.selectionButton.isSelected {
            
            isShowingArchivedOnly = true
            productsToShow = archivedProducts
        } else {
            productsToShow = unarchivedProducts
        }
        
        if shouldRedrawFilterRows {
            var filterMap: [String: Int] = [:]
            for product in productsToShow {
                guard let creatorName = product.creator_name else { continue }
                if let val = filterMap[creatorName] {
                    filterMap[creatorName] = val + 1
                } else {
                    filterMap[creatorName] = 1
                }
            }
            
            var creatorCounts = filterMap.map({ ($0, $1) })
            // sort by count desc, then alphabetical name asc
            creatorCounts = creatorCounts.sorted { c1, c2 in
                return (c2.1, c1.0.lowercased()) < (c1.1, c2.0.lowercased())
            }
            
            for subview in filterStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            
            let allFilterRow = FilterRow(width: filterViewWidthConstraint.constant, labelText: "", count: productsToShow.count, type: .all)
            allFilterRow.delegate = self
            filterStackView.addArrangedSubview(allFilterRow)
            
            for values in creatorCounts {
                let filterRow = FilterRow(width: filterViewWidthConstraint.constant, labelText: values.0, count: values.1, type: .creator)
                filterRow.delegate = self
                filterStackView.addArrangedSubview(filterRow)
            }
            
            if archivedProducts.count > 0 {
                let archivedFilterRow = FilterRow(width: filterViewWidthConstraint.constant, labelText: "", count: 0, type: .archived)
                archivedFilterRow.delegate = self
                filterStackView.addArrangedSubview(archivedFilterRow)
                archivedFilterRow.selectionButton.isSelected = isShowingArchivedOnly
            }
        }
        
        if let searchText = searchText {
            productsToShow = productsToShow.filter {
                ($0.name ?? "").lowercased().contains(searchText.lowercased()) || ($0.creator_name ?? "").lowercased().contains(searchText.lowercased())
            }
        }
        
        var creatorFilters = Set<String>()
        let filterRows = filterStackView.arrangedSubviews.compactMap({ $0 as? FilterRow })
        for filterRow in filterRows {
            if filterRow.selectionButton.isSelected,
                let creatorName = filterRow.creatorLabel.text {
                if filterRow.type == .all {
                    creatorFilters = []
                    break
                } else if filterRow.type == .creator {
                    creatorFilters.insert(creatorName)
                }
            }
        }
        if !creatorFilters.isEmpty {
            productsToShow = productsToShow.filter {
                creatorFilters.contains($0.creator_name ?? "")
            }
        }
        
        let areNoFiltersSelected = filterRows.filter({ $0.type != .all })
                                            .allSatisfy({ !$0.selectionButton.isSelected })
        filterClearButton.isHidden = areNoFiltersSelected
        filterButton.setImage(UIImage(named: "filter-\(areNoFiltersSelected ? "off" : "on")"), for: .normal)
        var resultsLabelText = "Showing \(productsToShow.count) product\(productsToShow.count == 1 ? "" : "s")"
        resultsCell.setLabel(resultsLabelText)
        
        productsToShow.sort(by: {
            let sortBy = SortByType.fetchSavedType()
            let defaultDate = Date(timeIntervalSinceReferenceDate: 0)
            let a = (sortBy == .recentlyUpdated ? $0.content_updated_at : $0.purchased_at) ?? defaultDate
            let b = (sortBy == .recentlyUpdated ? $1.content_updated_at : $1.purchased_at) ?? defaultDate
            return a > b
        })
        
        self.productsToShow = productsToShow
        if autoScrollAfterComplete {
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: max(8, tableView.bounds.size.height - (CGFloat(productsToShow.count) * productCellHeight) - resultsCellHeight)))
            let indexPath = IndexPath(row: userTriggered ? 1 : 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    func filterSelected(by filterRow: FilterRow, shouldForceRedraw: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let allFilterRows = filterStackView.arrangedSubviews.compactMap({ $0 as? FilterRow })
        let filterRows = allFilterRows.filter { $0.type == .creator }
        let allCreatorFilterRow = allFilterRows.first(where: { $0.type == .all })!
        let isArchivedFilterRow = filterRow == allFilterRows.first(where: { $0.type == .archived })
        
        if filterRow == allCreatorFilterRow && allCreatorFilterRow.selectionButton.isSelected {
            for filterRow in filterRows {
                if filterRow.type == .creator {
                    filterRow.selectionButton.isSelected = false
                }
            }
        } else if !isArchivedFilterRow {
            allCreatorFilterRow.selectionButton.isSelected = filterRows.allSatisfy({ !$0.selectionButton.isSelected })
        }
        
        applySearchAndFilters(shouldRedrawFilterRows: shouldForceRedraw || isArchivedFilterRow, userTriggered: true)
    }
    
    @objc func forceCloseFilterView() {
        toggleFilterView(forceClose: true)
    }
    
    func toggleFilterView(forceClose: Bool = false) {
        if forceClose {
            filterViewIsVisible = false
        } else {
            filterViewIsVisible.toggle()
        }
        filterViewLeadingConstraint.constant = filterViewIsVisible ? -filterViewWidthConstraint.constant : 5
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { _ in }
    }
    
    @IBAction func filterButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        view.endEditing(true)
        toggleFilterView()
    }
    
    @IBAction func filterClearButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let allFilterRows = filterStackView.arrangedSubviews.compactMap({ $0 as? FilterRow })
        let allCreatorFilterRow = allFilterRows.first(where: { $0.type == .all })!
        allCreatorFilterRow.selectionButton.isSelected = true
        let archivedFilterRow = allFilterRows.first(where: { $0.type == .archived })
        archivedFilterRow?.selectionButton.isSelected = false
        filterSelected(by: allCreatorFilterRow, shouldForceRedraw: true)
    }
    
    @IBAction func sortByButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let sortByPickerMenu = UIAlertController(title: nil, message: "Sort by", preferredStyle: .actionSheet)
        let sortBy = SortByType.fetchSavedType()
        let recentlyUpdatedAction = UIAlertAction(title: "\(sortBy == .recentlyUpdated ? "    " : "")\(SortByType.recentlyUpdated.label)\(sortBy == .recentlyUpdated ? " ✓" : "")", style: .default) { _ in
            UserDefaults.standard.set(SortByType.recentlyUpdated.rawValue, forKey: sortByUserDefaultsKey)
            self.sortByButton.setTitle(SortByType.recentlyUpdated.label, for: .normal)
            self.applySearchAndFilters(userTriggered: true)
        }
        sortByPickerMenu.addAction(recentlyUpdatedAction)
        let purchaseDateAction = UIAlertAction(title: "\(sortBy == .purchaseDate ? "    " : "")\(SortByType.purchaseDate.label)\(sortBy == .purchaseDate ? " ✓" : "")", style: .default) { _ in
            UserDefaults.standard.set(SortByType.purchaseDate.rawValue, forKey: sortByUserDefaultsKey)
            self.sortByButton.setTitle(SortByType.purchaseDate.label, for: .normal)
            self.applySearchAndFilters(userTriggered: true)
        }
        sortByPickerMenu.addAction(purchaseDateAction)
        
        if let popoverController = sortByPickerMenu.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = [.up]
        }
        self.present(sortByPickerMenu, animated: true, completion: nil)
    }
    
    func updateRecentlyViewedProducts(with product: Product) {
        if let productId = product.url_redirect_external_id {
            let updatedRecentlyViewedProductIds: [String]
            if recentlyViewedProductIds.contains(productId) {
                updatedRecentlyViewedProductIds = [productId] + recentlyViewedProductIds.filter { $0 != productId }
            } else {
                updatedRecentlyViewedProductIds = [productId] + recentlyViewedProductIds
            }
            recentlyViewedProductIds = Array(updatedRecentlyViewedProductIds.prefix(5))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.productCarouselCell.scrollToTop()
        }
    }
    
    func productCarouselItemClicked(for product: Product) {
        if filterViewIsVisible {
            toggleFilterView(forceClose: true)
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showProduct(product: product)
    }

    func showProduct(product: Product) {
        let vc = ProductViewController.instantiate()
        vc.product = product
        vc.moreLikeThisEnabledForUser = moreLikeThisEnabledForUser
        updateRecentlyViewedProducts(with: product)
        navigationController?.pushViewController(vc, animated: true)
    }

    func attemptShowingProductForSavedUrlRedirectToken() {
        // Present the product that the user is trying to open in the app via the smart app banner on web
        if !allProducts.isEmpty,
            let urlRedirectToken = CoreDataManager.shared.getUrlRedirectToken() {
            logEvent("deep_link_attempt_open_product")
            if let product = self.allProducts.first(where: { $0.url_redirect_token == urlRedirectToken }) {
                logEvent("deep_link_open_product_successful")
                CoreDataManager.shared.clearUrlRedirectToken()
                self.showProduct(product: product)
            }
        }
    }
    
    func showOptions(for product: Product) {
        guard let isArchivedNumber = product.is_archived else { return }
        let isArchived = isArchivedNumber == 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        func archiveProduct() {
            guard let purchaseId = product.purchase_id else { return }
            GRDNetworkRequest.shared.archiveProduct(purchaseId, successBlock: {
                product.archive(true) {
                    self.refreshLocalData(hasRefreshedNetwork: false, autoScrollAfterComplete: false)
                }
            }, failureBlock: { error in
                print(error.localizedDescription)
            })
        }
        
        func unarchiveProduct() {
            guard let purchaseId = product.purchase_id else { return }
            GRDNetworkRequest.shared.unarchiveProduct(purchaseId, successBlock: {
                product.archive(false) {
                    self.refreshLocalData(hasRefreshedNetwork: false, autoScrollAfterComplete: false)
                }
            }, failureBlock: { error in
                print(error.localizedDescription)
            })
        }
        
        let optionsMenu: UIAlertController
        if UIDevice.current.userInterfaceIdiom == .pad {
            optionsMenu = UIAlertController(title: nil, message: isArchived ? "Unarchive from library" : "Archive from library", preferredStyle: .alert)
            optionsMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            optionsMenu.addAction(UIAlertAction(title: "Ok", style: isArchived ? .default : .destructive, handler: { _ in
                isArchived ? unarchiveProduct() : archiveProduct()
            }))
        } else {
            optionsMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let archiveAction = UIAlertAction(title: isArchived ? "Unarchive from library" : "Archive from library", style: isArchived ? .default : .destructive) { _ in
                isArchived ? unarchiveProduct() : archiveProduct()
            }
            optionsMenu.addAction(archiveAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            optionsMenu.addAction(cancelAction)
        }
        present(optionsMenu, animated: true) {
            if optionsMenu.preferredStyle == .actionSheet &&
                (UIApplication.shared.delegate as? GRDAppDelegate)?.isMiniPlayerShown() ?? false {
                UIView.animate(withDuration: 0.5) {
                    optionsMenu.view.transform = CGAffineTransform(translationX: 0, y: -MiniPlayerView.getHeight())
                }
            }
        }
    }
    
    @IBAction func settingsButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let settingsView = UIHostingController(rootView: SettingsUIView(onLogoutCompleted: { self.dismiss(animated: false)}))
        self.present(settingsView , animated: true, completion: nil)
    }
}

extension LibraryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        toggleFilterView(forceClose: true)
        self.searchText = searchText == "" ? nil : searchText
        applySearchAndFilters(userTriggered: true)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        toggleFilterView(forceClose: true)
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return skeletonView.isHidden ? (productsToShow.count + 2) : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            productCarouselCell.configure(products: recentlyViewedProducts)
            return productCarouselCell
        } else if indexPath.row == 1 {
            return resultsCell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.identifier) as? ProductTableViewCell else {
            fatalError("The nib is not an instance of \(ProductTableViewCell.identifier).")
        }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.configure(with: productsToShow[indexPath.row - 2])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filterViewIsVisible {
            toggleFilterView(forceClose: true)
            return
        }
        if [0, 1].contains(indexPath.row) {
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let product = productsToShow[indexPath.row - 2]
        showProduct(product: product)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return productCarouselCellHeight
        } else if indexPath.row == 1 {
            return resultsCellHeight
        } else {
            return productCellHeight
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
        toggleFilterView(forceClose: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshControl.alpha = min(1, max(0, (-scrollView.contentOffset.y - 20) / 40))
        spinnerImageViewHeightConstraint.constant = 10 + (refreshControl.alpha * 20)
    }
}

enum SortByType: String, CaseIterable {
    case recentlyUpdated = "recently_updated"
    case purchaseDate = "purchase_date"
    
    static func fetchSavedType() -> SortByType {
        let defaultSortBy = SortByType.recentlyUpdated
        let savedSortByValue = UserDefaults.standard.string(forKey: sortByUserDefaultsKey) ?? defaultSortBy.rawValue
        return SortByType(rawValue: savedSortByValue) ?? defaultSortBy
    }
    
    var label: String {
        switch self {
        case .recentlyUpdated:
            return "Recently Updated"
        case .purchaseDate:
            return "Purchase Date"
        }
    }
}
