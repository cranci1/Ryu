//
//  ExternalVideoPlayerJK.swift
//  Ryu
//
//  Created by Francesco on 13/07/24.
//

import AVKit
import WebKit
import GoogleCast

class ExternalVideoPlayerJK: UIViewController, WKNavigationDelegate, GCKRemoteMediaClientListener {
    private let streamURL: String
    private var webView: WKWebView?
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var activityIndicator: UIActivityIndicatorView?
    
    private var retryCount = 0
    private let maxRetries = 10
    
    private var cell: EpisodeCell
    private var fullURL: String
    private weak var animeDetailsViewController: AnimeDetailViewController?
    private var timeObserverToken: Any?
    
    private var originalRate: Float = 1.0
    private var holdGesture: UILongPressGestureRecognizer?
    
    init(streamURL: String, cell: EpisodeCell, fullURL: String, animeDetailsViewController: AnimeDetailViewController) {
        self.streamURL = streamURL
        self.cell = cell
        self.fullURL = fullURL
        self.animeDetailsViewController = animeDetailsViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialURL()
        setupHoldGesture()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanup()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UserDefaults.standard.bool(forKey: "AlwaysLandscape") {
            return .landscape
        } else {
            return .all
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return playerViewController
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return playerViewController
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.secondarySystemBackground
        setupActivityIndicator()
        setupWebView()
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.color = .label
        activityIndicator?.startAnimating()
        activityIndicator?.center = view.center
        if let activityIndicator = activityIndicator {
            view.addSubview(activityIndicator)
        }
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
    }
    
    private func loadInitialURL() {
        guard let url = URL(string: streamURL) else {
            print("Invalid stream URL")
            return
        }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    func setupHoldGesture() {
        holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHoldGesture(_:)))
        holdGesture?.minimumPressDuration = 0.5
        if let holdGesture = holdGesture {
            view.addGestureRecognizer(holdGesture)
        }
    }
    
