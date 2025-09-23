//
//  StoryboardIdentifiable.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/22/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

enum StoryboardName: String {
    case main
    case creator
    case library
    case discover
    case authentication
    case audioPlayer
    case imageViewer
    // these string values get capitalized for storyboard file lookup
}

protocol StoryboardIdentifiable where Self: UIViewController {
    static var storyboardName: StoryboardName { get }
}

extension StoryboardIdentifiable {
    static func storyboardIdentifier() -> String {
        return String(describing: Self.self)
    }

    static func storyboard() -> UIStoryboard {
        return UIStoryboard(name: Self.storyboardName.rawValue.capitalizingFirstLetter(), bundle: nil)
    }

    static func instantiate() -> Self {
        return storyboard().instantiateViewController(withIdentifier: Self.storyboardIdentifier()) as! Self
    }
}
