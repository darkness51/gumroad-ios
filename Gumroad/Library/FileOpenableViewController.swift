//
//  FileOpenableViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/25/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit
import AVKit
import AFNetworking
import PSPDFKitUI
import KFEpubKit
import SafariServices

class FileOpenableViewController: UIViewController {
    var isPresentedModally = false
    var moviePlayerFile: File?
    var epubPageViewController: GRDEPubPageViewController?
    var activePipAVPlayerViewController: AVPlayerViewController?
    var productViewController: ProductViewController?
    var documentController: UIDocumentInteractionController?
    let sessionManager = AFURLSessionManager(sessionConfiguration: URLSessionConfiguration.default)
    var audioPlayerVC: AudioPlayerViewController?
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? [.portrait, .landscapeLeft, .landscapeRight] : .portrait
    }
    
    func hideMiniPlayerIfNeeded() {
        (UIApplication.shared.delegate as? GRDAppDelegate)?.hideMiniPlayer()
    }
    
    func attemptDownload(for file: File, onStart: @escaping () -> Void, onComplete: @escaping () -> Void) {
        if (file.download_url == nil || file.isDownloaded() || GRDFileNetworkRequest.shared.isOffline()) {
            return
        }
        
        if (file.size as? Int64 ?? 0 > GRDFileNetworkRequest.shared.freeDiskspace()!) {
            let message = "The file \"\(file.displayName() ?? "")\" is too large to download.\n\nFree up some space and try again."
            let alert = UIAlertController(title: "File is too large to download", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        } else {
            _ = GRDFileNetworkRequest.shared.performFileDownload(file, sessionManager: sessionManager, onComplete: onComplete)
            onStart()
        }
    }

    func cancelDownload(for file: File) {
        GRDFileNetworkRequest.shared.cancelRunningDownloadForFile(file, sessionManager: sessionManager)
    }
    
    func cleanupMiniPlayerIfNeeded() {
        if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate,
            let miniPlayerAudioPlayerVC = appDelegate.miniPlayerWindow.audioPlayerVC,
            miniPlayerAudioPlayerVC != audioPlayerVC {
            print("Mini player was initialized somewhere else, cleaning it up")
            miniPlayerAudioPlayerVC.audioPlayer?.pause();
            miniPlayerAudioPlayerVC.audioPlayer?.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1))
            miniPlayerAudioPlayerVC.cleanup()
            appDelegate.hideMiniPlayer()
        }
    }
    
    func open(file: File, cell: FileTableViewCell?, tableView: UITableView?) {
        switch file.filegroup {
        case "audio":
            logEvent("file_opened_audio", params: file.getAnalyticsParams())
            hideMiniPlayerIfNeeded()
            if let prevAudioPlayerVC = audioPlayerVC {
                print("Previous audioPlayerVC exists, pausing the associated player")
                prevAudioPlayerVC.audioPlayer?.pause()
                prevAudioPlayerVC.audioPlayer?.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1))
                prevAudioPlayerVC.dismiss(animated: true)
            }
            audioPlayerVC = AudioPlayerViewController.instantiate()
            if  let audioPlayerVC = audioPlayerVC {
                audioPlayerVC.files = file.installment?.fetchAudioFiles() ?? file.product?.fetchAudioFiles() ?? []
                audioPlayerVC.initialFile = file
                audioPlayerVC.modalPresentationStyle = .fullScreen
                let _ = audioPlayerVC.view // forces the AudioPlayerViewController viewDidLoad call which performs all the audio player setup, without having to present the view controller
                (UIApplication.shared.delegate as? GRDAppDelegate)?.showMiniPlayer(audioPlayerVC: audioPlayerVC)
            }
        case "video":
            openVideoFile(file)
        case "link":
            if let urlString = file.external_link_url,
                let url = URL(string: urlString) {
                let vc = SFSafariViewController(url: url)
                present(vc, animated: true)
            }
        default:
            if !file.isDownloaded() {
                downloadAndShowProgressDialog(file: file, cell: cell, tableView: tableView, postDownloadAction: productViewController?.webView != nil ? .OpenNatively : .NoOp)
                return
            } else if file.isPDF(),
               let url = file.fileSystemURL() {
                let document = Document(url: url)
                document.title = file.name
                let pdfViewController = GRDPDFViewController(document: document, configuration: PDFConfiguration { builder in
                    builder.sharingConfigurations = [DocumentSharingConfiguration { builder in
                        builder.excludedActivityTypes = [.copyToPasteboard, .assignToContact, .postToFacebook, .postToTwitter, .postToWeibo, .message, .mail, .postToFlickr, .postToVimeo, .postToTencentWeibo]
                    }]
                })
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    pdfViewController.appearanceModeManager.appearanceMode = .night
                }
                pdfViewController.file = file

