//
//  UIViewControllerExtensions.swift
//  Gumroad
//
//  Created by Nathan Chan on 9/9/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import Foundation
import SwiftUI

extension UIViewController {
    func setupLeftEdgeSwipeGesture() {
        let leftSwipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleLeftEdgeSwipe(_:)))
        leftSwipe.edges = .left
        view.addGestureRecognizer(leftSwipe)
    }
    
    @objc private func handleLeftEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended {
            handleLeftSwipe(gesture)
        }
    }
    
    @objc open func handleLeftSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        navigationController?.popViewController(animated: true)
    }
    
    func onBackClick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        navigationController?.popViewController(animated: true)
    }
    
    func onProductClick(product: DiscoverProduct) {
        guard let navigationController = navigationController else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var productView = DiscoverProductView(product: product)
        productView.onBackClick = onBackClick
        productView.onSellerClick = onSellerClick
        productView.onProductClick = onProductClick
        let hostingController = UIHostingController(rootView: productView)
        hostingController.view.backgroundColor = .black
        hostingController.setupLeftEdgeSwipeGesture()
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func onSellerClick(seller: DiscoverProductSeller, recommendationType: DiscoverRecommendationType?) {
        guard let navigationController = navigationController else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var sellerView = DiscoverSellerView(seller: seller, recommendationType: recommendationType)
        sellerView.onBackClick = onBackClick
        sellerView.onProductClick = onProductClick
        let hostingController = UIHostingController(rootView: sellerView)
        hostingController.view.backgroundColor = .black
        hostingController.setupLeftEdgeSwipeGesture()
        navigationController.pushViewController(hostingController, animated: true)
    }
}
