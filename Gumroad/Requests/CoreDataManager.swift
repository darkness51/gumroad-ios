//
//  CoreDataManager.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/7/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import CoreData
import ISO8601

class CoreDataManager: NSObject {

    static let shared = CoreDataManager()

    private var urlRedirectToken: String?

    // URLRedirectToken

    func setUrlRedirectToken(_ token: String) {
        self.urlRedirectToken = token
    }

    func getUrlRedirectToken() -> String? {
        return urlRedirectToken
    }

    func clearUrlRedirectToken() {
        self.urlRedirectToken = nil
    }

    // Product

    func getProduct(with uniquePermalink: String?) -> Product? {
        let existingProductRequest = NSFetchRequest<NSManagedObject>(entityName: Product.entityName())
        existingProductRequest.predicate = NSPredicate(format: "unique_permalink == %@", uniquePermalink ?? "")
        let results = try? Product.mainQueueContext().fetch(existingProductRequest)
        return results?.last as? Product ?? nil
    }

    func createProduct(with productInformation: [String: Any]?, fileInformation: [AnyHashable]?) -> Product? {
        var product = getProduct(with: productInformation?["unique_permalink"] as? String)
        if product == nil {
            product = createProduct(with: productInformation)
        }
        saveOrUpdateFiles(product: product, filesData: fileInformation)
        return product
    }

    func createProduct(with productInformation: [String: Any]?) -> Product? {
        let product = NSEntityDescription.insertNewObject(forEntityName: Product.entityName(), into: Product.mainQueueContext()) as? Product
        if let product = product {
            updateProductInformation(productInformation, for: product)
        }
        return product
    }

    func updateProductAndFiles(_ productInformation: [String: Any]?) {
        let product = updateProduct(with: productInformation)
        saveOrUpdateFiles(product: product, filesData: productInformation?["file_data"] as? [AnyHashable])
    }

    func updateProduct(with productInformation: [String: Any]?) -> Product? {
        let product = getProduct(with: productInformation?["unique_permalink"] as? String)
        updateProductInformation(productInformation, for: product)
        return product
    }

    func updateProductInformation(_ productInformation: [String: Any]?, for product: Product?) {
        let context = product?.managedObjectContext
        context?.performAndWait({
            product?.name = productInformation?["name"] as? String
            product?.product_description = productInformation?["description"] as? String
            product?.unique_permalink = productInformation?["unique_permalink"] as? String
            product?.preview_url = productInformation?["preview_url"] as? String
            product?.preview_oembed_url = productInformation?["preview_oembed_url"] as? String
            product?.thumbnail_url = productInformation?["thumbnail_url"] as? String
            product?.preview_height = productInformation?["preview_height"] as? NSNumber
            product?.preview_width = productInformation?["preview_width"] as? NSNumber
            product?.creator_name = productInformation?["creator_name"] as? String
            product?.creator_username = productInformation?["creator_username"] as? String
            product?.creator_profile_url = productInformation?["creator_profile_url"] as? String
            product?.creator_profile_picture_url = productInformation?["creator_profile_picture_url"] as? String
            if let createdAt = productInformation?["created_at"] as? String {
                product?.created_at = Date(nsdate: NSDate(iso8601String: createdAt))
            }
            if let updatedAt = productInformation?["updated_at"] as? String {
                product?.updated_at = Date(nsdate: NSDate(iso8601String: updatedAt))
            }
            if let purchasedAt = productInformation?["purchased_at"] as? String {
                product?.purchased_at = Date(nsdate: NSDate(iso8601String: purchasedAt))
            }
            if let contentUpdatedAt = productInformation?["content_updated_at"] as? String {
                product?.content_updated_at = Date(nsdate: NSDate(iso8601String: contentUpdatedAt))
            }
            product?.is_archived = productInformation?["is_archived"] as? NSNumber
            product?.is_loading = NSNumber(value: false)
            product?.can_contact = productInformation?["can_contact"] as? NSNumber
            product?.purchase_id = productInformation?["purchase_id"] as? String
            product?.purchase_email = productInformation?["purchase_email"] as? String
            product?.user_id = productInformation?["user_id"] as? String
            product?.url_redirect_external_id = productInformation?["url_redirect_external_id"] as? String
            product?.url_redirect_token = productInformation?["url_redirect_token"] as? String
            product?.folders = productInformation?["folders"] as? [[String: String]]
            if let installmentInformation = productInformation?["product_updates_data"] as? [AnyHashable] {
                saveOrUpdateInstallments(for: product, installmentInformation: installmentInformation)
            }
            do {
                try context?.save()
            } catch let error {
                print((error as NSError).description)
            }
        })
    }

