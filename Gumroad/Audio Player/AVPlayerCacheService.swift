//
//  GRDAVPlayerItemFactory.swift
//  Gumroad
//
//  Created by Matthew Whittaker on 11/30/19.
//  Copyright © 2019 Gumroad. All rights reserved.
//


import AVKit
import Cache

class AVPlayerCacheService: NSObject {
    
    static let shared = AVPlayerCacheService()

    let diskConfig = DiskConfig(name: "AudioCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Storage? = {
        return try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forData()
        )
    }()
    
    func cachedPlayerItem(_ playerItem: GRDAVPlayerItem, completion: @escaping (GRDAVPlayerItem) -> Void) {
        let file = playerItem.file!
        let url = file.bestAvailableUrl()!
        
        guard file.isDownloaded() == false else {
            completion(playerItem)
            return
        }
        
        storage?.async.entry(forKey: url.absoluteString) { [weak self] result in
            guard let self = self,
                  let fileType = file.filetype else { return }
            let mimeType = self.audioMimeTypeFrom(ext: fileType)
            var cacheItem: GRDAVPlayerItem
            if case .value(let data) = result {
                cacheItem = GRDAVPlayerItem(data: data.object, mimeType: mimeType, fileExtension: fileType)
            } else {
                cacheItem = GRDAVPlayerItem(url: url, customFileExtension: fileType)
            }
            cacheItem.delegate = self
            cacheItem.file = file
            completion(cacheItem)
        }
    }
    
    func audioMimeTypeFrom(ext: String) -> String {
        switch ext {
        case "flac":
            return "audio/flac"
        case "m3u":
            return "audio/mpegurl"
        case "m3u8":
            return "audio/mpegurl"
        case "m4a", "m4b":
            return "audio/mp4"
        case "mp3":
            return "audio/mpeg"
        case "ogg", "opus":
            return "audio/ogg"
        case "pls":
            return "audio/x-scpls"
        case "wav":
            return "audio/wav"
        default:
            return "audio/*"
        }
    }
}

extension AVPlayerCacheService: CachingPlayerItemDelegate {
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        guard let pi = playerItem as? GRDAVPlayerItem, let url = pi.file.bestAvailableUrl() else { return }
        storage?.async.setObject(data, forKey: url.absoluteString, completion: { _ in })
    }
}
