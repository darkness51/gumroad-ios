//
//  GRDEPubPageViewController.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 2/18/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import UIKit
import KFEpubKit

class GRDEPubPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate {
    var epubController: KFEpubController?
    var epubContentModel: KFEpubContentModel?
    var pageIndex: Int = 1
    var file: File?
    var currentSectionId = ""
    var lastTrackedSectionId = ""
    static let newEpubSectionDisplayedNotificationCenterObserverName = "new_epub_section_displayed"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = false
        // Do any additional setup after loading the view.
        self.delegate = self
        self.dataSource = self
        self.edgesForExtendedLayout = []
        self.setNeedsStatusBarAppearanceUpdate()
        let navBarAttributesDictionary: [String : Any]? = [
            convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.rgb(red: 179, green: 179, blue: 179),
            convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "HelveticaNeue", size: 15)!
        ]
        self.navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary(navBarAttributesDictionary)
    
        var startingIndex = pageIndex
        if let file = self.file {
            self.title = file.displayName()
            if let resumeLocation = file.resume_location as? Int, resumeLocation != 0 {
                startingIndex = resumeLocation
            } else {
                startingIndex = 1
            }
        }
        if let epubViewController = epubViewControllerForIndex(startingIndex) {
            self.setViewControllers([epubViewController], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        }
        let customChevronBackButton = UIBarButtonItem(image: UIImage(named: "caret-left-white"), style: .plain, target: self, action: #selector(GRDEPubPageViewController.popViewController))
        customChevronBackButton.accessibilityLabel = "backToProductCollectionViewButton"
        self.navigationItem.leftBarButtonItem = customChevronBackButton
        for gr in self.gestureRecognizers {
            if gr is UITapGestureRecognizer {
                gr.delegate = self
            }
        }

        // This is necessary since otherwise we don't get notified when the user taps on an item within the table of content
        // and jumps to a different section.
        NotificationCenter.default.addObserver(self, selector: #selector(sectionChangedThroughTableOfContent), name: NSNotification.Name(rawValue: GRDEPubPageViewController.newEpubSectionDisplayedNotificationCenterObserverName), object: nil)
    }

    @objc func sectionChangedThroughTableOfContent(notification: NSNotification) {
        let sectionId = notification.object as! String
        self.currentSectionId = sectionId
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (otherGestureRecognizer is UITapGestureRecognizer) {
            return true
        }
        return false
    }
    
    @objc func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate = nil
        self.dataSource = nil

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: GRDEPubPageViewController.newEpubSectionDisplayedNotificationCenterObserverName), object: nil)

        self.setFileResumeLocation()
    }

    class func notificationCenterObserverName() -> String {
        return newEpubSectionDisplayedNotificationCenterObserverName
    }
    
    // MARK: - UIPageViewControllerDataSource delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentEpubViewController = viewController as! GRDEPubViewController
        var newPageIndex = currentEpubViewController.pageIndex - 1
        if (newPageIndex < 1) {
            newPageIndex = 1
            return nil
        }
        return epubViewControllerForIndex(newPageIndex)
    }

    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentEpubViewController = viewController as! GRDEPubViewController
        let newPageIndex = currentEpubViewController.pageIndex + 1
        return epubViewControllerForIndex(newPageIndex)
    }
    
    // MARK: - Internal methods

    func epubViewControllerForIndex(_ currentIndex: Int) -> GRDEPubViewController? {
        var index = currentIndex
        if let contentModel = self.epubContentModel {
            let manifest = contentModel.manifest as NSDictionary
            let spine = contentModel.spine as NSArray
            if (index >= spine.count) {
                index = 1
            }
            let spineValue = spine[index] as! String
            if let manifestValue = manifest[spineValue] as? NSDictionary {
                let contentFile = manifestValue["href"] as! String
                let contentURL = self.epubController?.epubContentBaseURL.appendingPathComponent(contentFile)
                let epubViewController = GRDEPubViewController()
                epubViewController.epubContentModel = contentModel
                epubViewController.epubController = self.epubController
                epubViewController.epubContentUrl = contentURL!
                epubViewController.pageIndex = index
                epubViewController.file = self.file
                self.currentSectionId = spineValue
                if self.lastTrackedSectionId == "" {
                    // The reader has just opened the epub reader. Report the current page since the didFinishAnimating callback won't know about this.
                    self.lastTrackedSectionId = currentSectionId
                }
                return epubViewController
            }
        }

        return nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.fade
    }
    
    deinit {
        self.delegate = nil
        self.dataSource = nil
    }

    private func setFileResumeLocation() {
        if self.epubContentModel == nil {
            return
        }
        let spine = self.epubContentModel!.spine as NSArray
        let sectionIndex = spine.index(of: self.currentSectionId)
        self.file!.updateResumeLocation(sectionIndex)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