//                pdfViewController.navigationItem.setRightBarButtonItems([], for: .document, animated: false)
                var rightButtons = pdfViewController.navigationItem.rightBarButtonItems ?? []
                rightButtons.append(pdfViewController.settingsButtonItem)
                pdfViewController.navigationItem.setRightBarButtonItems(rightButtons, for: .document, animated: false)
                
                logEvent("file_opened_pdf", params: file.getAnalyticsParams())
                
                hideMiniPlayerIfNeeded()
                if isPresentedModally {
                    present(pdfViewController, animated: true, completion: nil)
                } else {
                    navigationController?.pushViewController(pdfViewController, animated: true)
                }
            } else if file.isEpub() {
                let epubPageViewController = GRDEPubPageViewController()
                epubPageViewController.file = file
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
                let epubController = KFEpubController(epubURL: file.fileSystemURL(), andDestinationFolder: documentsURL)
                epubController?.delegate = self
                epubController?.openAsynchronous(true)
                epubPageViewController.epubController = epubController
                self.epubPageViewController = epubPageViewController
                
                logEvent("file_opened_epub", params: file.getAnalyticsParams())
            } else if file.isImage() {
                logEvent("file_opened_image", params: file.getAnalyticsParams())
                
                let imageViewerVC = ImageViewerViewController.instantiate()
                imageViewerVC.isPresentedModally = isPresentedModally
                imageViewerVC.file = file
                imageViewerVC.modalPresentationStyle = .fullScreen
                if isPresentedModally {
                    present(imageViewerVC, animated: true, completion: nil)
                } else {
                    navigationController?.pushViewController(imageViewerVC, animated: true)
                }
            } else {
                openShareMenu(file: file, cell: cell, tableView: tableView, webView: productViewController?.webView)
            }
        }
    }
    
    func openFile(file: File, messagePayload: NSDictionary) {
        if messagePayload.value(forKey: "isDownload") as? Int == 1 {
            downloadAndShowProgressDialog(file: file, cell: nil, tableView: nil, postDownloadAction: .OpenShareMenu)
            return
        }
        
        if messagePayload.value(forKey: "type") as? String != "audio" {
            open(file: file, cell: nil, tableView: nil)
            return
        }
        
        guard let playingStatus = messagePayload.value(forKey: "isPlaying") as? String else { return }
        let isPlaying = playingStatus == "true"
        guard let resumeAtStr = messagePayload.value(forKey: "resumeAt") as? String else { return }
        let resumeAt = Double(resumeAtStr) ?? 0.0
        if file.content_length == nil, let contentLengthStr = messagePayload.value(forKey: "contentLength") as? String, let contentLength = Double(contentLengthStr) {
            file.content_length = NSNumber(value: contentLength)
        }
        guard let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate,
                let miniPlayerAudioPlayerVC = appDelegate.miniPlayerWindow.audioPlayerVC else {
            open(file: file, cell: nil, tableView: nil)
            return
        }
        if miniPlayerAudioPlayerVC != self.audioPlayerVC {
            cleanupMiniPlayerIfNeeded()
            open(file: file, cell: nil, tableView: nil)
        } else {
            if (miniPlayerAudioPlayerVC.audioPlayer?.rate ?? 0 > 0) {
                miniPlayerAudioPlayerVC.togglePlayback();
                
                if appDelegate.isMiniPlayerShown() {
                    appDelegate.updateMiniPlayerDisplay()
                }
            }
            
            if !isPlaying {
                file.resume_location = NSNumber(value: resumeAt < 1 ? 1 : resumeAt)
                miniPlayerAudioPlayerVC.setupAudioPlayer(for: file)
            }
        }
    }
    
    func openShareMenu(file: File, cell: FileTableViewCell?, tableView: UITableView?, webView: WKWebView?) {
        documentController = UIDocumentInteractionController()
        documentController?.url = file.fileSystemURL()
        documentController?.delegate = self
        documentController?.name = file.displayName()
        documentController?.annotation = file.getAnalyticsParams()
        
        if let tableView = tableView {
            if UIDevice.current.userInterfaceIdiom == .pad,
               let cell = cell {
                let presentingRect = cell.frame.offsetBy(dx: 0, dy: -1 * tableView.contentOffset.y)
                documentController?.presentOpenInMenu(from: presentingRect, in: tableView, animated: true)
            } else {
                documentController?.presentOpenInMenu(from: tableView.frame, in: tableView, animated: true)
            }
        } else if let webView = webView {
            documentController?.presentOpenInMenu(from: webView.frame, in: webView, animated: true)
        }

        logEvent("file_opened_share_menu", params: file.getAnalyticsParams())
    }
    
    enum AfterDownloadAction {
        case OpenNatively
        case OpenShareMenu
        case NoOp
    }
    
    func downloadAndShowProgressDialog(file: File, cell: FileTableViewCell?, tableView: UITableView?, postDownloadAction: AfterDownloadAction) {
        if file.isDownloaded() {
            switch postDownloadAction {
            case .OpenNatively:
                open(file: file, cell: cell, tableView: tableView)
            case .OpenShareMenu:
                openShareMenu(file: file, cell: cell, tableView: tableView, webView: productViewController?.webView)
            case .NoOp:
                break
            }
            return
        }
            
        file.isDownloadInProgress = true
        attemptDownload(for: file, onStart: {
            if let cell = cell, let tableView = tableView {
                cell.configure(with: FileFolderCellData(file: file), tableView: tableView)
            } else if let productViewController = self.productViewController, !productViewController.webView.isHidden {
                productViewController.loadingView.isHidden = false
            }
        }) {
            file.isDownloadInProgress = false
            
            if let cell = cell, let tableView = tableView {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                    cell.configure(with: FileFolderCellData(file: file), tableView: tableView)
            } else if let productViewController = self.productViewController, !productViewController.webView.isHidden {
                productViewController.loadingView.isHidden = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                switch postDownloadAction {
                case .OpenNatively:
                    self.open(file: file, cell: cell, tableView: tableView)
                case .OpenShareMenu:
                    self.openShareMenu(file: file, cell: cell, tableView: tableView, webView: productViewController.webView)
                case .NoOp:
                    break
                }
                
                logEvent("file_downloaded", params: file.getAnalyticsParams())
            }
        }
    }
    
    func setupPlayer(with url: URL, for file: File? = nil) {
        let playerItem = AVPlayerItem(url: url)
        let moviePlayerVC = AVPlayerViewController()
        moviePlayerVC.delegate = self
        moviePlayerVC.updatesNowPlayingInfoCenter = false
        moviePlayerVC.player = AVPlayer(playerItem: playerItem)
        if let resumeLocation = file?.resume_location,
           let contentLength = file?.content_length {
            if Int(truncating: resumeLocation) >= Int(truncating: contentLength) {
                moviePlayerVC.player?.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            } else {
                moviePlayerVC.player?.seek(to: CMTimeMakeWithSeconds(Float64(truncating: resumeLocation), preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            }
        }
        
        moviePlayerFile = file
        setupBackgroundAudioSession()
        moviePlayerVC.player?.play()
        
        logEvent("file_opened_video", params: file?.getAnalyticsParams())

        if let activePipAVPlayerViewController = activePipAVPlayerViewController {
            activePipAVPlayerViewController.player?.pause()
            activePipAVPlayerViewController.player = nil
            activePipAVPlayerViewController.dismiss(animated: true, completion: nil)
            self.activePipAVPlayerViewController = nil
        }
        hideMiniPlayerIfNeeded()
        present(moviePlayerVC, animated: true, completion: nil)
    }
    
    func openVideoFile(_ file: File) {
        if let fetchS3StreamURLRequest = GRDFileNetworkRequest.shared.fetchS3StreamURLRequest {
            GRDFileNetworkRequest.shared.cancelS3StreamRequest()
            if fetchS3StreamURLRequest.description == file.external_id {
                return
            }
        }
        
        if file.isDownloaded() {
            guard let url = file.fileSystemURL() else { return }
            setupPlayer(with: url, for: file)
        } else if file.streaming_url != nil {
            let s3RequestTask = GRDNetworkRequest.shared.getS3PlaylistUrl(file, successBlock: { [weak self] url in
                self?.setupPlayer(with: url, for: file)
            }) { (task, error) in
                guard
                    let data = (error as NSError).userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? Data
                    else { return }
                do {
                    guard
                        let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                        let message = jsonData["message"] as? String
                        else { return }
                    let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true)
                } catch(let error) {
                    print(error.localizedDescription)
                }
            }
            s3RequestTask.taskDescription = file.external_id
            GRDFileNetworkRequest.shared.fetchS3StreamURLRequest = s3RequestTask
        } else if let downloadUrl = file.download_url,
            let url = URL(string: downloadUrl) {
            setupPlayer(with: url, for: file)
        }
    }
    
    func getSwipeActionsConfiguration(file: File, cell: FileTableViewCell, tableView: UITableView) -> UISwipeActionsConfiguration? {
        if !file.isDownloaded() && GRDFileNetworkRequest.shared.isOffline() { return nil }
        
        var actions: [UIContextualAction] = []

        if file.isDownloaded() {
            let deleteAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
                file.delete() {
                    cell.configure(with: FileFolderCellData(file: file), tableView: tableView)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
                completion(true)
            }
            deleteAction.image = UIImage(named: "trash")
            deleteAction.backgroundColor = .gumroadRed
            actions.append(deleteAction)

            let shareAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.openShareMenu(file: file, cell: cell, tableView: tableView, webView: nil)
                completion(true)
            }
            shareAction.image = UIImage(named: "share-white")
            shareAction.backgroundColor = .gumroadYellow
            actions.append(shareAction)
        } else if file.isDownloadInProgress {
            let cancelAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
                self.cancelDownload(for: file)
                cell.configure(with: FileFolderCellData(file: file), tableView: tableView)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                completion(true)
            }
            cancelAction.image = UIImage(named: "cancel-white")
            cancelAction.backgroundColor = .gumroadRed
            actions.append(cancelAction)
        } else if file.download_url != nil {
            let downloadAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
                file.isDownloadInProgress = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.attemptDownload(for: file, onStart: {
                    cell.configure(with: FileFolderCellData(file: file), tableView: tableView)
                }) {
                    file.isDownloadInProgress = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    cell.configure(with: FileFolderCellData(file: file), tableView: tableView)
                    logEvent("file_downloaded", params: file.getAnalyticsParams())
                }
                completion(true)
            }
            downloadAction.image = UIImage(named: "download")
            downloadAction.backgroundColor = .gumroadGreen
            actions.append(downloadAction)
        }
        
        return UISwipeActionsConfiguration(actions: actions)
    }
}

