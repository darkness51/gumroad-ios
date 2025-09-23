//
//  NotificationView.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/30/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class NotificationView: UIView {
    enum NotificationType {
        case success
        case error
    }
    
    convenience init(width: CGFloat, text: String, type: NotificationType) {
        self.init()
        
        widthAnchor.constraint(equalToConstant: width).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = type == .success ? .gumroadGreen : .gumroadRed
        layer.cornerRadius = 4
        
        let warningImage = UIImageView(image: UIImage(named: type == .success ? "success" : "warning"))
        addSubview(warningImage)
        warningImage.translatesAutoresizingMaskIntoConstraints = false
        warningImage.widthAnchor.constraint(equalToConstant: 15).isActive = true
        warningImage.heightAnchor.constraint(equalToConstant: 15).isActive = true
        warningImage.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        warningImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "Mabry Pro", size: 13)
        label.textColor = .white
        label.numberOfLines = 0
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: warningImage.trailingAnchor, constant: 10).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        label.topAnchor.constraint(equalTo: warningImage.topAnchor).isActive = true
    }
    
    func animate(from view: UIView) {
        view.subviews.filter({ $0 is NotificationView }).forEach({ $0.removeFromSuperview() })
        
        alpha = 0
        view.addSubview(self)
        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        let bottomAnchor = self.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        bottomAnchor.isActive = true
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            bottomAnchor.constant = self.frame.height + 20
            self.alpha = 1
            view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.5, options: .curveEaseOut, animations: {
                bottomAnchor.constant = 0
                self.alpha = 0
                view.layoutIfNeeded()
            }, completion: { _ in
                self.removeFromSuperview()
            })
        })
        
    }
}
