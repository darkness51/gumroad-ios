//
//  DiscoverCollectionView.swift
//  Gumroad
//
//  Created by Nathan Chan on 4/18/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI
import StoreKit

struct DiscoverCollectionView: View {
    @SwiftUI.Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var onProductClick: ((DiscoverProduct) -> Void)?
    var tabBarController: MainTabViewController?
    
    @State private var isFirstLoad = true
    @State private var isLoading = false
    @State private var isLoadingMoreStaffPicks = false
    @State private var noMoreStaffPicksToLoad = false
    @State private var staffPicksLastLoadedPage = 1
    @State var productsToDisplay: [DiscoverProduct] = []
    @State var productsToDisplayType = DiscoverProductsToDisplayType.recommended
    @State var lastFetchedRecommendedProducts: [DiscoverProduct] = []
    @State var storeProducts: [StoreKit.Product] = []
    @StateObject private var store = Store()
    @State private var searchText = ""
    @State private var lastSearchQuery = ""
    @State private var isShowingCategoryDrawer = false
    @State private var isShowingFilterDrawer = false
    @State var allCategories: [DiscoverCategory] = []
    @State var selectedCategory: DiscoverCategory? {
        didSet {
            searchText = ""
            performSearch(query: searchText)
        }
    }
    @State var lastSelectedCategory: DiscoverCategory?
    @State var displayedCategoryForDrawer: DiscoverCategory?
    @State var isMoreCategoriesSelected = false
    @State var allTags: [DiscoverTag] = []
    @State var allFiletypes: [DiscoverFileType] = []
    @State var hasFilters = false
    @State var shouldResetFilterView = false
    
    @State private var skeletonOpacity: Double = 1.0
    
    @ObservedObject var state: DiscoverCollectionViewState
    
    init(state: DiscoverCollectionViewState, tabBarController: MainTabViewController?) {
        self.state = state
        self.tabBarController = tabBarController
        _skeletonOpacity = State(initialValue: UITraitCollection.current.userInterfaceStyle == .dark ? 0.2 : 1.0)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SearchBar(text: $searchText, placeholder: selectedCategory == nil ? "Search for products" : "Search in \(selectedCategory!.label)", onSearch: performSearch)
                        .id("searchBar")
                        .padding(16)
                    
                    let categories = allCategories.filter({ $0.parentId == nil })
                    if categories.count > 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                PillButton(title: "All", isSelected: selectedCategory == nil && !isMoreCategoriesSelected) {
                                    isMoreCategoriesSelected = false
                                    selectedCategory = nil
                                }
                                ForEach(categories.prefix(5)) { category in
                                    PillButton(title: category.label, isSelected: selectedCategory == category && !isMoreCategoriesSelected) {
                                        isMoreCategoriesSelected = false
                                        selectedCategory = category
                                    }
                                }
                                PillButton(title: "More",
                                           imageName: "outline-chevron-down",
                                           isSelected: isMoreCategoriesSelected) {
                                    isMoreCategoriesSelected = true
                                    isShowingCategoryDrawer = true
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                    
                    HStack(spacing: 10) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                if let selectedCategory = selectedCategory {
                                    let breadcrumbCategoryIds: [String] = sequence(first: selectedCategory.id) { currentId in
                                        allCategories.first(where: { $0.id == currentId })?.parentId
                                    }.compactMap({ $0 }).reversed()
                                    
                                    ForEach(breadcrumbCategoryIds, id: \.self) { categoryId in
                                        let breadcrumbCategory = allCategories.first(where: { $0.id == categoryId })
                                        let hasSubCategories = Array(allCategories.filter({ $0.parentId == categoryId })).count > 0
                                        Text(breadcrumbCategory?.label ?? "")
                                            .underline(hasSubCategories)
                                            .onTapGesture {
                                                if hasSubCategories {
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    isMoreCategoriesSelected = false
                                                    displayedCategoryForDrawer = breadcrumbCategory
                                                    isShowingCategoryDrawer = true
                                                }
                                            }
                                        if categoryId != breadcrumbCategoryIds.last {
                                            Text("/")
                                        }
                                    }
                                } else {
                                    Text(productsToDisplayType.rawValue)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .font(Font.discoverCardTitleFont)
                            .foregroundColor(Color(UIColor.label))
                        }
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            isShowingFilterDrawer = true
                        }) {
                            Image(hasFilters ? "filter-on" : "filter-off")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.top, 16)
                    
