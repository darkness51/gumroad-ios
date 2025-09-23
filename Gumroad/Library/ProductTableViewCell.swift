//
//  ProductTableViewCell.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/15/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {
    @IBOutlet weak var productImageOuterView: UIView!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productDescriptionLabel: UILabel!
    @IBOutlet weak var creatorImageOuterView: UIView!
    @IBOutlet weak var creatorImageView: UIImageView!
    @IBOutlet weak var creatorNameLabel: UILabel!
    
    static var identifier = "ProductTableViewCell"
    var product: Product?
    
    var delegate: ProductTableViewCellDelegate?
    
    func configure(with product: Product) {
        self.product = product
        
        let placeholderImage = UIImage(named: "product-placeholder-small")
        if let thumbnail_url = product.thumbnail_url,
            let imageURL = URL(string: thumbnail_url) {
            self.productImageView.setImageWith(imageURL, placeholderImage: placeholderImage)
        } else if let preview_url = product.preview_url,
            let imageURL = URL(string: preview_url) {
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
        
        let productNameLabelAttributedString = NSMutableAttributedString(string: product.name ?? "")
        productNameLabelAttributedString.addAttribute(.foregroundColor, value: UIColor(named: "GumroadLabelColor")!, range: NSRange(location: 0, length: productNameLabelAttributedString.length))
        self.productNameLabel.attributedText = productNameLabelAttributedString
        
        let creatorImageCornerRadius = self.creatorImageOuterView.frame.width / 2
        self.creatorImageOuterView.clipsToBounds = false
        self.creatorImageOuterView.layer.shadowColor = UIColor(named: "GumroadLabelColor")?.cgColor
        self.creatorImageOuterView.layer.shadowOpacity = 0.15
        self.creatorImageOuterView.layer.shadowOffset = .zero
        self.creatorImageOuterView.layer.shadowRadius = 1
        self.creatorImageOuterView.layer.shadowPath = UIBezierPath(roundedRect: self.creatorImageOuterView.bounds, cornerRadius: creatorImageCornerRadius).cgPath
        
        let emptyProfileImage = UIImage(named: "empty-profile")
        if let profile_url = product.creator_profile_picture_url,
            let imageURL = URL(string: profile_url) {
            self.creatorImageView.setImageWith(imageURL, placeholderImage: emptyProfileImage)
        } else {
            self.creatorImageView.image = emptyProfileImage
        }
        self.creatorImageView.contentMode = .scaleAspectFill
        self.creatorImageView.layer.cornerRadius = creatorImageCornerRadius
        self.creatorImageView.layer.borderColor = UIColor(named: "GumroadLabelColor")?.cgColor
        self.creatorImageView.layer.borderWidth = 1.0
        self.creatorImageView.clipsToBounds = true
        
        let creatorNameLabelAttributedString = NSMutableAttributedString(string: product.creator_name ?? "")
        creatorNameLabelAttributedString.addAttribute(.foregroundColor, value: UIColor(named: "GumroadLabelColor")!, range: NSRange(location: 0, length: creatorNameLabelAttributedString.length))
        self.creatorNameLabel.attributedText = creatorNameLabelAttributedString
    }
    
    @IBAction func ellipsisButtonClicked(_ sender: UIButton) {
        if let product = product {
            delegate?.showOptions(for: product)
        }
    }
}

protocol ProductTableViewCellDelegate {
    func showOptions(for product: Product)
}
