//
//  GRDAVPlayerItem.swift
//  Gumroad
//
//  Created by Matthew Whittaker on 11/30/19.
//  Copyright © 2019 Gumroad. All rights reserved.
//

import Foundation

class GRDAVPlayerItem: CachingPlayerItem {
    var file: File!
    static func playerItemWithFile(_ file: File) -> GRDAVPlayerItem? {
        guard let url = file.bestAvailableUrl() else { return nil }
        let player = GRDAVPlayerItem(url: url)
        player.file = file
        return player
    }
}
