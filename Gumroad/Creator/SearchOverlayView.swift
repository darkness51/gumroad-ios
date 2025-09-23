import UIKit

protocol SearchOverlayDelegate: AnyObject {
    func searchOverlay(_ overlay: SearchOverlayView, didSelectPurchase purchase: [String: String])
    func searchOverlayDidCancel(_ overlay: SearchOverlayView)
}

class SearchOverlayView: UIView {

    private let searchBar = UISearchBar()
    private var originalTableView: UITableView?
    private var originalDataSource: UITableViewDataSource?
    private var originalDelegate: UITableViewDelegate?
    private var allPurchases: [[String: String]] = []
    private var filteredPurchases: [[String: String]] = []
    private var topViewToHide: UIView?
    private var originalParentView: UIView?
    private var originalTableViewConstraints: [NSLayoutConstraint] = []
    private var loadingSpinner: UIActivityIndicatorView!
    private var searchTimer: Timer?
    private var noSalesLabel: UILabel!

    weak var delegate: SearchOverlayDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor(named: "GumroadTopViewColor")

        // Setup search bar
        searchBar.delegate = self
        searchBar.searchTextField.font = UIFont(name: "Mabry Pro", size: 14)
        searchBar.searchTextField.backgroundColor = UIColor.systemBackground
        searchBar.searchTextField.textColor = UIColor.label
        searchBar.searchTextField.layer.borderWidth = 1
        searchBar.searchTextField.layer.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        searchBar.searchTextField.layer.cornerRadius = 4
        searchBar.searchTextField.clipsToBounds = true
        let searchImage = UIImage(named: "search")
        searchBar.setImage(searchImage, for: .search, state: .normal)
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor.clear
        searchBar.barTintColor = UIColor.clear
        searchBar.placeholder = "Type to find purchases..."
        searchBar.showsCancelButton = false

        // Setup loading spinner
        loadingSpinner = UIActivityIndicatorView(style: .medium)
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.color = UIColor.label

        // Setup no sales label
        noSalesLabel = UILabel()
        noSalesLabel.text = "No sales found"
        noSalesLabel.textAlignment = .center
        noSalesLabel.textColor = UIColor.secondaryLabel
        noSalesLabel.font = UIFont(name: "Mabry Pro", size: 16)
        noSalesLabel.isHidden = true

        // Add subviews
        addSubview(searchBar)
        addSubview(loadingSpinner)
        addSubview(noSalesLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        noSalesLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

                        loadingSpinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            noSalesLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noSalesLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            noSalesLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            noSalesLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    func show(in parentView: UIView, with purchases: [[String: String]], tableView: UITableView, topView: UIView) {
        allPurchases = purchases
        filteredPurchases = purchases

        // Store references to original table view setup
        originalTableView = tableView
        originalDataSource = tableView.dataSource
        originalDelegate = tableView.delegate
        topViewToHide = topView
        originalParentView = tableView.superview

        // Store all original constraints that involve the table view
        if let parentView = originalParentView {
            originalTableViewConstraints = parentView.constraints.filter { constraint in
                constraint.firstItem === tableView || constraint.secondItem === tableView
            }
        }

        // Hide the top view (revenue section and time selectors)
        topView.isHidden = true

        // Replace table view data source and delegate temporarily
        tableView.dataSource = self
        tableView.delegate = self

        parentView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        // Position the overlay to fill from navigation bar to bottom (above tab bar)
        if let navController = parentView.findViewController()?.navigationController {
            let navBar = navController.navigationBar
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 6),
                leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
            ])
        } else {
            // Fallback positioning
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor),
                leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
            ])
        }

        // Move the table view to be a child of this search overlay and position it correctly
        setupTableViewInOverlay(tableView: tableView)

        alpha = 1

        // Focus search bar
        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
        }

        updateUIState()
    }

    private func setupTableViewInOverlay(tableView: UITableView) {
        // Remove table view from its current parent and add to overlay
        tableView.removeFromSuperview()
        addSubview(tableView)

        // Set up table view constraints within the search overlay
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateUIState() {
        guard let tableView = originalTableView else { return }

        let isEmpty = filteredPurchases.isEmpty
        let isLoading = loadingSpinner.isAnimating

        // Show/hide elements based on state
        tableView.isHidden = isEmpty || isLoading
        noSalesLabel.isHidden = !isEmpty || isLoading

        // Bring spinner to front to ensure it's visible
        if isLoading {
            bringSubviewToFront(loadingSpinner)
        }

        tableView.reloadData()
    }

    func hide() {
        // Cancel any ongoing search timer
        searchTimer?.invalidate()
        searchTimer = nil
        loadingSpinner.stopAnimating()

        // Restore original table view setup
        if let tableView = originalTableView,
           let originalParent = originalParentView {

            // Remove table view from overlay and add back to original parent
            tableView.removeFromSuperview()
            originalParent.addSubview(tableView)

            // Restore original constraints
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(originalTableViewConstraints)

            // Restore original data source and delegate
            tableView.dataSource = originalDataSource
            tableView.delegate = originalDelegate
            tableView.isHidden = false
            tableView.reloadData()
        }

        // Show the top view again
        topViewToHide?.isHidden = false

        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }

    private func performSearch(query: String) {
        // Cancel previous timer
        searchTimer?.invalidate()

        if query.isEmpty {
            // Show initial data when search is empty
            filteredPurchases = allPurchases
            loadingSpinner.stopAnimating()
            updateUIState()
            return
        }

        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.executeAPISearch(query: query)
        }
    }

    private func executeAPISearch(query: String) {
        loadingSpinner.startAnimating()
        updateUIState()

        // Always use "Alltime" range for search
        let timeRange = GRDCreatorDataHandler.TimeRange.Alltime

        GRDNetworkRequest.shared.fetchCreatorAnalytics(
            timeRange.rawValue,
            query: query,
            successBlock: { [weak self] (response, responseObject) -> Void in
                DispatchQueue.main.async {
                    self?.loadingSpinner.stopAnimating()

                    guard let data = responseObject as? [String: Any],
                          let purchasesNSArray = data["purchases"] as? NSArray else {
                        self?.filteredPurchases = []
                        self?.updateUIState()
                        return
                    }

                    self?.filteredPurchases = GRDCreatorDataHandler.parsePurchases(purchasesNSArray)
                    self?.updateUIState()
                }
            },
            failureBlock: { [weak self] (error) -> Void in
                DispatchQueue.main.async {
                    self?.loadingSpinner.stopAnimating()
                    // On error, show empty results
                    self?.filteredPurchases = []
                    self?.updateUIState()
                }
            }
        )
    }

    // Helper method from HomeViewController
    private func checkIsInAppPurchase(with purchaseData: [String: String]) -> Bool {
        if let inAppPurchasePlatform = purchaseData["in_app_purchase_platform"],
           !inAppPurchasePlatform.isEmpty {
            return true
        }
        return false
    }
}

// Extension to find view controller
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

extension SearchOverlayView: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension SearchOverlayView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPurchases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductSaleTableViewCell.identifier) as? ProductSaleTableViewCell else {
            fatalError("The nib is not an instance of \(ProductSaleTableViewCell.identifier).")
        }
        let purchaseData = filteredPurchases[indexPath.row]
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
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPurchase = filteredPurchases[indexPath.row]
        delegate?.searchOverlay(self, didSelectPurchase: selectedPurchase)
    }
}
