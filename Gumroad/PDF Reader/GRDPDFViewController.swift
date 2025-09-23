//
//  GRDPDFViewController.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 2/19/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import UIKit
import PSPDFKitUI

class GRDPDFViewController: PDFViewController, PDFViewControllerDelegate {
    @objc var file: File?
    var pageCount: Int = 0
    
    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let file = file,
           let resumeLocation = file.resume_location,
           let contentLength = file.content_length {
            if Int(truncating: resumeLocation) >= Int(truncating: contentLength) {
                pageIndex = 0
            } else {
                let resumeLocationUInt = UInt(truncating: resumeLocation)
                pageIndex = resumeLocationUInt > 0 ? resumeLocationUInt - 1 : 0
            }
        }
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        file?.updateResumeLocation(Int(pageIndex) + 1)
    }
    
    // MARK: - Initializers
    
    override init(document: Document!, configuration: PDFConfiguration!) {
        super.init(document: document, configuration: configuration)
        self.delegate = self
        self.view.accessibilityLabel = "pdfReaderView"
        self.pageCount = Int(document.pageCount)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Rotation logic
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait, .landscapeLeft, .landscapeRight]
    }
}
