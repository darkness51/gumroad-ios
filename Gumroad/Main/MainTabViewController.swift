//
//  MainTabViewController.swift
//  iOSCreator
//
//  Created by Nathan Chan on 10/2/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit

class MainTabViewController: UITabBarController, UITabBarControllerDelegate, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .main
    
    var showCreatorVCs = false
    
    var loadingView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .black
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .gumroadGray
        itemAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.gumroadGray,
            NSAttributedString.Key.font: UIFont(name: "Mabry Pro", size: 12) ?? UIFont.systemFont(ofSize: 12)]
        itemAppearance.selected.iconColor = .gumroadPink
        itemAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.gumroadPink,
            NSAttributedString.Key.font: UIFont(name: "Mabry Pro", size: 12) ?? UIFont.systemFont(ofSize: 12)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        self.tabBar.scrollEdgeAppearance = appearance
        self.tabBar.standardAppearance = appearance
        
        if showCreatorVCs {
            if let viewController = UIStoryboard(name: "Creator", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                viewController.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "home-tab-unselected"), selectedImage: UIImage(named: "home-tab-selected"))
                self.viewControllers = self.viewControllers.appendOrInitialize(viewController)
            }
            if let viewController = UIStoryboard(name: "Creator", bundle: nil).instantiateViewController(withIdentifier: "AnalyticsViewController") as? AnalyticsViewController {
                viewController.tabBarItem = UITabBarItem(title: "Analytics", image: UIImage(named: "analytics-tab-unselected"), selectedImage: UIImage(named: "analytics-tab-selected"))
                self.viewControllers = self.viewControllers.appendOrInitialize(viewController)
            }
        }
        
        if let viewController = UIStoryboard(name: "Library", bundle: nil).instantiateViewController(withIdentifier: "LibraryViewController") as? LibraryViewController {
            viewController.tabBarItem = UITabBarItem(title: "Library", image: UIImage(named: "library-tab-unselected"), selectedImage: UIImage(named: "library-tab-selected"))
            self.viewControllers = self.viewControllers.appendOrInitialize(viewController)
        }
        
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.88)
        loadingView.frame = self.view.bounds
        
        let spinnerImageView = UIImageView(image: UIImage(named: "spinner"))
        let spinnerRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        spinnerRotateAnimation.fromValue = 0.0
        spinnerRotateAnimation.toValue = CGFloat(.pi * 2.0)
        spinnerRotateAnimation.duration = 1
        spinnerRotateAnimation.repeatCount = .greatestFiniteMagnitude
        spinnerRotateAnimation.isRemovedOnCompletion = false
        spinnerImageView.layer.add(spinnerRotateAnimation, forKey: nil)
        
        loadingView.addSubview(spinnerImageView)
        spinnerImageView.translatesAutoresizingMaskIntoConstraints = false
        spinnerImageView.widthAnchor.constraint(equalToConstant: 75).isActive = true
        spinnerImageView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        spinnerImageView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor).isActive = true
        spinnerImageView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor).isActive = true
        
        self.view.addSubview(loadingView)
        
        loadingView.isHidden = true
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if let index = tabBar.items?.firstIndex(of: item) {
            if index == self.selectedIndex,
               let discoverViewController = viewControllers?[index] as? DiscoverViewController {
                discoverViewController.scrollToTop()
            }
        }
    }
}
