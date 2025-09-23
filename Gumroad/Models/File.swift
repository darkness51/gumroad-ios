//
//  File.swift
//  Gumroad
//
//  Created by Nathan Chan on 10/25/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import Foundation
import SSDataKit

@objc(File)
@objcMembers class File: SSManagedObject {
    @NSManaged var name: String?
    @NSManaged var name_displayable: String?
    @NSManaged var file_description: String?
    @NSManaged var download_url: String?
    @NSManaged var streaming_url: String?
    @NSManaged var external_link_url: String?
    @NSManaged var size: NSNumber?
    @NSManaged var content_length: NSNumber?
    @NSManaged var filetype: String?
    @NSManaged var filegroup: String?
    @NSManaged var local_file_url: String?
    @NSManaged var external_id: String?
    @NSManaged var created_at: Date?
    @NSManaged var position: NSNumber?
    @NSManaged var product: Product?
    @NSManaged var installment: Installment?
    @NSManaged var resume_location: NSNumber?
    @NSManaged var resume_location_timestamp: Date?
    @NSManaged var folder_id: String?

    var isDownloadInProgress = false

    func updateResumeLocation(_ location: Int, locallyOnly: Bool = false) {
        let context = File.mainQueueContext()
        context?.perform { [weak self] in
            let location = self?.filegroup == "audio" && location < 1 ? 1 : location
            self?.resume_location = NSNumber(value: location)
            self?.resume_location_timestamp = Date()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MiniPlayerView.miniPlayerUpdatedNotificationString), object: nil)

            if !locallyOnly {
                let _ = GRDNetworkRequest.shared.updateMediaLocation(
                    self?.urlRedirectExternalId() ?? "",
                    productFileId: self?.external_id ?? "",
                    purchaseId: self?.product?.purchase_id ?? "",
                    location: location,
                    successBlock: nil,
                    failureBlock: nil
                )
            }
        }
        do {
            try context?.save()
        } catch let error {
            if let errors = (error as NSError).userInfo[NSDetailedErrorsKey] as? [NSError] {
                for error in errors {
                    print(error.description)
                }
            }
        }
    }

    func updatePosition(_ position: Int) {
        self.position = NSNumber(value: position)
    }

    func generateAndSaveLocalFileUrl() {
        let fileURLInfo = GRDFileNetworkRequest.shared.generateFileDownloadURLInfo(self)
        let context = File.mainQueueContext()
        context?.performAndWait { [weak self] in
            self?.local_file_url = fileURLInfo["localFileRelativeURL"]!.absoluteString
        }
        do {
            try context?.save()
        } catch {
        }
    }

    func fileSystemURL() -> URL? {
        if !isDownloaded() {
            return nil
        }
        // Migrating in old file download urls from legacy downloads
        let fileInfo = GRDFileNetworkRequest.shared.generateFileDownloadURLInfo(self, createFileURL: false)
        guard let localFileUrl = local_file_url else {
            return nil
        }
        if !(localFileUrl == fileInfo["localFileRelativeURL"]?.absoluteString) {
            let context = File.mainQueueContext()
            context?.performAndWait { [weak self] in
                self?.local_file_url = nil
            }
            do {
                try context?.save()
            } catch {
            }
            return nil
        }
        return generateFileSystemURL()
    }

    func urlRedirectExternalId() -> String? {
        return installment?.url_redirect_external_id ?? product?.url_redirect_external_id ?? nil
    }

    func generateFileSystemURL() -> URL? {
        guard let localFileUrl = local_file_url else {
            return nil
        }
        var documentsDirectoryURL: URL? = nil
        do {
            documentsDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
        }
        let finalURL = URL(string: (documentsDirectoryURL?.absoluteString ?? "") + localFileUrl)
        return finalURL
    }

    override func prepareForDeletion() {
        if isDownloaded() {
            let fileDeletionQueue = OperationQueue()
            fileDeletionQueue.addOperation({ [self] in
                if let url = self.generateFileSystemURL(),
                   let managedObjectContext = File.mainQueueContext() {
                    do {
                        try FileManager.default.removeItem(at: url)

                        managedObjectContext.performAndWait { [weak self] in
                            self?.local_file_url = nil
                        }

                        try managedObjectContext.save()
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }
    
    func delete(onComplete: (() -> Void)? = nil) {
        if isDownloaded() {
            let fileDeletionQueue = OperationQueue()
            fileDeletionQueue.addOperation({ [self] in
                if let url = self.generateFileSystemURL(),
                   let managedObjectContext = File.mainQueueContext() {
                    do {
                        try FileManager.default.removeItem(at: url)

                        managedObjectContext.performAndWait { [weak self] in
                            self?.local_file_url = nil
                            onComplete?()
                        }
                        try managedObjectContext.save()
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }

    func isDownloaded() -> Bool {
        if local_file_url == nil {
            return false
        }
        let downloadedFileURL = generateFileSystemURL()
        if let downloadedFileURL = downloadedFileURL {
            if FileManager.default.isReadableFile(atPath: downloadedFileURL.path) {
                return true
            }
        }
        return false
    }

    func displayName() -> String? {
        return name_displayable ?? nameWithoutExtension()
    }

    func nameWithoutExtension() -> String? {
        guard let filetype = filetype else {
            return name
        }
        let pattern = "^(.+)\\." + filetype + "$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        guard let name = name else { return nil }
        let result = regex?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count))
        if let nsrange = result?.range(at: 1),
            let range = Range(nsrange, in: name) {
            return String(name[range])
        }
        return name
    }

    func bestAvailableUrl() -> URL? {
        var url: URL?
        if isDownloaded() {
            url = fileSystemURL()
        } else if ["video", "audio"].contains(filegroup),
           let streamingUrl = streaming_url {
            url = URL(string: streamingUrl)
        } else if let downloadUrl = download_url {
            url = URL(string: downloadUrl)
        }
        return url
    }

    func canBeOpenedImmediately() -> Bool {
        if isDownloaded() {
            return true
        } else if streaming_url != nil {
            return true
        } else if download_url != nil && ["video", "audio"].contains(filegroup) {
            return true
        }
        return false
    }

    func isPDF() -> Bool {
        if filetype == "pdf" {
            return true
        }
        return false
    }

    func isEpub() -> Bool {
        if filetype == "epub" {
            return true
        }
        return false
    }
    
    func isImage() -> Bool {
        if filegroup == "image" {
            return true
        }
        return false
    }

    func getAnalyticsParams() -> [String: Any] {
        return [
            "file_external_id": self.external_id ?? "",
            "file_name": self.name ?? "",
            "file_type": self.filetype ?? "",
            "file_group": self.filegroup ?? "",
            "product_unique_permalink": self.product?.unique_permalink ?? "",
            "product_name": self.product?.name ?? ""
        ]
    }
}
