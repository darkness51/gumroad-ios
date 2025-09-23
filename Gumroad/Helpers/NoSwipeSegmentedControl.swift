//
//  NoSwipeSegmentedControl.swift
//  iOSCreator
//
//  Created by Nathan Chan on 3/22/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit

class NoSwipeSegmentedControl: UISegmentedControl {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
