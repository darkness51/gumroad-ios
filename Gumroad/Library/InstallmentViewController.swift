//
//  InstallmentViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 11/22/20.
//  Copyright © 2020 Gumroad. All rights reserved.
//

import UIKit
import SafariServices
import CoreData

class InstallmentViewController: FileOpenableViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .library
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creatorProfileOuterView: UIView!
    @IBOutlet weak var creatorProfilePictureButton: UIButton!
    @IBOutlet weak var creatorNameButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageTextActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var ctaView: UIView!
    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var filesTableView: ContentSizedTableView!
    
    var installment: Installment?
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var isFirstLoad = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        backButton.isHidden = isPresentedModally
        closeButton.isHidden = !isPresentedModally
        navigationController?.navigationBar.isHidden = true
        if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate {
            scrollViewBottomConstraint.constant = appDelegate.isMiniPlayerShown() ? MiniPlayerView.BASE_HEIGHT : 0
            scrollView.layoutIfNeeded()
        }
        filesTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let installment = installment else {
            if isPresentedModally {
                dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFilesTableView), name: NSNotification.Name(rawValue: MiniPlayerView.miniPlayerUpdatedNotificationString), object: nil)
        
        fetchedResultsController = CoreDataManager.shared.fetchedResultsController(forInstallmentFiles: installment)
        do {
            try fetchedResultsController?.performFetch()
        } catch let error {
            print(error.localizedDescription)
        }
        
        let nib = UINib(nibName: FileTableViewCell.identifier, bundle: nil)
        filesTableView.register(nib, forCellReuseIdentifier: FileTableViewCell.identifier)
        filesTableView.delegate = self
        filesTableView.dataSource = self

        if let interactivePopGestureRecognizer = navigationController?.interactivePopGestureRecognizer {
            scrollView.panGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
        }

        if fetchedResultsController?.fetchedObjects?.count ?? 0 > 0 {
            // top separator
            let frame = CGRect(x: 0, y: 0, width: filesTableView.frame.size.width, height: 1 / UIScreen.main.scale)
            let line = UIView(frame: frame)
            filesTableView.tableHeaderView = line
            line.backgroundColor = filesTableView.separatorColor
        }
        
        titleLabel.text = installment.name
        titleLabel.textColor = .label
        creatorNameButton.setTitle(installment.creator_name, for: .normal)

        let creatorProfileCornerRadius = self.creatorProfileOuterView.frame.width / 2
        self.creatorProfileOuterView.clipsToBounds = false
        self.creatorProfileOuterView.layer.shadowColor = UIColor.label.cgColor
        self.creatorProfileOuterView.layer.shadowOpacity = 0.15
        self.creatorProfileOuterView.layer.shadowOffset = .zero
        self.creatorProfileOuterView.layer.shadowRadius = 1
        self.creatorProfileOuterView.layer.shadowPath = UIBezierPath(roundedRect: self.creatorProfileOuterView.bounds, cornerRadius: creatorProfileCornerRadius).cgPath
        
        let emptyProfileImage = UIImage(named: "empty-profile")
        if let profile_url = installment.creator_profile_picture_url,
            let imageURL = URL(string: profile_url) {
            creatorProfilePictureButton.setImage(fromUrl: imageURL, for: .normal, placeholderImage: emptyProfileImage)
        } else {
            creatorProfilePictureButton.setImage(emptyProfileImage, for: .normal)
        }
        creatorProfilePictureButton.imageView?.contentMode = .scaleAspectFill
        creatorProfilePictureButton.layer.cornerRadius = creatorProfileCornerRadius
        creatorProfilePictureButton.layer.borderColor =  UIColor.white.cgColor
        creatorProfilePictureButton.layer.borderWidth = 1.0
        creatorProfilePictureButton.clipsToBounds = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        dateLabel.text = dateFormatter.string(from: installment.published_at ?? Date())
        
        messageTextView.backgroundColor = .systemBackground
        if !(installment.message ?? "").htmlContainsImg() {
            setupMessageAndCTA()
        } else {
            messageTextActivityIndicatorView.isHidden = false
        }
        
        ctaButton.layer.cornerRadius = 4
        
        logEvent("installment_modal_opened", params: installment.getAnalyticsParams())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstLoad && (installment?.message ?? "").htmlContainsImg() {
            isFirstLoad = false
            setupMessageAndCTA()
            messageTextActivityIndicatorView.isHidden = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: MiniPlayerView.miniPlayerUpdatedNotificationString), object: nil)
    }

    @objc func reloadFilesTableView(notification: NSNotification) {
        filesTableView.reloadData()
    }
    
    func setupMessageAndCTA() {
        messageTextView.textContainerInset = .zero
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.setHTMLFromString(htmlText: installment?.message ?? "", imgMaxWidth: Int(view.frame.width - 30))
        
        if let ctaTitle = installment?.call_to_action_text.nilIfEmpty {
            ctaButton.setTitle(ctaTitle, for: .normal)
            ctaView.isHidden = false
        } else {
            ctaView.isHidden = true
        }
    }
    
    @IBAction func creatorNameClicked(_ sender: UIButton) {
        if let profileUrlString = installment?.creator_profile_url,
            let url = URL(string: profileUrlString) {
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        }
    }
    
    @IBAction func ctaButtonClicked(_ sender: Any) {
        if let ctaUrlString = installment?.call_to_action_url,
            let url = URL(string: ctaUrlString) {
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        }
    }
    
    @IBAction func backButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss(animated: true)
    }
}

extension InstallmentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FileTableViewCell.identifier) as? FileTableViewCell else {
            fatalError("The nib is not an instance of \(FileTableViewCell.identifier).")
        }
        cell.selectionStyle = .none
        cell.configure(with: FileFolderCellData(file: (fetchedResultsController?.object(at: indexPath) as! File)), tableView: tableView)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let file = fetchedResultsController?.object(at: indexPath) as? File {
            if !file.isDownloaded() && GRDFileNetworkRequest.shared.isOffline() { return }
            open(file: file, cell: tableView.cellForRow(at: indexPath) as? FileTableViewCell, tableView: tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let file = self.fetchedResultsController?.object(at: indexPath) as? File,
            let cell = tableView.cellForRow(at: indexPath) as? FileTableViewCell else { return nil }

        return getSwipeActionsConfiguration(file: file, cell: cell, tableView: tableView)
    }
}
