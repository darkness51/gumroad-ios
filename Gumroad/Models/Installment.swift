//
//  Installment.swift
//  Gumroad
//
//  Created by Nathan Chan on 10/26/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import Foundation
import SSDataKit

@objc(Installment)
@objcMembers class Installment: SSManagedObject {
    @NSManaged var name: String?
    @NSManaged var message: String?
    @NSManaged var external_id: String?
    @NSManaged var installment_type: String?
    @NSManaged var published_at: Date?
    @NSManaged var url_redirect_external_id: String?
    @NSManaged var creator_name: String?
    @NSManaged var creator_profile_url: String?
    @NSManaged var creator_profile_picture_url: String?
    @NSManaged var call_to_action_text: String?
    @NSManaged var call_to_action_url: String?
    @NSManaged var files: NSOrderedSet?
    @NSManaged var product: Product?

    func fetchAudioFiles() -> [File] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        let predicate = NSPredicate(format: "installment = %@ AND filegroup = %@", self, "audio")
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

    func getAnalyticsParams() -> [String: Any] {
        return [
            "installment_external_id": self.external_id ?? "",
            "installment_name": self.name ?? "",
            "product_unique_permalink": self.product?.unique_permalink ?? "",
            "product_name": self.product?.name ?? ""
        ]
    }
}