    func saveOrUpdateFiles(product: Product?, filesData: [AnyHashable]?) {
        product?.managedObjectContext?.performAndWait({
            // IDs of the files we want to keep, it is empty to start
            var aliveFileIDs: [String] = []
            var position = 0
            for fileData in filesData ?? [] {
                guard let fileData = fileData as? [String: Any],
                      let fileId = fileData["id"] as? String else {
                    continue
                }
                var file = getFile(with: fileId)
                if let file = file {
                    update(file, fileInformation: fileData, product: product)
                } else {
                    file = createFile(with: fileData, product: product)
                }
                file?.updatePosition(position)
                if let external_id = file?.external_id {
                    aliveFileIDs.append(external_id)
                }
                position += 1
            }
            deleteFilesThatAreNoLongerAlive(product: product, aliveFileIDs: aliveFileIDs)
            do {
                try File.mainQueueContext()?.save()
            } catch let error {
                print((error as NSError).description)
            }
        })
    }

    func removeAllProducts() {
        let context = Product.mainQueueContext()
        context?.performAndWait({
            let removeAllProductsRequest = NSFetchRequest<NSManagedObject>(entityName: Product.entityName())
            if let allProducts = try? context?.fetch(removeAllProductsRequest) {
                for product in allProducts {
                    (product as? Product)?.delete()
                }
            }
            do {
                try context?.save()
            } catch let error {
                print((error as NSError).description)
            }
        })
    }

    func removeAllPlaceholderProducts() {
        let context = Product.privateQueueContext()
        context?.performAndWait({
            let oldPlaceholderProductRequest = NSFetchRequest<NSManagedObject>(entityName: Product.entityName())
            oldPlaceholderProductRequest.predicate = NSPredicate(format: "unique_permalink IN %@", Product.placeholderProductUniquePermalinks())
            if let oldPlaceholderProducts = try? Product.mainQueueContext().fetch(oldPlaceholderProductRequest) {
                for product in oldPlaceholderProducts {
                    (product as? Product)?.delete()
                }
            }
            do {
                try context?.save()
            } catch let error {
                print((error as NSError).description)
            }
        })
    }

    func removeInvalidProducts(with permalinks: [String]) {
        let context = Product.privateQueueContext()
        context?.performAndWait({
            let invalidProductsFetch = NSFetchRequest<NSManagedObject>(entityName: Product.entityName())
            invalidProductsFetch.predicate = NSPredicate(format: "NOT (unique_permalink IN %@)", permalinks)
            if let invalidProducts = try? Product.mainQueueContext().fetch(invalidProductsFetch) {
                for product in invalidProducts {
                    guard let product = product as? Product else {
                        continue
                    }
                    if product.user_id != nil {
                        product.delete()
                    }
                }
            }
            do {
                try context?.save()
            } catch let error {
                print((error as NSError).description)
            }
        })
    }