                    if isLoading {
                        Image("skeleton-discover")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width)
                            .clipped()
                            .opacity(skeletonOpacity)
                            .onAppear {
                                skeletonOpacity = UITraitCollection.current.userInterfaceStyle == .dark ? 0.2 : 1.0 // required to reset animation
                                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                    skeletonOpacity = UITraitCollection.current.userInterfaceStyle == .dark ? 0.05 : 0.5
                                }
                            }
                    } else {
                        DiscoverProductGrid(products: productsToDisplay, onProductClick: onProductClick)
                        
                        if isLoadingMoreStaffPicks {
                            SpinnerView()
                                .scaleEffect(0.3)
                                .padding(.top, 5)
                                .padding(.bottom, 25)
                        } else if productsToDisplayType == .recommended && !noMoreStaffPicksToLoad {
                            Button(action: {
                                loadMoreStaffPicks()
                            }) {
                                Text(productsToDisplay.count ==  0 ? "Refresh" : "Load more")
                                    .font(Font.discoverCardButtonFont)
                                    .foregroundColor(Color(UIColor.label))
                                    .padding(.bottom, 17)
                            }
                        } else if productsToDisplayType == .search && productsToDisplay.count == 0 {
                            Text("No products found")
                                .font(Font.discoverCardButtonFont)
                                .foregroundColor(Color(UIColor.label))
                        }
                    }
                }
            }
            .onChange(of: state.scrollViewID) { _ in
                withAnimation {
                    proxy.scrollTo("searchBar", anchor: .top)
                }
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    dismissKeyboard()
                }
            )
            .onTapGesture {
                dismissKeyboard()
            }
        }
        .background(Color(UIColor(named: "GumroadTopViewColor")!))
        .overlay(
            CategoryDrawerView(isShowing: $isShowingCategoryDrawer,
                               isShowingMoreCategories: $isMoreCategoriesSelected,
                               selectedCategory: $selectedCategory,
                               displayedCategory: $displayedCategoryForDrawer,
                               allCategories: allCategories,
                               tabBarController: tabBarController)
        )
        .overlay(
            FilterDrawerView(isShowing: $isShowingFilterDrawer,
                             tags: $allTags,
                             filetypes: $allFiletypes,
                             shouldReset: $shouldResetFilterView,
                             tabBarController: tabBarController,
                             onApply: { minimumPrice, maximumPrice, selectedRatingMinimum, selectedTags, selectedFiletypes in
                                 hasFilters = !minimumPrice.isEmpty || !maximumPrice.isEmpty || selectedRatingMinimum > 0 || selectedTags.count > 0 || selectedFiletypes.count > 0
                                 performSearch(query: searchText, minimumPrice: minimumPrice, maximumPrice: maximumPrice, selectedRatingMinimum: selectedRatingMinimum, tags: selectedTags, filetypes: selectedFiletypes)
                             })
        )
        .onChange(of: isShowingCategoryDrawer) { newValue in
            if newValue {
                lastSelectedCategory = selectedCategory
                dismissKeyboard()
            } else {
                if lastSelectedCategory != selectedCategory {
                    searchText = ""
                    performSearch(query: searchText)
                }
                isMoreCategoriesSelected = false
            }
        }
        .onAppear {
            if isFirstLoad {
                isFirstLoad = false
                isLoading = true
                
                logEvent("discover_first_load")
                
                GRDNetworkRequest.shared.fetchCategories(successBlock: { categories in
                    self.allCategories = categories
                }, failureBlock: { _ in })
                
                refreshFilterMetadata()
                
                GRDNetworkRequest.shared.fetchRecommendedProducts(successBlock: { recommendedProducts in
                    GRDNetworkRequest.shared.fetchStaffPickedProducts(page: staffPicksLastLoadedPage, successBlock: { staffPickedProducts in
                        var products = (recommendedProducts + staffPickedProducts).removingDuplicates(by: \.id)
                        Task {
                            storeProducts = await store.fetchStoreKitProducts(for: products)
                            products.indices.forEach({ index in
                                products[index].prepareForDisplay(with: storeProducts)
                                products[index].recommendationType = recommendedProducts.contains(products[index]) ? .productsForYou : .staffPicks
                            })
                            self.productsToDisplay = products
                            lastFetchedRecommendedProducts = products
                            logEvent("discover_all_products_successful_load", params: ["count": products.count])
                            isLoading = false
                        }
                    }, failureBlock: { _ in
                        var products = recommendedProducts.removingDuplicates(by: \.id)
                        Task {
                            storeProducts = await store.fetchStoreKitProducts(for: products)
                            products.indices.forEach({ index in
                                products[index].prepareForDisplay(with: storeProducts)
                                products[index].recommendationType = .productsForYou
                            })
                            self.productsToDisplay = products
                            lastFetchedRecommendedProducts = products
                            logEvent("discover_recommended_successful_load", params: ["count": products.count])
                            isLoading = false
                        }
                    })
                }, failureBlock: { _ in
                    GRDNetworkRequest.shared.fetchStaffPickedProducts(page: staffPicksLastLoadedPage, successBlock: { staffPickedProducts in
                        var products = staffPickedProducts.removingDuplicates(by: \.id)
                        Task {
                            storeProducts = await store.fetchStoreKitProducts(for: products)
                            products.indices.forEach({ index in
                                products[index].prepareForDisplay(with: storeProducts)
                                products[index].recommendationType = .staffPicks
                            })
                            self.productsToDisplay = products
                            lastFetchedRecommendedProducts = products
                            logEvent("discover_staff_picks_successful_load", params: ["count": products.count])
                            isLoading = false
                        }
                    }, failureBlock: { _ in
                        self.productsToDisplay = []
                        lastFetchedRecommendedProducts = []
                        logEvent("discover_failed_load")
                        isLoading = false
                    })
                })
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func loadMoreStaffPicks() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isLoadingMoreStaffPicks = true
        staffPicksLastLoadedPage += 1
        
        GRDNetworkRequest.shared.fetchStaffPickedProducts(page: staffPicksLastLoadedPage, successBlock: { staffPickedProducts in
            var products = staffPickedProducts.removingDuplicates(by: \.id)
            Task {
                storeProducts = await store.fetchStoreKitProducts(for: products)
                products.indices.forEach({ index in
                    products[index].prepareForDisplay(with: storeProducts)
                    products[index].recommendationType = .staffPicks
                })
                self.productsToDisplay.append(contentsOf: products)
                lastFetchedRecommendedProducts = productsToDisplay
                logEvent("discover_staff_picks_load_page_\(staffPicksLastLoadedPage)", params: ["count": products.count])
                isLoadingMoreStaffPicks = false
                noMoreStaffPicksToLoad = products.count == 0
            }
        }, failureBlock: { _ in
            logEvent("discover_failed_load_more_staff_picks")
            isLoadingMoreStaffPicks = false
        })
    }
    
    func refreshFilterMetadata() {
        GRDNetworkRequest.shared.productsSearch(query: "", tags: [], filetypes: [], successBlock: { searchContainer in
            allTags = searchContainer.tags
            allFiletypes = searchContainer.filetypes
        }, failureBlock: { _ in })
    }
    
    func performSearch(query: String) {
        shouldResetFilterView = true
        hasFilters = false
        performSearch(query: query, minimumPrice: "", maximumPrice: "", selectedRatingMinimum: 0, tags: [], filetypes: [])
    }
    
    func performSearch(query: String,
                       minimumPrice: String,
                       maximumPrice: String,
                       selectedRatingMinimum: Int,
                       tags: [DiscoverTag],
                       filetypes: [DiscoverFileType]) {
        lastSearchQuery = query
        
        if query.isEmpty && selectedCategory == nil && !isMoreCategoriesSelected && !hasFilters {
            isLoading = false
            productsToDisplay = lastFetchedRecommendedProducts
            productsToDisplayType = .recommended
            
            refreshFilterMetadata()
        } else {
            isLoading = true
            productsToDisplayType = .search
            
            GRDNetworkRequest.shared.productsSearch(query: query, taxonomyId: selectedCategory?.id, tags: tags, filetypes: filetypes, successBlock: { searchContainer in
                guard query == lastSearchQuery else { return }
                
                var products = searchContainer.products
                allTags = searchContainer.tags
                allFiletypes = searchContainer.filetypes
                Task {
                    storeProducts = await store.fetchStoreKitProducts(for: products)
                    products.indices.forEach({ index in
                        products[index].prepareForDisplay(with: storeProducts)
                        products[index].recommendationType = .search
                    })
                    productsToDisplay = products.filter({ product in
                        let minPrice = Int(minimumPrice) ?? 0
                        let maxPrice = Int(maximumPrice) ?? Int.max
                        let meetsRatingCriteria = selectedRatingMinimum == 0 || product.ratings.average >= Double(selectedRatingMinimum)
                        return product.priceInt >= minPrice && product.priceInt <= maxPrice && meetsRatingCriteria
                    })
                    logEvent("discover_search_query", params: ["query": query])
                    isLoading = false
                }
            }, failureBlock: { _ in
                guard query == lastSearchQuery else { return }
                
                logEvent("discover_search_failed")
                isLoading = false
            })
        }
    }
}

class DiscoverCollectionViewState: ObservableObject {
    @Published var scrollViewID = UUID()

    func scrollToTop() {
        scrollViewID = UUID()
    }
}

enum DiscoverProductsToDisplayType: String {
    case recommended = "Recommended for you"
    case search = "Search results"
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    var onSearch: (String) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Image("search")
                .foregroundColor(.gray)
                .padding(.leading, 14)
                .padding(.trailing, 5)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray))
                .font(Font.searchBarFont)
                .foregroundColor(Color(UIColor.label))
                .padding(.top, 15)
                .padding(.bottom, 14)
                .autocorrectionDisabled()
                .onChange(of: text) { newValue in
                    onSearch(newValue)
                }
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                    onSearch("")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 14)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(UIColor(named: "GumroadBorderColor") ?? .gray), lineWidth: 1)
        )
    }
}
