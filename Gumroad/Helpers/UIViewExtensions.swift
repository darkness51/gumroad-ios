//
//  UIViewExtensions.swift
//  iOSCreator
//
//  Created by Nathan Chan on 3/24/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit

extension UIView {
    func fit(to container: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topAnchor.constraint(equalTo: container.topAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
    }
}
