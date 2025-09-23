//
//  ProductCarouselTableViewCell.swift
//  Gumroad
//
//  Created by Nathan Chan on 2/9/21.
//  Copyright © 2021 Gumroad. All rights reserved.
//

import UIKit

class ProductCarouselTableViewCell: UITableViewCell, ProductCarouselItemDelegate {
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    var products: [Product] = []
    var delegate: ProductCarouselTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor(named: "GumroadBackgroundColor")
        
        scrollView.contentSize = CGSize(width: 500, height: 200)
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16).isActive = true
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(products: [Product]) {
        self.products = products
        
        for subview in stackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        for product in products {
            let item = ProductCarouselItem(product: product)
            item.delegate = self
            stackView.addArrangedSubview(item)
        }
    }
    
    func scrollToTop() {
        scrollView.setContentOffset(.zero, animated: true)
    }
    
    func productCarouselItemClicked(for product: Product) {
        delegate?.productCarouselItemClicked(for: product)
    }
}

protocol ProductCarouselTableViewCellDelegate {
    func productCarouselItemClicked(for product: Product)
}
