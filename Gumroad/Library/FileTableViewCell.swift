//
//  FileTableViewCell.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/24/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit

class FileTableViewCell: UITableViewCell {
    @IBOutlet weak var fileTypeImageView: UIImageView!
    @IBOutlet weak var fileDownloadedImageView: UIImageView!
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var downloadingAnimatingImageView: UIImageView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var ellipsisImageView: UIImageView!
    @IBOutlet weak var folderOpenedClosedImageView: UIImageView!
    @IBOutlet weak var progressImageView: UIImageView!
    @IBOutlet weak var progressCircleView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var leadingSpaceConstraint: NSLayoutConstraint!

    static var identifier = "FileTableViewCell"
    var file: File?
    
    func configure(with fileFolderCellData: FileFolderCellData, tableView: UITableView) {
        self.file = fileFolderCellData.file
        
        if let file = fileFolderCellData.file {
            self.isUserInteractionEnabled = !file.isDownloadInProgress

            var audioIsCurrentlyPlaying = false
            if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate,
               appDelegate.isMiniPlayerShown(),
               let currentlyPlayingFileId = appDelegate.miniPlayerCurrentlyPlayingFileId() {
                audioIsCurrentlyPlaying = currentlyPlayingFileId == file.external_id ?? ""
            }

            self.folderOpenedClosedImageView.isHidden = true
            if ["video", "audio", "link", "image"].contains(file.filegroup) || file.isPDF() || file.isEpub() {
                self.arrowImageView.isHidden = false
                self.ellipsisImageView.isHidden = true
            } else {
                self.arrowImageView.isHidden = true
                self.ellipsisImageView.isHidden = false
            }

            if let resumeLocation = file.resume_location,
               let contentLength = file.content_length,
               Int(truncating: resumeLocation) > 0 {
                if Int(truncating: resumeLocation) >= Int(truncating: contentLength) {
                    self.progressImageView.image = UIImage(named: "file-complete")
                    self.progressCircleView.isHidden = true
                } else {
                    self.progressImageView.image = UIImage(named: "file-progress-border")

                    self.progressCircleView.backgroundColor = .gumroadPink
                    self.progressCircleView.translatesAutoresizingMaskIntoConstraints = false

                    let radius = self.progressCircleView.bounds.width / 2
                    let startAngle = -CGFloat.pi / 2
                    let endAngle = CGFloat.pi * 2 * (CGFloat(truncating: resumeLocation) / CGFloat(truncating: contentLength)) - (CGFloat.pi / 2)
                    let maskShape = CAShapeLayer()
                    let bezierPathMask = UIBezierPath()
                    bezierPathMask.move(to: CGPoint(x: radius, y: radius))
                    bezierPathMask.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                    bezierPathMask.close()
                    maskShape.path = bezierPathMask.cgPath

                    self.progressCircleView.layer.mask = maskShape
                    self.progressCircleView.isHidden = false
                }
                self.progressImageView.isHidden = false
            } else {
                self.progressImageView.isHidden = true
                self.progressCircleView.isHidden = true
            }

            self.fileTypeImageView.isHidden = false
            self.folderImageView.isHidden = true
            switch file.filegroup {
            case "video":
                self.fileTypeImageView.image = UIImage(named: "file-video")
            case "audio":
                self.fileTypeImageView.image = UIImage(named: "file-audio\(audioIsCurrentlyPlaying ? "-highlighted" : "")")
            case "document":
                self.fileTypeImageView.image = UIImage(named: "file-ebook")
            case "link":
                self.fileTypeImageView.image = UIImage(named: "file-link")
            case "image":
                self.fileTypeImageView.image = UIImage(named: "file-image")
            default:
                self.fileTypeImageView.image = UIImage(named: "file-unknown")
            }

            self.fileDownloadedImageView.isHidden = !file.isDownloaded()

            self.nameLabel.text = file.displayName()
            self.nameLabel.isEnabled = file.isDownloaded() || !GRDFileNetworkRequest.shared.isOffline()

            let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(truncating: file.size ?? 0), countStyle: .file)
            var fileLengthString: String?
            if let contentLength = file.content_length as? Int {
                if file.filegroup == "document" {
                    fileLengthString = "\(contentLength) pages"
                } else if ["video", "audio"].contains(file.filegroup) {
                    let hours = contentLength / 3600
                    let minutes = (contentLength / 60) % 60
                    let seconds = contentLength % 60
                    if hours > 0 {
                        fileLengthString = "\(hours)h \(minutes)m"
                    } else {
                        fileLengthString = "\(minutes)m \(seconds)s"
                    }
                }
            }

            self.sizeLabel.isHidden = false
            if file.filegroup == "audio" {
                self.sizeLabel.text = fileLengthString ?? ""
            } else if file.filegroup == "link" {
                self.sizeLabel.text = file.external_link_url ?? ""
            } else if let fileLengthString = fileLengthString {
                self.sizeLabel.text = "\(fileSizeString) · \(fileLengthString)"
            } else {
                self.sizeLabel.text = "\(fileSizeString)"
            }

            if file.isDownloadInProgress {
                var downloadingSpinnerImages: [UIImage] = []
                for i in 0...35 {
                    downloadingSpinnerImages.append(UIImage(named: "downloading-\(i)")!)
                }
                self.downloadingAnimatingImageView.animationImages = downloadingSpinnerImages
                self.downloadingAnimatingImageView.animationDuration = 1.0
                self.downloadingAnimatingImageView.startAnimating()
            }
            self.downloadingAnimatingImageView.isHidden = !(file.isDownloadInProgress)
            self.fileTypeImageView.isHidden = !self.downloadingAnimatingImageView.isHidden
            self.fileDownloadedImageView.isHidden = !(self.downloadingAnimatingImageView.isHidden && file.isDownloaded())

            self.contentView.backgroundColor = .systemBackground
            self.leadingSpaceConstraint.constant = file.folder_id == nil ? 15 : 35
        } else {
            self.fileTypeImageView.isHidden = true
            self.folderImageView.isHidden = false
            self.folderImageView.image = UIImage(named: "file-folder")
            self.folderOpenedClosedImageView.image = UIImage(named: "file-folder-\(fileFolderCellData.isFolderOpen ? "opened" : "closed")")
            self.folderOpenedClosedImageView.isHidden = false
            self.arrowImageView.isHidden = true
            self.ellipsisImageView.isHidden = true
            self.progressImageView.isHidden = true
            self.progressCircleView.isHidden = true
            self.fileDownloadedImageView.isHidden = true
            self.downloadingAnimatingImageView.isHidden = true
            self.nameLabel.text = fileFolderCellData.folderName
            self.nameLabel.isEnabled = true
            self.sizeLabel.isHidden = true
            self.contentView.backgroundColor = fileFolderCellData.isFolderOpen ? .systemBackground : (UITraitCollection.current.userInterfaceStyle == .dark ? .gumroadFolderGrayDark : .gumroadGray100)
            self.leadingSpaceConstraint.constant = 15
        }
    }
}
