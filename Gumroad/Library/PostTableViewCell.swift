//
//  PostTableViewCell.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/10/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    static var identifier = "PostTableViewCell"
    
    func configure(with installment: Installment) {
        self.nameLabel.text = installment.name
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        self.dateLabel.text = dateFormatter.string(from: installment.published_at ?? Date())
    }
}