    @objc private func handleHoldGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            beginHoldSpeed()
        case .ended, .cancelled:
            endHoldSpeed()
        default:
            break
        }
    }
    
    private func beginHoldSpeed() {
        guard let player = player else { return }
        originalRate = player.rate
        let holdSpeed = UserDefaults.standard.float(forKey: "holdSpeedPlayer")
        player.rate = holdSpeed
    }
    
    private func endHoldSpeed() {
        player?.rate = originalRate
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.simulateClickInIframe()
        }
    }
    
    private func simulateClickInIframe() {
        let jsCode = """
        var iframe = document.querySelector('iframe.player_conte');
        var iframeDocument = iframe.contentDocument || iframe.contentWindow.document;
        var videoElement = iframeDocument.querySelector('video');
        var clickEvent = document.createEvent('MouseEvents');
        clickEvent.initMouseEvent('click', true, true, window);
        videoElement.dispatchEvent(clickEvent);
        videoElement.getAttribute('src');
        """
        
        webView?.evaluateJavaScript(jsCode) { [weak self] result, error in
            self?.activityIndicator?.stopAnimating()
            if let videoSrc = result as? String, error == nil {
                self?.handleVideoURL(url: URL(string: videoSrc)!)
            } else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                self?.retryExtraction()
            }
        }
    }
    
    private func handleVideoURL(url: URL) {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            
            if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
                self.castVideoToGoogleCast(videoURL: url)
                self.dismiss(animated: true, completion: nil)
            }
            else if let selectedPlayer = UserDefaults.standard.string(forKey: "mediaPlayerSelected") {
                if selectedPlayer == "VLC" || selectedPlayer == "Infuse" || selectedPlayer == "OutPlayer" {
                    self.animeDetailsViewController?.openInExternalPlayer(player: selectedPlayer, url: url)
                } else if selectedPlayer == "Experimental" {
                    let videoTitle = self.animeDetailsViewController?.animeTitle ?? "Anime"
                    let customPlayerVC = CustomPlayerView(videoTitle: videoTitle, videoURL: url)
                    customPlayerVC.modalPresentationStyle = .fullScreen
                    customPlayerVC.delegate = self
                    self.present(customPlayerVC, animated: true, completion: nil)
                } else {
                    self.playOrCastVideo(url: url)
                }
            }
            else {
                self.playOrCastVideo(url: url)
            }
        }
    }
    
    private func playOrCastVideo(url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.addChild(playerViewController)
        self.view.addSubview(playerViewController.view)
        
        playerViewController.view.frame = self.view.bounds
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewController.didMove(toParent: self)
        
        let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(self.fullURL)")
        
        if lastPlayedTime > 0 {
            player.seek(to: CMTime(seconds: lastPlayedTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
        
        player.play()
        
        self.player = player
        self.playerViewController = playerViewController
        self.addPeriodicTimeObserver()
    }
    
    private func castVideoToGoogleCast(videoURL: URL) {
        DispatchQueue.main.async {
            let metadata = GCKMediaMetadata(metadataType: .movie)
            
            if UserDefaults.standard.bool(forKey: "fullTitleCast") {
                if let animeTitle = self.animeDetailsViewController?.animeTitle {
                    metadata.setString(animeTitle, forKey: kGCKMetadataKeyTitle)
                } else {
                    print("Error: Anime title is missing.")
                }
            } else {
                let episodeNumber = (self.animeDetailsViewController?.currentEpisodeIndex ?? -1) + 1
                metadata.setString("Episode \(episodeNumber)", forKey: kGCKMetadataKeyTitle)
            }
            
            if UserDefaults.standard.bool(forKey: "animeImageCast") {
                if let imageURL = URL(string: self.animeDetailsViewController?.imageUrl ?? "") {
                    metadata.addImage(GCKImage(url: imageURL, width: 480, height: 720))
                } else {
                    print("Error: Anime image URL is missing or invalid.")
                }
            }
            
            let builder = GCKMediaInformationBuilder(contentURL: videoURL)
            builder.contentType = "application/x-mpegURL"
            builder.metadata = metadata
            
            let streamTypeString = UserDefaults.standard.string(forKey: "castStreamingType") ?? "buffered"
            switch streamTypeString {
            case "live":
                builder.streamType = .live
            default:
                builder.streamType = .buffered
            }
            
            let mediaInformation = builder.build()
            
            if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
                remoteMediaClient.add(self)
                
                let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(self.fullURL)")
                if lastPlayedTime > 0 {
                    let options = GCKMediaLoadOptions()
                    options.playPosition = lastPlayedTime
                    remoteMediaClient.loadMedia(mediaInformation, with: options)
                } else {
                    remoteMediaClient.loadMedia(mediaInformation)
                }
            }
        }
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let mediaStatus = mediaStatus else { return }
        
        let currentTime = mediaStatus.streamPosition
        let duration = mediaStatus.mediaInformation?.streamDuration ?? 0
        
        UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(self.fullURL)")
        UserDefaults.standard.set(duration, forKey: "totalTime_\(self.fullURL)")
        
        let progress = Float(currentTime / duration)
        let remainingTime = duration - currentTime
        self.cell.updatePlaybackProgress(progress: progress, remainingTime: remainingTime)
        
        let episodeNumber = Int(self.cell.episodeNumber) ?? 0
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "JKanime"
        
        let continueWatchingItem = ContinueWatchingItem(
            animeTitle: self.animeDetailsViewController?.animeTitle ?? "Unknown Anime",
            episodeTitle: "Ep. \(episodeNumber)",
            episodeNumber: episodeNumber,
            imageURL: self.animeDetailsViewController?.imageUrl ?? "",
            fullURL: self.fullURL,
            lastPlayedTime: currentTime,
            totalTime: duration,
            source: selectedMediaSource
        )
        ContinueWatchingManager.shared.saveItem(continueWatchingItem)
        
        if remainingTime < 120 && !(self.animeDetailsViewController?.hasSentUpdate ?? false) {
            updateAniListProgress()
        }
    }
    
    private func updateAniListProgress() {
        let cleanedTitle = self.animeDetailsViewController?.cleanTitle(self.animeDetailsViewController?.animeTitle ?? "Unknown Anime")
        
        self.animeDetailsViewController?.fetchAnimeID(title: cleanedTitle ?? "Title") { animeID in
            let aniListMutation = AniListMutation()
            aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: Int(self.cell.episodeNumber) ?? 0) { result in
                switch result {
                case .success():
                    print("Successfully updated anime progress.")
                case .failure(let error):
                    print("Failed to update anime progress: \(error.localizedDescription)")
                }
            }
            
            self.animeDetailsViewController?.hasSentUpdate = true
        }
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let currentItem = self.player?.currentItem,
                  currentItem.duration.seconds.isFinite else {
                      return
                  }
            
            let currentTime = time.seconds
            let duration = currentItem.duration.seconds
            let progress = currentTime / duration
            let remainingTime = duration - currentTime
            
            self.cell.updatePlaybackProgress(progress: Float(progress), remainingTime: remainingTime)
            
            UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(self.fullURL)")
            UserDefaults.standard.set(duration, forKey: "totalTime_\(self.fullURL)")
            
            let episodeNumber = Int(self.cell.episodeNumber) ?? 0
            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "JKanime"
            
            let continueWatchingItem = ContinueWatchingItem(
                animeTitle: self.animeDetailsViewController?.animeTitle ?? "Unknown Anime",
                episodeTitle: "Ep. \(episodeNumber)",
                episodeNumber: episodeNumber,
                imageURL: self.animeDetailsViewController?.imageUrl ?? "",
                fullURL: self.fullURL,
                lastPlayedTime: currentTime,
                totalTime: duration,
                source: selectedMediaSource
            )
            ContinueWatchingManager.shared.saveItem(continueWatchingItem)
            
            if remainingTime < 120 && !(self.animeDetailsViewController?.hasSentUpdate ?? false) {
                let cleanedTitle = self.animeDetailsViewController?.cleanTitle(self.animeDetailsViewController?.animeTitle ?? "Unknown Anime")
                
                self.animeDetailsViewController?.fetchAnimeID(title: cleanedTitle ?? "Title") { animeID in
                    let aniListMutation = AniListMutation()
                    aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: Int(self.cell.episodeNumber) ?? 0) { result in
                        switch result {
                        case .success():
                            print("Successfully updated anime progress.")
                        case .failure(let error):
                            print("Failed to update anime progress: \(error.localizedDescription)")
                        }
                    }
                    
                    self.animeDetailsViewController?.hasSentUpdate = true
                }
            }
        }
    }
    
    func playNextEpisode() {
        guard let animeDetailsViewController = self.animeDetailsViewController else {
            print("Error: animeDetailsViewController is nil")
            return
        }
        
        if animeDetailsViewController.isReverseSorted {
            animeDetailsViewController.currentEpisodeIndex -= 1
            if animeDetailsViewController.currentEpisodeIndex >= 0 {
                playEpisode(at: animeDetailsViewController.currentEpisodeIndex)
            } else {
                animeDetailsViewController.currentEpisodeIndex = 0
            }
        } else {
            animeDetailsViewController.currentEpisodeIndex += 1
            if animeDetailsViewController.currentEpisodeIndex < animeDetailsViewController.episodes.count {
                playEpisode(at: animeDetailsViewController.currentEpisodeIndex)
            } else {
                animeDetailsViewController.currentEpisodeIndex = animeDetailsViewController.episodes.count - 1
            }
        }
    }
    
    private func playEpisode(at index: Int) {
        guard let animeDetailsViewController = self.animeDetailsViewController,
              index >= 0 && index < animeDetailsViewController.episodes.count else {
                  return
              }
        
        let nextEpisode = animeDetailsViewController.episodes[index]
        if let cell = animeDetailsViewController.tableView.cellForRow(at: IndexPath(row: index, section: 2)) as? EpisodeCell {
            animeDetailsViewController.episodeSelected(episode: nextEpisode, cell: cell)
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if UserDefaults.standard.bool(forKey: "AutoPlay") {
            guard let animeDetailsViewController = self.animeDetailsViewController else { return }
            let hasNextEpisode = animeDetailsViewController.isReverseSorted ?
            (animeDetailsViewController.currentEpisodeIndex > 0) :
            (animeDetailsViewController.currentEpisodeIndex < animeDetailsViewController.episodes.count - 1)
            
            if hasNextEpisode {
                self.dismiss(animated: true) { [weak self] in
                    self?.playNextEpisode()
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
        
        playerViewController?.willMove(toParent: nil)
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
        
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func retryExtraction() {
        retryCount += 1
        if retryCount < maxRetries {
            print("Retrying extraction (Attempt \(retryCount + 1))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.loadInitialURL()
            }
        } else {
            print("Max retries reached. Unable to find video source.")
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.dismiss(animated: true)
            }
        }
    }
}

extension ExternalVideoPlayerJK: CustomPlayerViewDelegate {
    func customPlayerViewDidDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}
