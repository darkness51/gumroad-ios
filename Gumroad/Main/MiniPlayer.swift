//
//  MiniPlayer.swift
//  Gumroad
//
//  Created by Nathan Chan on 1/28/21.
//  Copyright © 2021 Gumroad. All rights reserved.
//

import UIKit

class MiniPlayerWindow: UIWindow {
    
    var miniPlayerView: MiniPlayerView?
    var audioPlayerVC: AudioPlayerViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let miniPlayerHeight = MiniPlayerView.getHeight()
        let miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - miniPlayerHeight, width: UIScreen.main.bounds.width, height: miniPlayerHeight))
        miniPlayerView.isHidden = true
        self.addSubview(miniPlayerView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(miniPlayerTapped))
        miniPlayerView.addGestureRecognizer(tap)
        
        self.miniPlayerView = miniPlayerView
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate, appDelegate.isMiniPlayerShown(),  let progressBarView = appDelegate.miniPlayerWindow.miniPlayerView?.progressBarView {
                    progressBarView.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .gumroadGray : .black
                }
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let miniPlayerView = miniPlayerView {
            updateMiniPlayerFrame()
            self.bringSubviewToFront(miniPlayerView)
        }
    }
    
    @objc func miniPlayerTapped() {
        if let audioPlayerVC = audioPlayerVC {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if let vc = rootViewController?.presentedViewController?.presentedViewController {
                vc.present(audioPlayerVC, animated: true, completion: nil)
            } else {
                rootViewController?.presentedViewController?.present(audioPlayerVC, animated: true, completion: nil)
            }
            hideMiniPlayer(shouldCleanup: false)
        }
    }
    
    func showMiniPlayer(audioPlayerVC: AudioPlayerViewController) {
        self.audioPlayerVC = audioPlayerVC
        miniPlayerView?.audioPlayerVC = audioPlayerVC
        miniPlayerView?.updateDisplay()
        miniPlayerView?.isHidden = false
    }
    
    func hideMiniPlayer(shouldCleanup: Bool = true) {
        if shouldCleanup {
            audioPlayerVC?.cleanup()
        }
        audioPlayerVC = nil
        miniPlayerView?.isHidden = true
    }
    
    func isMiniPlayerShown() -> Bool {
        !(miniPlayerView?.isHidden ?? true)
    }

    func updateMiniPlayerFrame() {
        miniPlayerView?.updateFrame()
    }
    
    func updateMiniPlayerDisplay() {
        miniPlayerView?.updateDisplay()
    }

    func updateMiniPlayerProgressBar(percentage: Float) {
        miniPlayerView?.updateProgressBar(percentage: percentage)
    }
    
    func currentlyPlayingFileId() -> String? {
        return miniPlayerView?.currentlyPlayingFileId()
    }
}

class MiniPlayerView: UIView {