    func removeAllLoadingProducts() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Product.entityName())
        fetchRequest.predicate = NSPredicate(format: "is_loading == %@", NSNumber(value: true))

        if let productsThatNeedToBeDeleted = try? Product.mainQueueContext().fetch(fetchRequest) {
            for product in productsThatNeedToBeDeleted {
                (product as? Product)?.delete()
            }
        }
    }

    func hasProducts() -> Bool {
        return totalNumberOfProducts() > 0
    }

    func totalNumberOfProducts() -> Int {
        let existingProductRequest = NSFetchRequest<NSManagedObject>(entityName: Product.entityName())
        let predicate = NSPredicate(format: "NOT (unique_permalink IN %@)", Product.placeholderProductUniquePermalinks())
        existingProductRequest.predicate = predicate
        let allProducts = try? Product.mainQueueContext().fetch(existingProductRequest)
        return allProducts?.count ?? 0
    }

    // File

    func fetchAllFiles() -> [File] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        let fetchedObjects = try? File.mainQueueContext().fetch(fetchRequest) as? [File]
        return fetchedObjects ?? []

    }

    func getFile(with externalId: String) -> File? {
        let existingFileRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        let predicate = NSPredicate(format: "external_id == %@", externalId)
        existingFileRequest.predicate = predicate
        return try? File.mainQueueContext()?.fetch(existingFileRequest).last as? File
    }

    func createFile(with fileInformation: [String: Any]?, installment: Installment?) -> File? {
        let context = installment?.managedObjectContext
        let file = self.insertFileIntoContext(with: context, fileInformation: fileInformation)
        file?.installment = installment
        file?.product = installment?.product
        return file
    }

    func createFile(with fileInformation: [String: Any]?, product: Product?) -> File? {
        let context = product?.managedObjectContext
        let file = self.insertFileIntoContext(with: context, fileInformation: fileInformation)
        file?.product = product
        return file
    }

    func updateExistingFile(with fileInformation: [String: Any]?, file: File?) {
        file?.name = fileInformation?["name"] as? String
        file?.name_displayable = fileInformation?["name_displayable"] as? String
        file?.file_description = fileInformation?["description"] as? String
        file?.download_url = fileInformation?["download_url"] as? String
        file?.streaming_url = fileInformation?["streaming_url"] as? String
        file?.external_link_url = fileInformation?["external_link_url"] as? String
        file?.size = fileInformation?["size"] as? NSNumber ?? 0
        file?.content_length = fileInformation?["content_length"] as? NSNumber
        file?.filetype = fileInformation?["filetype"] as? String
        file?.filegroup = fileInformation?["filegroup"] as? String
        file?.folder_id = fileInformation?["folder_id"] as? String
        if let createdAt = fileInformation?["created_at"] as? String {
            file?.created_at = Date(nsdate: NSDate(iso8601String: createdAt))
        }
        if let latestMediaLocationData = (fileInformation?["latest_media_location"] as? [String: Any]),
           let resumeLocation = latestMediaLocationData["location"] as? NSNumber,
           let resumeLocationTimestamp = latestMediaLocationData["timestamp"] as? String,
           let updatedResumeLocationTimestamp = Date(nsdate: NSDate(iso8601String: resumeLocationTimestamp)) {
            if file?.resume_location == nil ||
                file?.resume_location_timestamp == nil ||
                file!.resume_location_timestamp! < updatedResumeLocationTimestamp {
                file?.resume_location = resumeLocation
                file?.resume_location_timestamp = updatedResumeLocationTimestamp
            }
        }
    }

    func update(_ file: File?, fileInformation: [String: Any]?, product: Product?) {
        product?.managedObjectContext?.performAndWait({ [self] in
            self.updateExistingFile(with: fileInformation, file: file)
            file?.product = file?.product ?? product
        })
    }

    func insertFileIntoContext(with context: NSManagedObjectContext?, fileInformation: [String: Any]?) -> File? {
        var file: File? = nil
        if let context = context {
            file = NSEntityDescription.insertNewObject(forEntityName: File.entityName(), into: context) as? File
        }
        file?.name = fileInformation?["name"] as? String
        file?.name_displayable = fileInformation?["name_displayable"] as? String
        file?.file_description = fileInformation?["description"] as? String
        file?.download_url = fileInformation?["download_url"] as? String
        file?.streaming_url = fileInformation?["streaming_url"] as? String
        file?.external_link_url = fileInformation?["external_link_url"] as? String
        file?.size = fileInformation?["size"] as? NSNumber ?? 0
        file?.content_length = fileInformation?["content_length"] as? NSNumber
        file?.filetype = fileInformation?["filetype"] as? String
        file?.filegroup = fileInformation?["filegroup"] as? String
        file?.external_id = fileInformation?["id"] as? String
        file?.folder_id = fileInformation?["folder_id"] as? String
        if let createdAt = fileInformation?["created_at"] as? String {
            file?.created_at = Date(nsdate: NSDate(iso8601String: createdAt))
        }
        if let latestMediaLocationData = (fileInformation?["latest_media_location"] as? [String: Any]),
           let resumeLocation = latestMediaLocationData["location"] as? NSNumber,
           let resumeLocationTimestamp = latestMediaLocationData["timestamp"] as? String {
            file?.resume_location = resumeLocation
            file?.resume_location_timestamp = Date(nsdate: NSDate(iso8601String: resumeLocationTimestamp))

        }
        return file
    }

    func deleteFilesThatAreNoLongerAlive(product: Product?, aliveFileIDs: [String]) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        if let product = product {
            fetchRequest.predicate = NSPredicate(format: "product == %@ AND installment == nil AND NOT (external_id IN %@)", product, aliveFileIDs)
        }
        if let filesToDelete = try? File.mainQueueContext().fetch(fetchRequest) {
            for file in filesToDelete {
                (file as? File)?.delete()
            }
        }
    }

    // Installment

    func getInstallment(with externalId: String?) -> Installment? {
        let existingInstallmentRequest = NSFetchRequest<NSManagedObject>(entityName: Installment.entityName())
        existingInstallmentRequest.predicate = NSPredicate(format: "external_id == %@", externalId ?? "")
        let results = try? Installment.mainQueueContext().fetch(existingInstallmentRequest)
        return results?.last as? Installment ?? nil
    }

    func updateInstallment(with installmentInformation: [String: Any]?) -> Installment? {
        var installment = getInstallment(with: installmentInformation?["external_id"] as? String)

        let context = Installment.mainQueueContext()
        if installment == nil {
            if let context = context {
                installment = NSEntityDescription.insertNewObject(forEntityName: Installment.entityName(), into: context) as? Installment
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        installment?.name = installmentInformation?["name"] as? String
        if installment?.name == nil,
            let publishedAt = installment?.published_at {
            installment?.name = dateFormatter.string(from: publishedAt)
        }
        installment?.message = installmentInformation?["message"] as? String
        installment?.installment_type = installmentInformation?["installment_type"] as? String
        if let publishedAt = installmentInformation?["published_at"] as? String {
            installment?.published_at = Date(nsdate: NSDate(iso8601String: publishedAt))
        }
        installment?.external_id = installmentInformation?["external_id"] as? String
        installment?.url_redirect_external_id = installmentInformation?["url_redirect_external_id"] as? String
        installment?.creator_name = installmentInformation?["creator_name"] as? String
        installment?.creator_profile_url = installmentInformation?["creator_profile_url"] as? String
        installment?.creator_profile_picture_url = installmentInformation?["creator_profile_picture_url"] as? String
        installment?.call_to_action_text = installmentInformation?["call_to_action_text"] as? String
        installment?.call_to_action_url = installmentInformation?["call_to_action_url"] as? String

        if installment?.save() ?? false {
            saveOrUpdateFiles(installment: installment, filesData: installmentInformation?["files_data"] as? [AnyHashable])
        }
        return installment
    }

    func saveOrUpdateInstallments(for product: Product?, installmentInformation: [AnyHashable]?) {
        var aliveInstallmentIDs: [String] = []
        for installmentData in installmentInformation ?? [] {
            guard let installmentData = installmentData as? [String: Any] else {
                continue
            }
            let context = Installment.mainQueueContext()
            context?.performAndWait({
                var installment = getInstallment(with: installmentData["external_id"] as? String)
                if installment == nil {
                    if let context = context {
                        installment = NSEntityDescription.insertNewObject(forEntityName: Installment.entityName(), into: context) as? Installment
                    }
                }
                installment?.product = product
                installment?.message = installmentData["message"] as? String
                installment?.installment_type = installmentData["installment_type"] as? String
                if let publishedAt = installmentData["published_at"] as? String {
                    installment?.published_at = Date(nsdate: NSDate(iso8601String: publishedAt))
                }
                installment?.external_id = installmentData["external_id"] as? String
                installment?.url_redirect_external_id = installmentData["url_redirect_external_id"] as? String
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .none
                dateFormatter.dateStyle = .medium
                installment?.name = installmentData["name"] as? String
                if installment?.name == nil, let publishedAt = installment?.published_at {
                    installment?.name = dateFormatter.string(from: publishedAt)
                }
                installment?.creator_name = installmentData["creator_name"] as? String
                installment?.creator_profile_url = installmentData["creator_profile_url"] as? String
                installment?.creator_profile_picture_url = installmentData["creator_profile_picture_url"] as? String
                installment?.call_to_action_text = installmentData["call_to_action_text"] as? String
                installment?.call_to_action_url = installmentData["call_to_action_url"] as? String

                if installment?.save() ?? false {
                    if let externalId = installmentData["external_id"] as? String {
                        aliveInstallmentIDs.append(externalId)
                    }
                    saveOrUpdateFiles(installment: installment, filesData: installmentData["files_data"] as? [AnyHashable])
                }
            })
        }
        deleteInstallmentsThatAreNoLongerAlive(for: product, aliveInstallmentIds: aliveInstallmentIDs)
    }

    func saveOrUpdateFiles(installment: Installment?, filesData: [AnyHashable]?) {
        let context = installment?.managedObjectContext
        context?.performAndWait({
            // IDs of the files we want to keep, it is empty to start
            var aliveFileIDs: [String] = []
            var position = 0
            for fileData in filesData ?? [] {
                guard let fileData = fileData as? [String: Any],
                      let fileId = fileData["id"] as? String else {
                    continue
                }
                var file = getFile(with: fileId)
                if let file = file  {
                    update(file, fileInformation: fileData, installment: installment)
                } else {
                    file = createFile(with: fileData, installment: installment)
                }
                file?.updatePosition(position)
                file?.save()
                if let external_id = file?.external_id {
                    aliveFileIDs.append(external_id)
                }
                position += 1
            }
            deleteFilesThatAreNoLongerAlive(installment: installment, aliveFileIDs: aliveFileIDs)
            do {
                try context?.save()
            } catch let error {
                print((error as NSError).description)
            }
        })
    }

    func update(_ file: File?, fileInformation: [String: Any]?, installment: Installment?) {
        let context = installment?.managedObjectContext
        context?.performAndWait({ [self] in
            self.updateExistingFile(with: fileInformation, file: file)
            file?.installment = installment
            file?.save()
        })
    }

    func deleteFilesThatAreNoLongerAlive(installment: Installment?, aliveFileIDs: [String]) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: File.entityName())
        if let installment = installment {
            fetchRequest.predicate = NSPredicate(format: "installment == %@ AND NOT (external_id IN %@)", installment, aliveFileIDs)
        }
        if let filesToDelete = try? File.mainQueueContext().fetch(fetchRequest) {
            for file in filesToDelete {
                (file as? File)?.delete()
            }
        }
    }

    func deleteInstallmentsThatAreNoLongerAlive(for product: Product?, aliveInstallmentIds aliveInstallmentIDs: [String]) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Installment.entityName())
        if let product = product {
            fetchRequest.predicate = NSPredicate(format: "product == %@ AND NOT (external_id IN %@)", product, aliveInstallmentIDs)
        }
        if let installmentsToDelete = try? Installment.mainQueueContext().fetch(fetchRequest) {
            for installment in installmentsToDelete {
                (installment as? Installment)?.delete()
            }
        }
    }

    // Fetched Results Controller

    func fetchedResultsController(forProductFiles product: Product?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: File.entityName())
        if let product = product {
            fetchRequest.predicate = NSPredicate(format: "product == %@ AND installment == nil", product)
        }
        let sortDescriptor = NSSortDescriptor(
            key: "position",
            ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: File.mainQueueContext(), sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }

    func fetchedResultsController(forInstallments product: Product?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Installment.entityName())
        if let product = product {
            fetchRequest.predicate = NSPredicate(format: "product == %@", product)
        }
        let sortDescriptor = NSSortDescriptor(
            key: "published_at",
            ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Installment.mainQueueContext(), sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }

    func fetchedResultsControllerForLibrary() -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Product.entityName())
        fetchRequest.sortDescriptors = []

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Product.mainQueueContext(), sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }

    func fetchedResultsController(forInstallmentFiles installment: Installment?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: File.entityName())
        if let installment = installment {
            fetchRequest.predicate = NSPredicate(format: "installment == %@", installment)
        }
        let sortDescriptor = NSSortDescriptor(
            key: "position",
            ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: File.mainQueueContext(), sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }
}
