//
//  ContentSizedTableView.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/24/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class ContentSizedTableView: UITableView {
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
