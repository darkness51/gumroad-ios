//
//  Product.swift
//  Gumroad
//
//  Created by Nathan Chan on 10/26/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import Foundation
import SSDataKit

@objc(Product)
@objcMembers class Product: SSManagedObject {
    @NSManaged var name: String?
    @NSManaged var product_description: String?
    @NSManaged var preview_url: String?
    @NSManaged var thumbnail_url: String?
    @NSManaged var unique_permalink: String?
    @NSManaged var url: String?
    @NSManaged var creator_name: String?
    @NSManaged var creator_username: String?
    @NSManaged var creator_profile_url: String?
    @NSManaged var creator_profile_picture_url: String?
    @NSManaged var created_at: Date?
    @NSManaged var updated_at: Date?
    @NSManaged var purchased_at: Date?
    @NSManaged var content_updated_at: Date?
    @NSManaged var files: NSOrderedSet?
    @NSManaged var installments: NSOrderedSet?
    @NSManaged var last_successful_sync: Date?
    @NSManaged var url_redirect_external_id: String?
    @NSManaged var url_redirect_token: String?
    @NSManaged var is_archived: NSNumber?
    @NSManaged var is_loading: NSNumber?
    @NSManaged var preview_oembed_url: String?
    @NSManaged var preview_height: NSNumber?
    @NSManaged var preview_width: NSNumber?
    @NSManaged var position: NSNumber?
    @NSManaged var user_id: String?
    @NSManaged var purchase_id: String?
    @NSManaged var purchase_email: String?
    @NSManaged var can_contact: NSNumber?
    @NSManaged var folders: [[String: String]]?

    class func placeholderProductUniquePermalinks() -> [String] {
        #if DEBUG
            return ["mobile_friendly_placeholder_product"]
        #else
            return ["hDyr", "Llyh"]
        #endif
    }

    func productFiles() -> [File] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        let predicate = NSPredicate(format: "product = %@ AND installment = %@", self as CVarArg, 0)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(
            key: "position",
            ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        if let context = File.mainQueueContext(),
           let fetchedObjects = try? context.fetch(fetchRequest) as? [File] {
            return fetchedObjects
        }
        return []
    }

    func fetchAudioFiles() -> [File] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        let predicate = NSPredicate(format: "product = %@ AND filegroup = %@ AND installment = %@", self as CVarArg, "audio", NSNull())
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(
            key: "position",
            ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        if let context = File.mainQueueContext(),
           let fetchedObjects = try? context.fetch(fetchRequest) as? [File] {
            return fetchedObjects
        }
        return []
    }

    func hasVimeoPreview() -> Bool {
        if hasOembedPreview(), let url = preview_oembed_url {
            let pattern = "^https://player\\.vimeo\\.com\\/video"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let result = regex?.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.count))
            if result != nil {
                return true
            }
        }
        return false
    }

    func hasOembedPreview() -> Bool {
        guard let preview_oembed_url = preview_oembed_url else { return false }
        return !(preview_oembed_url == "")
    }

    func hasUpdates() -> Bool {
        guard let installments = installments else { return false }
        return installments.count > 0
    }

    func hasFiles() -> Bool {
        return productFiles().count > 0
    }
    
    func archive(_ archive: Bool, onComplete: (() -> Void)? = nil) {
        let queue = OperationQueue()
        queue.addOperation({ [self] in
            let context = Product.privateQueueContext()
            context?.perform { [weak self] in
                self?.is_archived = NSNumber(value: archive)
            }
            do {
                try context?.save()
                onComplete?()
            } catch let error {
                print(error.localizedDescription)
            }
        })
    }
}
