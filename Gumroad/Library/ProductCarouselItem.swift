//
//  ProductCarouselItem.swift
//  Gumroad
//
//  Created by Nathan Chan on 2/9/21.
//  Copyright © 2021 Gumroad. All rights reserved.
//

import UIKit

class ProductCarouselItem: UIImageView {
    var product: Product?
    var delegate: ProductCarouselItemDelegate?
    
    convenience init(product: Product) {
        self.init()
        
        self.product = product
        
        widthAnchor.constraint(equalToConstant: 200).isActive = true
        heightAnchor.constraint(equalToConstant: 200).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
        
        let placeholderImage = UIImage(named: "product-placeholder-large")
        if let thumbnail_url = product.thumbnail_url,
            let imageURL = URL(string: thumbnail_url) {
            self.setImageWith(imageURL, placeholderImage: placeholderImage)
        } else if let preview_url = product.preview_url,
            let imageURL = URL(string: preview_url) {
            self.setImageWith(imageURL, placeholderImage: placeholderImage)
        } else {
            self.image = placeholderImage
        }
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.layer.cornerRadius = 4
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
        
        let gradientImageView = UIImageView(image: UIImage(named: "product-image-gradient"))
        gradientImageView.alpha = 0.75
        addSubview(gradientImageView)
        gradientImageView.translatesAutoresizingMaskIntoConstraints = false
        gradientImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gradientImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        gradientImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gradientImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        let creatorProfileImageView = UIImageView()
        let emptyProfileImage = UIImage(named: "empty-profile")
        if let profile_url = product.creator_profile_picture_url,
            let imageURL = URL(string: profile_url) {
            creatorProfileImageView.setImageWith(imageURL, placeholderImage: emptyProfileImage)
        } else {
            creatorProfileImageView.image = emptyProfileImage
        }
        creatorProfileImageView.contentMode = .scaleAspectFill
        creatorProfileImageView.layer.cornerRadius = 10
        creatorProfileImageView.layer.borderColor =  UIColor.white.cgColor
        creatorProfileImageView.layer.borderWidth = 1.0
        creatorProfileImageView.layer.masksToBounds = true
        addSubview(creatorProfileImageView)
        creatorProfileImageView.translatesAutoresizingMaskIntoConstraints = false
        creatorProfileImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        creatorProfileImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        creatorProfileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        creatorProfileImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        
        let creatorNameLabel = UILabel()
        creatorNameLabel.text = product.creator_name
        creatorNameLabel.font = UIFont(name: "Mabry Pro", size: 12)
        creatorNameLabel.textColor = .white
        addSubview(creatorNameLabel)
        creatorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        creatorNameLabel.leadingAnchor.constraint(equalTo: creatorProfileImageView.trailingAnchor, constant: 8).isActive = true
        creatorNameLabel.centerYAnchor.constraint(equalTo: creatorProfileImageView.centerYAnchor).isActive = true
        creatorNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        
        let productNameLabel = UILabel()
        let attributedString = NSMutableAttributedString(string: product.name ?? "")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: NSMakeRange(0, attributedString.length))
        productNameLabel.attributedText = attributedString
        productNameLabel.font = UIFont(name: "Mabry Pro Bold", size: 14)
        productNameLabel.numberOfLines = 3
        productNameLabel.textColor = .white
        addSubview(productNameLabel)
        productNameLabel.translatesAutoresizingMaskIntoConstraints = false
        productNameLabel.leadingAnchor.constraint(equalTo: creatorProfileImageView.leadingAnchor).isActive = true
        productNameLabel.bottomAnchor.constraint(equalTo: creatorProfileImageView.topAnchor, constant: -8).isActive = true
        productNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    }
    
    @objc func viewTapped() {
        if let product = product {
            delegate?.productCarouselItemClicked(for: product)
        }
    }
}

protocol ProductCarouselItemDelegate {
    func productCarouselItemClicked(for product: Product)
}
