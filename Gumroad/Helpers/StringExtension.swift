//
//  StringExtension.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/22/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    
    func htmlContainsImg() -> Bool {
        return self.contains("<img")
    }
    
    // used for price display to match web, eg. $15.00 -> $15
    func stripCentsIfNeeded() -> String {
        if self.hasSuffix(".00") {
            return String(self[..<self.index(self.endIndex, offsetBy: -3)])
        }
        return self
    }
}

extension Optional where Wrapped == String {
    var nilIfEmpty: String? {
        guard let strongSelf = self else {
            return nil
        }
        return strongSelf.isEmpty ? nil : strongSelf
    }
}
