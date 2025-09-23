//
//  UIScrollViewExtensions.swift
//  iOSCreator
//
//  Created by Nathan Chan on 3/24/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit

extension UIScrollView {
    fileprivate static func make() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isDirectionalLockEnabled = true
        return scrollView
    }

    static func makeHorizontal(with horizontalControllers: [UIViewController], in parent: UIViewController) -> UIScrollView {
        let scrollView = UIScrollView.make()

        let width = UIScreen.main.bounds.width
        let height: CGFloat
        if let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first {
            height = UIScreen.main.bounds.height - window.safeAreaInsets.top - window.safeAreaInsets.bottom
        } else {
            height = UIScreen.main.bounds.height
        }

        func add(_ child: UIViewController, withOffset offset: CGFloat) {
            parent.addChild(child)
            scrollView.addSubview(child.view)
            child.didMove(toParent: parent)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                child.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                child.view.heightAnchor.constraint(equalToConstant: height),
                child.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: offset)
                ])
        }

        scrollView.contentSize = CGSize(width: width * CGFloat(horizontalControllers.count), height: height)

        for (index, controller) in horizontalControllers.enumerated() {
            let xPosition = CGFloat(index) * width
            add(controller, withOffset: xPosition)
        }

        return scrollView
    }
}
