//
//  GRDFileNetworkRequest.swift
//  Gumroad
//
//  Created by Maxwell Elliott on 5/13/15.
//  Copyright (c) 2015 Gumroad. All rights reserved.
//

import AFNetworking
import Reachability

class GRDFileNetworkRequest: NSObject {
    
    static let shared = GRDFileNetworkRequest()
    
    let sessionManager : AFURLSessionManager = AFURLSessionManager(sessionConfiguration: URLSessionConfiguration.default)
    let reachability : Reachability = Reachability(hostName: "https://www.gumroad.com")
    var fetchS3StreamURLRequest : URLSessionDataTask?
    let documentsDirectoryURL : URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    
    func isOffline() -> Bool {
        return !reachability.isReachable()
    }
    
    func cancelS3StreamRequest() {
        self.fetchS3StreamURLRequest?.cancel()
        self.fetchS3StreamURLRequest = nil
    }
    
    func performFileDownload(_ file: File, sessionManager: AFURLSessionManager, onComplete: (() -> Void)? = nil) -> URLSessionDownloadTask? {
        sessionManager.setTaskWillPerformHTTPRedirectionBlock { (session, task, response, request) -> URLRequest in
            return URLRequest(url: request.url!)
        }
        
        guard let downloadURLString = file.download_url,
              let downloadURL = URL(string: downloadURLString) else {
            onComplete?()
            return nil
        }
        let downloadRequest = URLRequest(url: downloadURL)
        
        // Return an existing task if there is one for the download url
        let existingRunningDownloadTasks = sessionManager.downloadTasks.filter { (dTask) -> Bool in
            guard dTask.originalRequest == downloadRequest else { return false }
            switch dTask.state {
            case .running:
                return true
            case .suspended:
                dTask.cancel()
                return false
            case .completed:
                return true
            default:
                return false
            }
        }
        
        if let downloadTask = existingRunningDownloadTasks.first {
            return downloadTask
        }
        
        // There is no existing download task create one and return it
        let fileDownloadTask = sessionManager.downloadTask(with: downloadRequest, progress: nil, destination: { (url, response) -> URL in
            let fileURLInfo = self.generateFileDownloadURLInfo(file, createFileURL: true)
            return fileURLInfo["finalURLDirectory"]!
        }) { (response, filePath, error) -> Void in
            guard error == nil else {
                onComplete?()
                return
            }
            do {
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                guard var fileURL = filePath else { return }
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try fileURL.setResourceValues(resourceValues)
                } else {
                    print("File does not exist at path: \(fileURL.path)")
                }
            } catch let error {
                print(error.localizedDescription)
            }
            file.generateAndSaveLocalFileUrl()
            onComplete?()
        }
        
        fileDownloadTask.resume()
        
        return fileDownloadTask
    }
    
    func generateFileDownloadURLInfo(_ file: File, createFileURL: Bool = false) -> Dictionary<String, URL> {
        var parentObjectExternalId = ""
        
        if let installment = file.installment {
            if let redirectExternalId = installment.url_redirect_external_id {
                parentObjectExternalId = redirectExternalId
            } else if let externalId = installment.external_id {
                parentObjectExternalId = externalId
            }
        } else if let product = file.product,
              let redirectExternalId = product.url_redirect_external_id{
            parentObjectExternalId = redirectExternalId
        }
        
        var finalURLDirectory = self.documentsDirectoryURL.appendingPathComponent(parentObjectExternalId)
        finalURLDirectory = finalURLDirectory.appendingPathComponent(file.external_id!)
        
        if (createFileURL) {
            do {
                try FileManager.default.createDirectory(at: finalURLDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        let pathString = parentObjectExternalId + "/" + file.external_id! + "/" + file.name!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let localFileRelativeURL = URL(string:  pathString)!
        var response = Dictionary<String, URL>()
        response["localFileRelativeURL"] = localFileRelativeURL
        response["finalURLDirectory"] = finalURLDirectory.appendingPathComponent(file.name!.replacingOccurrences(of: "/", with: "%2F"))
        
        return response
    }
    
    func downloadTaskForFile(_ file: File, sessionManager: AFURLSessionManager) -> URLSessionDownloadTask? {
        guard let downloadUrlString = file.download_url,
              let downloadURL = URL(string: downloadUrlString)
              else { return nil }
        let request = URLRequest(url: downloadURL)
        
        let existingTasks = sessionManager.downloadTasks.filter { (dTask) -> Bool in
            let existingDownloadTask = dTask
            if (existingDownloadTask.originalRequest?.url?.absoluteString == request.url?.absoluteString) {
                return true
            }
            return false
        }
        
        if let existingTask = existingTasks.first {
            return existingTask
        }
        
        return nil
    }

    func cancelRunningDownloadForFile(_ file: File, sessionManager: AFURLSessionManager) -> Void {
        self.downloadTaskForFile(file, sessionManager: sessionManager)?.cancel()
    }
    
    func cancelAllRunningDownloadsForProduct(_ product: Product, sessionManager: AFURLSessionManager?) -> Void {
        if let manager = sessionManager {
            for file in product.productFiles() {
                self.downloadTaskForFile(file, sessionManager: manager)?.cancel()
            }
        }
    }
    
    func cancelAllRunningDownloads(_ sessionManager: AFURLSessionManager?) -> Void {
        if let manager = sessionManager {
            for downloadTask in manager.downloadTasks {
                downloadTask.cancel()
            }
        }
    }
    
    // Internal
    
    func freeDiskspace() -> Int64? {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let path = documentDirectoryPath.last else { return nil }
        do {
           let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            if let freeSize = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
}
