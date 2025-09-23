//
//  DiscoverViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 4/16/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import UIKit
import SwiftUI

class DiscoverViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .discover
    
    var discoverCollectionViewState = DiscoverCollectionViewState()
    
    @IBOutlet weak var discoverTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var collectionView = DiscoverCollectionView(state: discoverCollectionViewState, tabBarController: tabBarController as? MainTabViewController)
        collectionView.onProductClick = self.onProductClick
        let hostingController = UIHostingController(rootView: collectionView)
        hostingController.setupLeftEdgeSwipeGesture()
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: discoverTitleLabel.bottomAnchor, constant: 16).isActive = true
        
        let topBorder = UIView()
        topBorder.backgroundColor = UIColor(named: "GumroadBorderColor")
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(topBorder, at: 0)
        
        NSLayoutConstraint.activate([
            topBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBorder.topAnchor.constraint(equalTo: hostingController.view.topAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        setupLeftEdgeSwipeGesture()
    }
    
    @IBAction func settingsButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let settingsView = UIHostingController(rootView: SettingsUIView(onLogoutCompleted: { self.dismiss(animated: false)}))
        self.present(settingsView, animated: true, completion: nil)
    }
    
    func scrollToTop() {
        discoverCollectionViewState.scrollToTop()
    }
}
