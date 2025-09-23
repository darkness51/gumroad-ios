//
//  UITextViewExtension.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/23/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

extension UITextView {
    func setHTMLFromString(htmlText: String, imgMaxWidth: Int) {
        let modifiedStyleString = String(format:"<style>img { max-width: \(imgMaxWidth)px; height: auto; } li br { display: none; } p { line-height: 24px; margin-top: 10px; } li p { line-height: 0 !important; margin: 0 !important }</style><span style=\"font-family: 'Mabry Pro', '-apple-system', 'HelveticaNeue'; font-size: \(self.font!.pointSize)\">%@</span>", htmlText)

        let attrStr = try! NSMutableAttributedString(
            data: modifiedStyleString.data(using: .unicode, allowLossyConversion: true)!,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.label, range: NSMakeRange(0, attrStr.length))

        self.attributedText = attrStr
    }
}