    let productImageView = UIImageView()
    let fileLabel = UILabel()
    let playPauseButton = UIButton()
    let skipForwardButton = UIButton()
    let progressBarView = UIView()
    var progressBarTrailingAnchor: NSLayoutConstraint!
    var audioPlayerVC: AudioPlayerViewController?
    static let BASE_HEIGHT: CGFloat = 62
    static let miniPlayerUpdatedNotificationString = "miniPlayerUpdatedNotification"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .systemBackground
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOpacity = 0.75
        layer.shadowOffset = .zero
        layer.shadowRadius = 2
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: bounds.origin, size: CGSize(width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: bounds.size.height)), cornerRadius: 0).cgPath
        
        productImageView.clipsToBounds = true
        productImageView.layer.cornerRadius = 5
        productImageView.layer.borderColor = UIColor.label.cgColor
        productImageView.layer.borderWidth = 1.0
        addSubview(productImageView)
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        productImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        productImageView.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        productImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        
        skipForwardButton.setImage(UIImage(named: "skip-forward"), for: .normal)
        skipForwardButton.addTarget(self, action: #selector(skipForwardButtonClicked), for: .touchUpInside)
        addSubview(skipForwardButton)
        skipForwardButton.translatesAutoresizingMaskIntoConstraints = false
        skipForwardButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        skipForwardButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        skipForwardButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        skipForwardButton.centerYAnchor.constraint(equalTo: productImageView.centerYAnchor).isActive = true
        
        playPauseButton.addTarget(self, action: #selector(playPauseButtonClicked), for: .touchUpInside)
        addSubview(playPauseButton)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        playPauseButton.trailingAnchor.constraint(equalTo: skipForwardButton.leadingAnchor, constant: -12).isActive = true
        playPauseButton.centerYAnchor.constraint(equalTo: productImageView.centerYAnchor).isActive = true
        
        fileLabel.font = UIFont(name: "Mabry Pro Bold", size: 16)
        fileLabel.textColor = UIColor(named: "GumroadLabelColor")
        fileLabel.numberOfLines = 1
        addSubview(fileLabel)
        fileLabel.translatesAutoresizingMaskIntoConstraints = false
        fileLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 8).isActive = true
        fileLabel.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -8).isActive = true
        fileLabel.centerYAnchor.constraint(equalTo: productImageView.centerYAnchor).isActive = true
        if #available(iOS 17.0, *) {
            progressBarView.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .gumroadGray : .black
        } else {
            progressBarView.backgroundColor = .gumroadPink
        }
        
        addSubview(progressBarView)
        progressBarView.translatesAutoresizingMaskIntoConstraints = false
        progressBarView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        progressBarView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        progressBarTrailingAnchor = progressBarView.trailingAnchor.constraint(equalTo: trailingAnchor)
        progressBarTrailingAnchor.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func getHeight() -> CGFloat {
        guard let window = UIApplication.shared.windows.first else {
            return BASE_HEIGHT
        }
        return window.safeAreaInsets.bottom + BASE_HEIGHT
    }

    func updateFrame() {
        let miniPlayerHeight = MiniPlayerView.getHeight()
        frame = CGRect(x: 0, y: UIScreen.main.bounds.maxY - miniPlayerHeight, width: UIScreen.main.bounds.width, height: miniPlayerHeight)
    }
    
    func updateDisplay() {
        guard let audioPlayerVC = audioPlayerVC else { return }
        let file = (audioPlayerVC.audioPlayer?.currentItem as? GRDAVPlayerItem)?.file
        
        let placeholderImage = UIImage(named: "product-placeholder-small")
        if let preview_url = file?.product?.preview_url,
            let imageURL = URL(string: preview_url) {
            productImageView.setImageWith(imageURL, placeholderImage: placeholderImage)
        } else {
            productImageView.image = placeholderImage
        }
        
        fileLabel.text = file?.displayName()
        
        playPauseButton.setImage(audioPlayerVC.playPauseButton.image(for: .normal), for: .normal)
    }

    func updateProgressBar(percentage: Float) {
        progressBarTrailingAnchor.constant = -(CGFloat((1 - percentage)) * UIScreen.main.bounds.width)
    }

    func currentlyPlayingFileId() -> String? {
        return (audioPlayerVC?.audioPlayer?.currentItem as? GRDAVPlayerItem)?.file.external_id
    }
    
    @objc func playPauseButtonClicked() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let audioPlayerVC = audioPlayerVC else { return }
        
        audioPlayerVC.togglePlayback()
        playPauseButton.setImage(audioPlayerVC.playPauseButton.image(for: .normal), for: .normal)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MiniPlayerView.miniPlayerUpdatedNotificationString), object: nil)
    }
    
    @objc func skipForwardButtonClicked() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let audioPlayerVC = audioPlayerVC else { return }
        
        audioPlayerVC.skipForward()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MiniPlayerView.miniPlayerUpdatedNotificationString), object: nil)
    }
}
