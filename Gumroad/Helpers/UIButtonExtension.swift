//
//  UIButtonExtension.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/13/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

extension UIButton {
    func setImage(fromUrl url: URL, for state: UIControl.State, placeholderImage: UIImage?) {
        let theTask = URLSession.shared.dataTask(with: url) { data, response, _ in
            if let response = data {
                DispatchQueue.main.async {
                    self.setImage(UIImage(data: response), for: state)
                }
            } else {
                self.setImage(placeholderImage, for: state)
            }
        }
        theTask.resume()
    }
}
