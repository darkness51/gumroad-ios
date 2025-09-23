//
//  AudioPlayerViewController.swift
//  Gumroad
//
//  Created by Nathan Chan on 1/20/21.
//  Copyright © 2021 Gumroad. All rights reserved.
//

import UIKit
import SafariServices
import AVKit
import MediaPlayer
import KVOController

class AudioPlayerViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .audioPlayer

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var creatorProfilePictureButton: UIButton!
    @IBOutlet weak var creatorNameButton: UIButton!
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var seekBackwardButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    @IBOutlet weak var seekForwardButton: UIButton!
    
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var playbackSpeedButton: UIButton!
    
    var initialFile: File?
    var files: [File] = []
    var playerItems: [GRDAVPlayerItem] = []
    var queuePlayerItemIndex: Int = 0
    var audioPlayer: AVPlayer?
    var periodicTimeObserver: Any?
    var seekTimer: Timer?
    var seekIsActive = false
    var SKIP_BACKWARD_SECONDS = 15.0
    var SKIP_FORWARD_SECONDS = 30.0
    let routePickerView = AVRoutePickerView()
    let playbackSpeedUserDefaultsKey = "playbackSpeed"
    let playbackSpeeds = ["0.5", "1", "1.25", "1.5", "2"]
    var isCollapsingToMiniPlayer = false
    var isOpeningSafari = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
        setNeedsStatusBarAppearanceUpdate()
        (UIApplication.shared.delegate as? GRDAppDelegate)?.hideMiniPlayer()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeholderImage = UIImage(named: "product-placeholder-large")
        if let preview_url = initialFile?.product?.preview_url,
            let imageURL = URL(string: preview_url) {
            productImageView.setImageWith(imageURL, placeholderImage: placeholderImage)
        } else {
            productImageView.image = placeholderImage
        }
        creatorNameButton.setTitle(initialFile?.product?.creator_name ?? initialFile?.installment?.creator_name, for: .normal)

        let emptyProfileImage = UIImage(named: "empty-profile")
        if let profile_url = initialFile?.product?.creator_profile_picture_url ?? initialFile?.installment?.creator_profile_picture_url,
            let imageURL = URL(string: profile_url) {
            creatorProfilePictureButton.setImage(fromUrl: imageURL, for: .normal, placeholderImage: emptyProfileImage)
        } else {
            creatorProfilePictureButton.setImage(emptyProfileImage, for: .normal)
        }
        creatorProfilePictureButton.imageView?.contentMode = .scaleAspectFill
        creatorProfilePictureButton.imageView?.layer.cornerRadius = creatorProfilePictureButton.imageView!.frame.width / 2
        creatorProfilePictureButton.imageView?.layer.borderColor =  UIColor.white.cgColor
        creatorProfilePictureButton.imageView?.layer.borderWidth = 1.0
        creatorProfilePictureButton.imageView?.clipsToBounds = true
        
        let sliderThumbImage = UIImage(named: "slider-thumb")
        slider.setThumbImage(sliderThumbImage, for: .normal)
        slider.setThumbImage(sliderThumbImage, for: .highlighted)
        
        routePickerView.delegate = self
        
        playbackSpeedButton.imageView?.contentMode = .scaleAspectFit
        
        setupBackgroundAudioSession()
        
        playerItems = files.compactMap({ GRDAVPlayerItem.playerItemWithFile($0) })
        
        var initialIndex = 0
        for playerItem in playerItems {
            if playerItem.file == initialFile {
                queuePlayerItemIndex = initialIndex
                setTrackInformationLabels(playerItem)
                setupAudioPlayer(for: playerItem, isFirstLoad: true)
                break
            }
            initialIndex += 1
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        let rcc = MPRemoteCommandCenter.shared()
        let playCommand = rcc.playCommand
        playCommand.isEnabled = true
        playCommand.addTarget(handler: remoteTogglePlayPause)
        let pauseCommand = rcc.pauseCommand
        pauseCommand.isEnabled = true
        pauseCommand.addTarget(handler: remoteTogglePlayPause)
        let skipBackwardCommand = rcc.skipBackwardCommand
        skipBackwardCommand.isEnabled = true
        skipBackwardCommand.addTarget(handler: remoteSkipBackward)
        skipBackwardCommand.preferredIntervals = [SKIP_BACKWARD_SECONDS as NSNumber]
        let skipForwardCommand = rcc.skipForwardCommand
        skipForwardCommand.isEnabled = true
        skipForwardCommand.addTarget(handler: remoteSkipForward)
        skipForwardCommand.preferredIntervals = [SKIP_FORWARD_SECONDS as NSNumber]
        let previousTrackCommand = rcc.previousTrackCommand
        previousTrackCommand.isEnabled = true
        previousTrackCommand.addTarget(handler: remoteSkipBackward)
        let nextTrackCommand = rcc.nextTrackCommand
        nextTrackCommand.isEnabled = true
        nextTrackCommand.addTarget(handler: remoteSkipForward)
    }

    @objc func appMovedToForeground() {
        updatePlaybackButtons()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !isCollapsingToMiniPlayer && !isOpeningSafari {
            cleanup()
        }
        isCollapsingToMiniPlayer = false
        isOpeningSafari = false
    }
    
    func cleanup() {
        guard let audioPlayer = audioPlayer else { return }
        let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: audioPlayer.currentItem)
        (audioPlayer.currentItem as? GRDAVPlayerItem)?.file.updateResumeLocation(Int(elapsedTimeInSeconds))
        audioPlayer.pause()
        notifyAudioInfoForWebView()

        resetCurrentAudioPlayer()
        removeBackgroundAudioSession()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? [.portrait, .landscapeLeft, .landscapeRight] : .portrait
    }
    
    @IBAction func sliderTouchedDown(_ sender: UISlider) {
        if let periodicTimeObserver = periodicTimeObserver {
            audioPlayer?.removeTimeObserver(periodicTimeObserver)
        }
        periodicTimeObserver = nil
    }
    
    @IBAction func sliderTouchedUp(_ sender: UISlider) {
        guard let trackLength = audioPlayer?.currentItem?.duration,
            trackLength.timescale != 0 else {
            return
        }
        let audioLengthInSeconds = Float(Int(trackLength.value) / Int(trackLength.timescale == 0 ? 1 : trackLength.timescale))
        let newElapsedTime = CMTimeMakeWithSeconds(Float64(audioLengthInSeconds * slider.value), preferredTimescale: 1)
        seekIsActive = true
        audioPlayer?.seek(to: newElapsedTime) { _ in
            self.seekIsActive = false
        }
        setupPeriodicTimeObserverForAudioPlayer()
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let trackLength = audioPlayer?.currentItem?.duration,
            trackLength.timescale != 0 else {
            return
        }
        let audioLengthInSeconds = Float(Int(trackLength.value) / Int(trackLength.timescale == 0 ? 1 : trackLength.timescale))
        let newElapsedTime = CMTimeMakeWithSeconds(Float64(audioLengthInSeconds * slider.value), preferredTimescale: 1)
        setTrackTimeLabelsWithElapsedTime(newElapsedTime)
    }
    
    @IBAction func playPauseButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        togglePlayback()
    }
    
    @IBAction func seekBackwardClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        previousTrack()
    }
    
    @IBAction func seekForwardClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advanceTrack()
    }
    
    @IBAction func skipBackwardClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        skipBackward()
    }
    
    @IBAction func skipForwardClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        skipForward()
    }
    
    func playAudioPlayerAtSavedRate() {
        let playbackSpeedIndex: Int
        if let savedPlaybackSpeed = UserDefaults.standard.string(forKey: self.playbackSpeedUserDefaultsKey),
            let savedPlaybackSpeedIndex = self.playbackSpeeds.firstIndex(of: savedPlaybackSpeed) {
            playbackSpeedIndex = savedPlaybackSpeedIndex
        } else {
            playbackSpeedIndex = 1
            UserDefaults.standard.set(self.playbackSpeeds[playbackSpeedIndex], forKey: self.playbackSpeedUserDefaultsKey)
        }
        self.playbackSpeedButton.tag = playbackSpeedIndex
        let playbackSpeed = self.playbackSpeeds[playbackSpeedIndex]
        self.playbackSpeedButton.setImage(UIImage(named: "playback-speed-\(playbackSpeed)x"), for: .normal)
        audioPlayer?.currentItem?.audioTimePitchAlgorithm = .timeDomain
        audioPlayer?.play()
        audioPlayer?.rate = Float(playbackSpeed)!
        notifyAudioInfoForWebView()
    }
    
    func setupAudioPlayer(for playerItem: GRDAVPlayerItem, isFirstLoad: Bool = false) {
        resetCurrentAudioPlayer()
        
        logEvent("file_audio_started", params: playerItem.file.getAnalyticsParams())

        AVPlayerCacheService.shared.cachedPlayerItem(playerItem) { [self] cachedPlayerItem in
            DispatchQueue.main.async(execute: { [self] in
                if self.audioPlayer == nil {
                    self.audioPlayer = AVPlayer(playerItem: cachedPlayerItem)
                } else {
                    self.audioPlayer?.replaceCurrentItem(with: cachedPlayerItem)
                }
                guard let audioPlayer = self.audioPlayer else { return }
                audioPlayer.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1))
                audioPlayer.automaticallyWaitsToMinimizeStalling = false
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.automaticallyAdvance(toNextTrack:)),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: audioPlayer.currentItem)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.playbackHasStalled),
                    name: .AVPlayerItemPlaybackStalled,
                    object: audioPlayer.currentItem)
                self.setupPeriodicTimeObserverForAudioPlayer()

                self.kvoController.observe(audioPlayer.currentItem, keyPath: "status", options: [.initial, .new], block: { observer, object, change in
                    let audioController = observer as? AudioPlayerViewController
                    if (object as? AVPlayerItem)?.status == .readyToPlay {
                        audioController?.playerHasLoadedMedia()
                    } else {
                        audioController?.playerHasNotLoadedMedia()
                    }
                })
                if isFirstLoad,
                   let file = (audioPlayer.currentItem as? GRDAVPlayerItem)?.file,
                   let resumeLocation = file.resume_location,
                   let contentLength = file.content_length {
                    if Int(truncating: resumeLocation) >= Int(truncating: contentLength) {
                        audioPlayer.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1))
                    } else {
                        audioPlayer.seek(to: CMTimeMakeWithSeconds(Float64(truncating: resumeLocation), preferredTimescale: 1))
                    }
                }
                self.playAudioPlayerAtSavedRate()
                self.playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
                self.setNowPlayingInfoCenter(for: cachedPlayerItem)
                if let appDelegate = UIApplication.shared.delegate as? GRDAppDelegate,
                    appDelegate.isMiniPlayerShown() {
                    appDelegate.updateMiniPlayerDisplay()
                }
                notifyAudioInfoForWebView()
            })
        }
    }
    
    func setupAudioPlayer(for file: File) {
        playerItems = files.compactMap({ GRDAVPlayerItem.playerItemWithFile($0) })
        
        var initialIndex = 0
        for playerItem in playerItems {
            if playerItem.file == file {
                queuePlayerItemIndex = initialIndex
                setTrackInformationLabels(playerItem)
                setupAudioPlayer(for: playerItem, isFirstLoad: true)
                break
            }
            initialIndex += 1
        }
    }

    func resetCurrentAudioPlayer() {
        if let audioPlayer = audioPlayer {
            audioPlayer.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: audioPlayer.currentItem)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: audioPlayer.currentItem)
            if let periodicTimeObserver = periodicTimeObserver {
                audioPlayer.removeTimeObserver(periodicTimeObserver)
            }
            notifyAudioInfoForWebView()
            periodicTimeObserver = nil
            self.audioPlayer = nil
        }
    }
    
    func setupPeriodicTimeObserverForAudioPlayer() {
        if let audioPlayer = audioPlayer, periodicTimeObserver == nil {
            let interval = CMTimeMakeWithSeconds(1, preferredTimescale: 1)
            periodicTimeObserver = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: nil, using: { [weak self] time in
                guard let self = self,
                    let currentItem = audioPlayer.currentItem,
                    !self.seekIsActive else { return }
                self.setTrackTimeLabelsWithElapsedTime(audioPlayer.currentTime())
                self.setNowPlayingInfoCenter(for: self.playerItems[self.queuePlayerItemIndex])

                let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: audioPlayer.currentItem)
                let percentage = Float(elapsedTimeInSeconds / CMTimeGetSeconds(currentItem.duration))
                if !percentage.isNaN {
                    self.slider.setValue(percentage, animated: true)
                    (UIApplication.shared.delegate as? GRDAppDelegate)?.updateMiniPlayerDisplay(percentage: percentage)
                    // Update the file's resumeLocation remotely: every 5 seconds or when it's finished playing
                    let updateProgressRemotely = elapsedTimeInSeconds < 1  || elapsedTimeInSeconds == CMTimeGetSeconds(currentItem.duration) || Int(elapsedTimeInSeconds) % 5 == 0
                    (audioPlayer.currentItem as? GRDAVPlayerItem)?.file.updateResumeLocation(Int(elapsedTimeInSeconds), locallyOnly: !updateProgressRemotely)
                    notifyAudioInfoForWebView()
                }
            })
        }
    }

    func formattedTimeString(for secondsToFormat: Int) -> String? {
        let seconds = secondsToFormat % 60
        let minutes = (secondsToFormat / 60) % 60
        let hours = secondsToFormat / 3600
        if hours > 0 {
            return String(format: "%01d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%01d:%02d", minutes, seconds)
    }
    
    func setTrackInformationLabels(_ playerItem: GRDAVPlayerItem?) {
        fileNameLabel.text = playerItem?.file.displayName()
        trackLabel.text = "\(Int(queuePlayerItemIndex) + 1) of \(UInt(files.count))"
    }

    func setTrackTimeLabelsWithElapsedTime(_ currentlyElapsedTime: CMTime) {
        guard let duration = audioPlayer?.currentItem?.duration else { return }
        var elapsedTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentlyElapsedTime), preferredTimescale: duration.timescale)
        let secondsElapsed = CMTimeGetSeconds(elapsedTime).rounded()
        if secondsElapsed < 0 || secondsElapsed.isNaN {
            elapsedTime = CMTimeMake(value: 0, timescale: duration.timescale)
            timeElapsedLabel.text = "0:00"
        } else {
            timeElapsedLabel.text = formattedTimeString(for: Int(secondsElapsed))
        }
        let timeDifferenceInSeconds = CMTimeGetSeconds(CMTimeSubtract(duration, elapsedTime))
        if timeDifferenceInSeconds < 0 || timeDifferenceInSeconds.isNaN {
            timeRemainingLabel.text = "0:00"
        } else {
            timeRemainingLabel.text = formattedTimeString(for: Int(timeDifferenceInSeconds))
        }
    }

    func togglePlayback() {
        guard let audioPlayer = audioPlayer else { return }
        if audioPlayer.rate == 0.0 && audioPlayer.error == nil {
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            playAudioPlayerAtSavedRate()
            notifyAudioInfoForWebView()
        } else {
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
            audioPlayer.pause()
            if let file = (audioPlayer.currentItem as? GRDAVPlayerItem)?.file {
                let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: audioPlayer.currentItem)
                file.updateResumeLocation(Int(elapsedTimeInSeconds))
            }
            notifyAudioInfoForWebView()
        }
    }

    func updatePlaybackButtons() {
        guard let audioPlayer = audioPlayer else { return }
        playPauseButton.setImage(UIImage(named: audioPlayer.rate == 0.0 && audioPlayer.error == nil ? "play" : "pause"), for: .normal)
        notifyAudioInfoForWebView()
    }

    @objc func playbackHasStalled(_ notification: Notification?) {
        playPauseButton.setImage(UIImage(named: "play"), for: .normal)
        audioPlayer?.pause()
        notifyAudioInfoForWebView()
    }

    @objc func automaticallyAdvance(toNextTrack notification: Notification?) {
        if let audioPlayer = audioPlayer,
           let file = (audioPlayer.currentItem as? GRDAVPlayerItem)?.file {
            file.updateResumeLocation((file.content_length as? Int) ?? Int(getElapsedTimeInSeconds(for: audioPlayer.currentItem)))
            notifyAudioInfoForWebView()
        }
        playerHasNotLoadedMedia()
        seekTimer?.invalidate()
        advanceTrack(wasAutomatic: true)
    }
    
    func notifyAudioInfoForWebView() {
        if let audioPlayer = audioPlayer,
           let file = (audioPlayer.currentItem as? GRDAVPlayerItem)?.file {
            NotificationCenter.default.post(name: NSNotification.Name(GRDNotificationStrings.audioInfoForWebViewNotificationString()), object: nil, userInfo: ["file": file, "isPlaying": audioPlayer.rate > 0.0])
        }
    }

    func advanceTrack(wasAutomatic: Bool = false) {
        if !wasAutomatic, let audioPlayer = audioPlayer {
            let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: audioPlayer.currentItem)
            (audioPlayer.currentItem as? GRDAVPlayerItem)?.file.updateResumeLocation(Int(elapsedTimeInSeconds))
            notifyAudioInfoForWebView()
        }
        
        playerHasNotLoadedMedia()
        let playerItem = nextPlayerItem()
        setTrackInformationLabels(playerItem)
        setupAudioPlayer(for: playerItem, isFirstLoad: true)
        timeElapsedLabel.text = "0:00"
        slider.value = 0
    }

    func previousTrack() {
        guard let audioPlayer = audioPlayer else { return }
        if getElapsedTimeInSeconds(for: audioPlayer.currentItem) < elapsedTimeLowerLimit {
            (audioPlayer.currentItem as? GRDAVPlayerItem)?.file.updateResumeLocation(0)
            notifyAudioInfoForWebView()
            let playerItem = previousPlayerItem()
            setTrackInformationLabels(playerItem)
            setupAudioPlayer(for: playerItem, isFirstLoad: true)
            timeElapsedLabel.text = "0:00"
            slider.value = 0
        } else {
            audioPlayer.seek(to: CMTimeMakeWithSeconds(0, preferredTimescale: 1))
            notifyAudioInfoForWebView()
        }
    }

    func previousPlayerItem() -> GRDAVPlayerItem {
        if queuePlayerItemIndex == 0 {
            queuePlayerItemIndex = playerItems.count - 1
        } else {
            queuePlayerItemIndex -= 1
        }
        return playerItems[queuePlayerItemIndex]
    }

    func nextPlayerItem() -> GRDAVPlayerItem {
        if queuePlayerItemIndex == playerItems.count - 1 {
            queuePlayerItemIndex = 0
        } else {
            queuePlayerItemIndex += 1
        }
        return playerItems[queuePlayerItemIndex]
    }

    @objc func skipForward() {
        guard let audioPlayer = audioPlayer else { return }
        if audioPlayer.rate == 0.0 && audioPlayer.error == nil { return } // if paused
        guard let trackLength = audioPlayer.currentItem?.duration else { return }
        let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: audioPlayer.currentItem)
        let audioLengthInSeconds = Float(Int(trackLength.value) / Int(trackLength.timescale == 0 ? 1 : trackLength.timescale))
        if Float(elapsedTimeInSeconds + SKIP_FORWARD_SECONDS) > audioLengthInSeconds {
            seekTimer?.invalidate()
        }
        seekIsActive = true
        audioPlayer.seek(to: CMTimeMakeWithSeconds(Float64(elapsedTimeInSeconds + SKIP_FORWARD_SECONDS), preferredTimescale: 1)) { _ in
            self.seekIsActive = false
        }
        notifyAudioInfoForWebView()
    }

    @objc func skipBackward() {
        guard let audioPlayer = audioPlayer else { return }
        if audioPlayer.rate == 0.0 && audioPlayer.error == nil { return } // if paused
        let elapsedTimeInSeconds = getElapsedTimeInSeconds(for: audioPlayer.currentItem)
        if elapsedTimeInSeconds - SKIP_BACKWARD_SECONDS < 0.0 {
            seekTimer?.invalidate()
        }
        seekIsActive = true
        audioPlayer.seek(to: CMTimeMakeWithSeconds(Float64(elapsedTimeInSeconds - SKIP_BACKWARD_SECONDS), preferredTimescale: 1)) { _ in
            self.seekIsActive = false
        }
        notifyAudioInfoForWebView()
    }

    func setNowPlayingInfoCenter(for playerItem: GRDAVPlayerItem?) {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = playerItem?.file.displayName()
        info[MPMediaItemPropertyArtist] = playerItem?.file.product?.creator_name ?? playerItem?.file.installment?.creator_name
        if let productImage = productImageView?.image {
            let artwork = MPMediaItemArtwork(boundsSize: productImageView.bounds.size, requestHandler: { size in
                return productImage
            })
            info[MPMediaItemPropertyArtwork] = artwork
        }
        guard let currentItem = audioPlayer?.currentItem else { return }
        info[MPMediaItemPropertyAssetURL] = playerItem?.file.bestAvailableUrl
        info[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: Float(CMTimeGetSeconds(currentItem.duration)))
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: Float(CMTimeGetSeconds(currentItem.currentTime())))
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func remoteTogglePlayPause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        togglePlayback()
        return .success
    }

    func remoteSkipBackward(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        skipBackward()
        return .success
    }

    func remoteSkipForward(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        skipForward()
        return .success
    }

    func playerHasLoadedMedia() {
        slider.isEnabled = true
        playPauseButton.isEnabled = true
    }

    func playerHasNotLoadedMedia() {
        slider.isEnabled = false
        playPauseButton.isEnabled = false
    }

    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @IBAction func creatorNameClicked(_ sender: UIButton) {
        if let profileUrlString = initialFile?.product?.creator_profile_url ?? initialFile?.installment?.creator_profile_url,
            let url = URL(string: profileUrlString) {
            let vc = SFSafariViewController(url: url)
            isOpeningSafari = true
            present(vc, animated: true)
        }
    }
    
    @IBAction func collapseButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        (UIApplication.shared.delegate as? GRDAppDelegate)?.showMiniPlayer(audioPlayerVC: self)
        isCollapsingToMiniPlayer = true
        dismiss(animated: true)
    }
    
    @IBAction func closeButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss(animated: true)
    }
    
    @IBAction func airplayButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let routePickerButton = routePickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            routePickerButton.sendActions(for: .touchUpInside)
        }
    }
    
    @IBAction func playbackSpeedButtonClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        sender.tag = (sender.tag + 1) % playbackSpeeds.count
        let playbackSpeed = playbackSpeeds[sender.tag]
        playbackSpeedButton.setImage(UIImage(named: "playback-speed-\(playbackSpeed)x"), for: .normal)
        if let rate = audioPlayer?.rate, rate > 0.0 {
            audioPlayer?.rate = Float(playbackSpeed)!
        }
        UserDefaults.standard.set(playbackSpeed, forKey: playbackSpeedUserDefaultsKey)
    }
}

extension AudioPlayerViewController: AVRoutePickerViewDelegate {
    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        updatePlaybackButtons()
    }
}