extension FileOpenableViewController: AVPlayerViewControllerDelegate {
    func updateResumeLocation(playerViewController: AVPlayerViewController) {
        let playerItem = playerViewController.player?.currentItem
        let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: playerItem)
        var resumeLocation = 0
        if elapsedTimeInSeconds >= elapsedTimeLowerLimit {
            resumeLocation = Int(elapsedTimeInSeconds)
        }
        moviePlayerFile?.updateResumeLocation(resumeLocation)
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        updateResumeLocation(playerViewController: playerViewController)
    }

    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        activePipAVPlayerViewController = playerViewController
    }

    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        updateResumeLocation(playerViewController: playerViewController)
        activePipAVPlayerViewController = nil
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        present(playerViewController, animated: true, completion: nil)
    }
}

extension FileOpenableViewController: KFEpubControllerDelegate {
    func epubController(_ controller: KFEpubController!, didOpenEpub contentModel: KFEpubContentModel!) {
        guard let epubVC = epubPageViewController else { return }
        epubVC.epubContentModel = contentModel
        
        hideMiniPlayerIfNeeded()
        if isPresentedModally {
            present(epubVC, animated: true, completion: nil)
        } else {
            navigationController?.pushViewController(epubVC, animated: true)
        }
    }

    func epubController(_ controller: KFEpubController!, didFailWithError error: Error!) {
        print(error.localizedDescription)
    }
}

extension FileOpenableViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        if var params = controller.annotation as? [String: Any] {
            params["application"] = application
            logEvent("file_shared_to_application", params: params)
        }
    }
}

struct FileFolderCellData {
    var file: File?
    var folderId: String? = nil
    var folderName: String? = nil
    var isFolderOpen = false
}
