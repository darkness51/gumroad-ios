//
//  GRDNavigationViewController.swift
//  Gumroad
//
//  Created by Matthew Whittaker on 10/20/19.
//  Copyright © 2019 Gumroad. All rights reserved.
//

import UIKit
import QuickLook
import AVKit
import SwiftUI

class GRDNavigationViewController : UINavigationController {
    
    var gradientLayer : CAGradientLayer?
    var originalStatusBarHeight : CGFloat?
    var allowLandscapeOverride = false
    
    var previousContentOffset : CGPoint = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        edgesForExtendedLayout = []
        navigationBar.isHidden = true
        modalPresentationStyle = .currentContext
        interactivePopGestureRecognizer?.delegate = self
    }
    
    func popViewController() {
        popViewController(animated: true)
    }
    
    deinit {
        delegate = nil
        interactivePopGestureRecognizer?.delegate = nil
    }
    
}

// MARK: - Orientation and rotation logic

extension GRDNavigationViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        topViewController is LoginViewController ||
        topViewController is GRDEPubPageViewController ||
        topViewController is GRDPDFViewController ||
        topViewController is LibraryViewController ||
        topViewController is InstallmentViewController
            ? .default
            : (topViewController is LaunchViewController ? .darkContent : .lightContent)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .slide
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let topViewController = topViewController as? MainTabViewController,
               (topViewController.selectedViewController is HomeViewController ||
                topViewController.selectedViewController is AnalyticsViewController ||
                topViewController.selectedViewController is DiscoverViewController) { // don't support landscape mode for the creator or discover views due to complexities of re-drawing the custom scroll view used for the analytics charts and discover collection view
                return [.portrait]
            } else if topViewController is UIHostingController<DiscoverProductView> ||
                      topViewController is UIHostingController<DiscoverSellerView> { // don't support landscape mode for inner discover SwiftUI views
                return [.portrait]
            }
            return [.portrait, .landscapeLeft, .landscapeRight]
        } else if let topController = topViewController, viewControllerIsAllowedToRotate(topController) {
            return [.portrait, .landscapeLeft, .landscapeRight]
        }
        return [.portrait]
    }
    
    override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? false
    }
    
    func viewControllerIsAllowedToRotate(_ viewController: UIViewController) -> Bool {
        return (
            viewController is GRDPDFViewController ||
            viewController is QLPreviewController ||
            viewController is AVPlayerViewController ||
            viewController is GRDEPubPageViewController
        )
    }
}

// MARK: - UINavigationControllerDelegate

extension GRDNavigationViewController : UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if gradientLayer != nil {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
        }
        
        navigationBar.isTranslucent = true
        navigationBar.tintColor = .label
        
        switch viewController {
        case is QLPreviewController:
            setNavigationBarHidden(false, animated: true)
            navigationBar.setBackgroundImage(nil, for: .default)
            navigationBar.shadowImage = nil
            navigationBar.barStyle = .black
            navigationBar.isTranslucent = true
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        case is GRDEPubPageViewController:
            setNavigationBarHidden(false, animated: true)
            navigationBar.setBackgroundImage(nil, for: .default)
            navigationBar.shadowImage = nil
            navigationBar.tintColor = .gumroadGray400
            navigationBar.isTranslucent = false
            navigationBar.barStyle = .default
        default:
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            setNavigationBarHidden(false, animated: true)
            createNavigationBarBackgroundImage(with: [UIColor.black.withAlphaComponent(0.2).cgColor, UIColor.clear.cgColor])
        }
    }
    
    func createNavigationBarBackgroundImage(with colors: [CGColor]) {
        let gradientLayer = CAGradientLayer()
        var updatedFrame = navigationBar.bounds
        updatedFrame.size.height += view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        gradientLayer.frame = updatedFrame
        gradientLayer.colors = colors

        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension GRDNavigationViewController : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
}
