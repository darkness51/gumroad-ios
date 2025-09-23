//
//  ImageViewerViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/15/21.
//  Copyright © 2021 Gumroad. All rights reserved.
//

import UIKit

class ImageViewerViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .imageViewer
    
    @IBOutlet weak var imageView: UIImageView!
    
    var file: File?
    var documentController: UIDocumentInteractionController?
    var isPresentedModally = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let downloadUrl = file?.bestAvailableUrl() {
            imageView.setImageWith(downloadUrl)
        }
    }
    
    @IBAction func backButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isPresentedModally {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func shareButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        documentController = UIDocumentInteractionController()
        documentController?.url = file?.bestAvailableUrl()
        documentController?.delegate = self
        documentController?.name = file?.displayName()
        documentController?.annotation = file?.getAnalyticsParams()
        documentController?.presentOpenInMenu(from: view.frame, in: view, animated: true)
    }
}

extension ImageViewerViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        if var params = controller.annotation as? [String: Any] {
            params["application"] = application
            logEvent("file_shared_to_application", params: params)
        }
    }
}
