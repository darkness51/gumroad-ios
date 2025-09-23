//
//  ProductSaleTableViewCell.swift
//  iOSCreator
//
//  Created by Nathan Chan on 10/3/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit

class ProductSaleTableViewCell: UITableViewCell {

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var salePriceLabel: UILabel!
    @IBOutlet weak var customerEmailLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    
    static var identifier = "ProductSaleTableViewCell"

    func configure(productName: String, price: String, customerEmail: String, timestamp: String, thumbnailURL: String?, isRefunded: Bool, isPartiallyRefunded: Bool, isChargedback: Bool, isInAppPurchase: Bool) {
        let placeholderImage = UIImage(named: "product-placeholder-small")
        if let thumbnailURL = thumbnailURL,
            let imageURL = URL(string: thumbnailURL) {
            self.productImageView.setImageWith(imageURL, placeholderImage: placeholderImage)
        } else {
            self.productImageView.image = placeholderImage
        }
        self.productImageView.clipsToBounds = true
        self.productImageView.layer.cornerRadius = 0
        
        let borderWidth = 0.25
        let leftBorder = CALayer()
        leftBorder.backgroundColor = UIColor(named: "GumroadLabelColor")?.cgColor
        leftBorder.frame = CGRect(x: 0, y: 0, width: borderWidth, height: self.productImageView.frame.height)
        self.productImageView.layer.addSublayer(leftBorder)
        let rightBorder = CALayer()
        rightBorder.backgroundColor = UIColor(named: "GumroadLabelColor")?.cgColor
        rightBorder.frame = CGRect(x: self.productImageView.frame.width - borderWidth, y: 0, width: borderWidth, height: self.productImageView.frame.height)
        self.productImageView.layer.addSublayer(rightBorder)

        productNameLabel.text = productName
        salePriceLabel.text = price
        customerEmailLabel.text = customerEmail
        timestampLabel.text = timestamp
        
        tagLabel.isHidden = !(isInAppPurchase || isRefunded || isPartiallyRefunded || isChargedback)
        tagLabel.clipsToBounds = true
        tagLabel.layer.cornerRadius = 4
        tagLabel.layer.borderColor = UIColor(named: "GumroadBorderColor")?.cgColor
        tagLabel.layer.borderWidth = 1.0
        tagLabel.text = "  \(isInAppPurchase ? "In-App" : (isRefunded ? "Refunded" : (isPartiallyRefunded ? "Partially refunded" : "Chargedback")))  "
    }
}
