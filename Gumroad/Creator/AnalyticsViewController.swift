//
//  AnalyticsViewController.swift
//  iOSCreator
//
//  Created by Nathan Chan on 3/22/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit
import SwiftUI

class AnalyticsViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .creator
    
    @IBOutlet weak var analyticsTitleLabel: UILabel!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var headerSalesButton: UIButton!
    @IBOutlet weak var headerTrafficButton: UIButton!
    private var mainScrollView: UIScrollView!
    
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
        bottomBorder.frame = CGRect(x: 0, y: topView.frame.size.height - 1, width: topView.frame.size.width, height: 1)
        bottomBorder.borderWidth = 1
        topView.layer.addSublayer(bottomBorder)
        topView.layer.masksToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.orientation.isLandscape {
            updateHeaderSelection(selectedIndex: 0) // this view is disabled in landscape mode, so this is for handling weird UI when navigating back here in landscape mode
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mainScrollView = UIScrollView.makeHorizontal(
            with: [SalesViewController.instantiate(), TrafficViewController.instantiate()],
            in: self
        )
        mainView.addSubview(mainScrollView)
        mainScrollView.fit(to: mainView)
        mainScrollView.isScrollEnabled = false
    }
    
    @IBAction func headerButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateHeaderSelection(selectedIndex: sender == headerSalesButton ? 0 : 1)
    }
    
    func updateHeaderSelection(selectedIndex: Int) {
        headerSalesButton.isSelected = selectedIndex == 0
        headerTrafficButton.isSelected = selectedIndex == 1
        let mainScrollOffset = CGPoint(x: mainScrollView.bounds.width * CGFloat(selectedIndex), y: 0)
        mainScrollView.setContentOffset(mainScrollOffset, animated: true)
    }

    @IBAction func settingsButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let settingsView = UIHostingController(rootView: SettingsUIView(onLogoutCompleted: { self.dismiss(animated: false)}))
        self.present(settingsView , animated: true, completion: nil)
    }
}
