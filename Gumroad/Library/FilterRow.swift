//
//  FilterRow.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/19/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class FilterRow: UIView {
    var creatorLabel = UILabel()
    var selectionButton = UIButton()
    var delegate: FilterRowDelegate?
    var type: FilterType = .creator
    
    convenience init(width: CGFloat, labelText: String, count: Int, type: FilterType) {
        self.init()
        
        self.type = type
        
        widthAnchor.constraint(equalToConstant: width).isActive = true
        heightAnchor.constraint(equalToConstant: 32).isActive = true

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSelectionButton)))

        switch type {
        case .all:
            creatorLabel.text = "All Creators"
        case .archived:
            creatorLabel.text = "Show archived only"
        case .creator:
            creatorLabel.text = labelText
        }
        creatorLabel.font = UIFont(name: "Mabry Pro", size: 16)
        creatorLabel.textColor = UIColor(named: "GumroadLabelColor")
        addSubview(creatorLabel)
        creatorLabel.translatesAutoresizingMaskIntoConstraints = false
        creatorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        creatorLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let countLabel = UILabel()
        countLabel.text = type == .archived ? "" : "(\(count))"
        countLabel.font = UIFont(name: "Mabry Pro", size: 16)
        countLabel.textColor = UIColor(named: "GumroadLabelColor")
        addSubview(countLabel)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.leadingAnchor.constraint(equalTo: creatorLabel.trailingAnchor, constant: 5).isActive = true
        countLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        selectionButton.setImage(UIImage(named: "filter-unselected"), for: .normal)
        selectionButton.setImage(UIImage(named: "filter-selected"), for: .selected)
        selectionButton.addTarget(self, action: #selector(toggleSelectionButton), for: .touchUpInside)
        selectionButton.isSelected = type == .all
        addSubview(selectionButton)
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        selectionButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        selectionButton.widthAnchor.constraint(equalTo: selectionButton.heightAnchor).isActive = true
        selectionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        selectionButton.leadingAnchor.constraint(greaterThanOrEqualTo: countLabel.trailingAnchor, constant: 16).isActive = true
        selectionButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    @objc func toggleSelectionButton() {
        if type == .all && selectionButton.isSelected {
            return
        }
        selectionButton.isSelected.toggle()
        delegate?.filterSelected(by: self, shouldForceRedraw: false)
    }
}

protocol FilterRowDelegate {
    func filterSelected(by: FilterRow, shouldForceRedraw: Bool)
}

enum FilterType {
    case all
    case archived
    case creator
}
