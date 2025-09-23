//
//  LaunchViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/15/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if GRDNetworkRequest.shared.currentUserAccount == nil {
            presentNavVC(with: LoginViewController.instantiate())
        } else {
            let vc = MainTabViewController.instantiate()
            GRDNetworkRequest.shared.fetchProducts(successBlock: { [self] (response, responseObject) -> Void in
                if let data = responseObject as? [String: Any],
                   let products = data["products"] as? NSArray,
                   products.count > 0 {
                    vc.showCreatorVCs = true
                }
                presentNavVC(with: vc)
            }, failureBlock: { [self] (error) -> Void in
                print("fetchProducts error: \(error.localizedDescription)")
                presentNavVC(with: vc)
            })
        }
    }
    
    func presentNavVC(with rootViewController: UIViewController) {
        let navVC = GRDNavigationViewController(rootViewController: rootViewController)
        navVC.modalPresentationStyle = .fullScreen
        navVC.modalTransitionStyle = .crossDissolve
        present(navVC, animated: true, completion: nil)
    }
}
