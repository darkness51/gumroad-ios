//
//  LibraryFilterResultsTableViewCell.swift
//  Gumroad
//
//  Created by Nathan Chan on 2/9/21.
//  Copyright © 2021 Gumroad. All rights reserved.
//

import UIKit

class LibraryFilterResultsTableViewCell: UITableViewCell {
    
    let resultsLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor(named: "GumroadBackgroundColor")
        
        resultsLabel.font = UIFont(name: "Mabry Pro", size: 14)
        resultsLabel.textColor = UIColor(named: "GumroadLabelColor")
        addSubview(resultsLabel)
        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        resultsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        resultsLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabel(_ text: String) {
        resultsLabel.text = text
    }
}
