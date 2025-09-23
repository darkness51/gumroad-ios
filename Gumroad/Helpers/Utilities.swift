//
//  Utilities.swift
//  Gumroad
//
//  Created by Nathan Chan on 12/22/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit
import AVKit

var mobileToken: String {
    ROT13.encode(Environment.mobileToken)
}

extension Date {
    init?(nsdate: NSDate?) {
        guard let nsdate = nsdate else { return nil}
        self.init(timeIntervalSinceReferenceDate: nsdate.timeIntervalSinceReferenceDate)
    }
}

extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }

    static let gumroadGreen = rgb(red: 35, green: 160, blue: 148)
    static let gumroadYellow = rgb(red: 255, green: 201, blue: 0)
    static let gumroadRed = rgb(red: 152, green: 40, blue: 42)
    static let gumroadPink = rgb(red: 255, green: 144, blue: 232)
    static let gumroadGray = rgb(red: 221, green: 221, blue: 221)
    static let gumroadGray100 = rgb(red: 244, green: 244, blue: 240)
    static let gumroadGray400 = rgb(red: 168, green: 162, blue: 158)
    static let gumroadFolderGrayDark = rgb(red: 36, green: 34, blue: 32)
}

extension UIImage {
    static func make(with color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let theImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return theImage
    }
}

extension UIRefreshControl {
    func programaticallyBeginRefreshing(in tableView: UITableView) {
        beginRefreshing()
        let offsetPoint = CGPoint.init(x: 0, y: -frame.size.height)
        tableView.setContentOffset(offsetPoint, animated: true)
    }
}

func setupBackgroundAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setCategory(.playback)
        try audioSession.setActive(true)
    } catch {
        print(error.localizedDescription)
    }
}

func removeBackgroundAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setActive(false)
    } catch {
        print(error.localizedDescription)
    }
}

func getElapsedTimeInSeconds(for playerItem: AVPlayerItem?) -> Float64 {
    guard let playerItem = playerItem else { return 0 }
    var secondsElapsed = CMTimeGetSeconds(playerItem.currentTime())
    if secondsElapsed < 0.0 {
        secondsElapsed = Float64(0.0)
    } else if CMTimeGetSeconds(playerItem.duration) < secondsElapsed {
        secondsElapsed = CMTimeGetSeconds(playerItem.duration)
    }
    return secondsElapsed
}

let elapsedTimeLowerLimit: Float64 = 3.0

let appOpenCountUserDefaultsKey = "appOpenCount1"
let appGroupName = "group.com.GRD.Gumroad"
let accountObjectUserDefaultsKey = "NXOAuth2AccountObject"
let timeRangeSelectedIndexUserDefaultsKey = "timeRangeSelectedIndex"
let recentlyViewedUserDefaultsKey = "recentlyViewedProductIds"
let sortByUserDefaultsKey = "sortBy"
let hasSeenLibraryMoreLikeThisUserDefaultsKey = "hasSeenLibraryMoreLikeThis"

let webViewTimeoutInSeconds = 300 // 5 minutes

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Int {
    func withCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self))!
    }

    func truncatedNumber() -> String {
        let thousand = 1_000
        let million = 1_000_000

        func formatNumber(_ value: Double, withSuffix suffix: String) -> String {
            let formattedString = String(format: "%.1f", value)
            if formattedString.hasSuffix(".0") {
                let integerPart = formattedString.dropLast(2) // Remove ".0"
                return "\(integerPart)\(suffix)"
            } else {
                return "\(formattedString)\(suffix)"
            }
        }

        switch self {
        case ..<thousand:
            return "\(self)"
        case thousand..<million:
            return formatNumber(Double(self) / Double(thousand), withSuffix: "K")
        default:
            return formatNumber(Double(self) / Double(million), withSuffix: "M")
        }
    }
}

extension Double {
    func dollarFormat() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let stringWithCommas = numberFormatter.string(from: NSNumber(value: self))!
        let dollarString = "\(self < 0 ? "-" : "")$\(stringWithCommas)"
        let secondLastChar = dollarString[dollarString.index(dollarString.endIndex, offsetBy: -2)]
        return "\(dollarString)\(secondLastChar == "." ? "0" : "")"
    }
}

extension Optional where Wrapped == Array<UIViewController> {
    func appendOrInitialize(_ newElement: UIViewController) -> [UIViewController] {
        if let array = self {
            return array + [newElement]
        } else {
            return [newElement]
        }
    }
}

extension Array where Element: Equatable {
    func removingDuplicates(by keyPath: KeyPath<Element, String>) -> [Element] {
        var seenIds = Set<String>()
        return self.filter { product in
            let id = product[keyPath: keyPath]
            return seenIds.insert(id).inserted
        }
    }
}

let validIAPPlatforms = ["Apple", "Google"]

func checkIsInAppPurchase(with purchaseData: [String: String]) -> Bool {
    return fetchInAppPurchasePlatform(from: purchaseData) != nil
}

func fetchInAppPurchasePlatform(from purchaseData: [String: String]) -> String? {
    if let iapPlatform = purchaseData["in_app_purchase_platform"]?.capitalized,
       validIAPPlatforms.contains(iapPlatform) {
        return iapPlatform
    }
    return nil
}
