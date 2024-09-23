//
//  ExternalVideoPlayerKura.swift
//  Ryu
//
//  Created by Francesco on 09/07/24.
//

import AVKit
import WebKit
import SwiftSoup
import GoogleCast

class ExternalVideoPlayerKura: UIViewController, GCKRemoteMediaClientListener {
    private let streamURL: String
    private var webView: WKWebView?
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var activityIndicator: UIActivityIndicatorView?
    
    private var retryCount = 0
    private let maxRetries: Int
    
    private var cell: EpisodeCell
    private var fullURL: String
    private weak var animeDetailsViewController: AnimeDetailViewController?
    private var timeObserverToken: Any?
    
    private var originalRate: Float = 1.0
    private var holdGesture: UILongPressGestureRecognizer?
    private var videoURLs: [String: String] = [:]
    
    init(streamURL: String, cell: EpisodeCell, fullURL: String, animeDetailsViewController: AnimeDetailViewController) {
        self.streamURL = streamURL
        self.cell = cell
        self.fullURL = fullURL
        self.animeDetailsViewController = animeDetailsViewController
        self.maxRetries = UserDefaults.standard.integer(forKey: "maxRetries") > 0 ? UserDefaults.standard.integer(forKey: "maxRetries") : 10
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
        UserDefaults.standard.set(false, forKey: "isToDownload")
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
        view.backgroundColor = .secondarySystemBackground
        setupActivityIndicator()
        setupWebView()
    }
    
    private func setupHoldGesture() {
        holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHoldGesture(_:)))
        holdGesture?.minimumPressDuration = 0.5
        view.addGestureRecognizer(holdGesture!)
    }
    
    @objc private func handleHoldGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began: beginHoldSpeed()
        case .ended, .cancelled: endHoldSpeed()
        default: break
        }
    }
    
    private func beginHoldSpeed() {
        guard let player = player else { return }
        originalRate = player.rate
        player.rate = UserDefaults.standard.float(forKey: "holdSpeedPlayer")
    }
    
    private func endHoldSpeed() {
        player?.rate = originalRate
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator?.hidesWhenStopped = true
        
        if let activityIndicator = activityIndicator {
            view.addSubview(activityIndicator)
            
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            activityIndicator.startAnimating()
        }
    }
    
    private func setupWebView() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView?.navigationDelegate = self
    }
    
    private func loadInitialURL() {
        guard let url = URL(string: streamURL) else {
            print("Invalid stream URL")
            return
        }
        webView?.load(URLRequest(url: url))
    }
    
    private func extractVideoSources() {
        webView?.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self, let htmlString = result as? String else {
                self?.retryExtraction()
                return
            }
            
            self.handleVideoSources(htmlString: htmlString)
        }
    }
    
    private func handleVideoSources(htmlString: String) {
        do {
            let doc = try SwiftSoup.parse(htmlString)
            let videoElement = try doc.select("video#player").first()
            let sourceElements = try videoElement?.select("source")
            
            sourceElements?.forEach { element in
                if let _ = try? element.attr("size"),
                   let url = try? element.attr("src") {
                    let id = element.id()
                    let qualityNumber = id.replacingOccurrences(of: "source", with: "")
                    self.videoURLs[qualityNumber + "p"] = url
                }
            }
            
            DispatchQueue.main.async {
                if self.videoURLs.isEmpty {
                    self.retryExtraction()
                } else {
                    self.selectQuality()
                    self.activityIndicator?.stopAnimating()
                }
            }
        } catch {
            print("Error parsing HTML: \(error)")
            self.retryExtraction()
        }
    }
    
    private func selectQuality() {
        let preferredQuality = UserDefaults.standard.string(forKey: "preferredQuality") ?? "720p"
        
        if let url = videoURLs[preferredQuality] {
            handleVideoURL(url: URL(string: url)!)
        } else {
            let availableQualities = videoURLs.keys.map { Int($0.replacingOccurrences(of: "p", with: "")) ?? 0 }.sorted()
            let preferredQualityValue = Int(preferredQuality.replacingOccurrences(of: "p", with: "")) ?? 720
            
            if let closestQuality = availableQualities.min(by: { abs($0 - preferredQualityValue) < abs($1 - preferredQualityValue) }) {
                if let url = videoURLs["\(closestQuality)p"] {
                    handleVideoURL(url: URL(string: url)!)
                } else {
                    showQualitySelectionPopup()
                }
            } else {
                showQualitySelectionPopup()
            }
        }
    }
    
    private func showQualitySelectionPopup() {
        let alertController = UIAlertController(title: "Select Prefered Quality", message: nil, preferredStyle: .actionSheet)
        
        for (quality, urlString) in videoURLs.sorted(by: {
            Int($0.key.replacingOccurrences(of: "p", with: "")) ?? 0 >
            Int($1.key.replacingOccurrences(of: "p", with: "")) ?? 0
        }) {
            alertController.addAction(UIAlertAction(title: quality, style: .default) { [weak self] _ in
                if let url = URL(string: urlString) {
                    self?.handleVideoURL(url: url)
                }
            })
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func handleVideoURL(url: URL) {
        if UserDefaults.standard.bool(forKey: "isToDownload") {
            handleDownload(url: url)
        } else if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
            castVideoToGoogleCast(videoURL: url)
            dismiss(animated: true)
        } else {
            let selectedPlayer = UserDefaults.standard.string(forKey: "mediaPlayerSelected") ?? "Default"
            switch selectedPlayer {
            case "VLC", "Infuse", "OutPlayer":
                animeDetailsViewController?.openInExternalPlayer(player: selectedPlayer, url: url)
                dismiss(animated: true)
            case "Custom":
                let videoTitle = animeDetailsViewController?.animeTitle ?? "Anime"
                let imageURL = animeDetailsViewController?.imageUrl ?? ""
                let customPlayerVC = CustomPlayerView(videoTitle: videoTitle, videoURL: url, cell: self.cell, fullURL: self.fullURL, image: imageURL)
                customPlayerVC.modalPresentationStyle = .fullScreen
                customPlayerVC.delegate = self
                present(customPlayerVC, animated: true)
            default:
                playOrCastVideo(url: url)
            }
        }
    }
    
    private func handleDownload(url: URL) {
        UserDefaults.standard.set(false, forKey: "isToDownload")
        dismiss(animated: true)
        
        let downloadManager = DownloadManager.shared
        let title = animeDetailsViewController?.animeTitle ?? "Anime Download"
        downloadManager.startDownload(url: url, title: title, progress: { progress in
            print("Download progress: \(progress * 100)%")
        }) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let downloadURL):
                    print("Download completed. File saved at: \(downloadURL)")
                    self?.animeDetailsViewController?.showAlert(withTitle: "Download Completed!", message: "You can find your download in the Library -> Downloads.")
                case .failure(let error):
                    print("Download failed with error: \(error.localizedDescription)")
                    self?.animeDetailsViewController?.showAlert(withTitle: "Download Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func castVideoToGoogleCast(videoURL: URL) {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        
        if UserDefaults.standard.bool(forKey: "fullTitleCast") {
            metadata.setString(animeDetailsViewController?.animeTitle ?? "Unknown Anime", forKey: kGCKMetadataKeyTitle)
        } else {
            let episodeNumber = (animeDetailsViewController?.currentEpisodeIndex ?? -1) + 1
            metadata.setString("Episode \(episodeNumber)", forKey: kGCKMetadataKeyTitle)
        }
        
        if UserDefaults.standard.bool(forKey: "animeImageCast"), let imageURL = URL(string: animeDetailsViewController?.imageUrl ?? "") {
            metadata.addImage(GCKImage(url: imageURL, width: 480, height: 720))
        }
        
        let builder = GCKMediaInformationBuilder(contentURL: videoURL)
        builder.contentType = "video/mp4"
        builder.metadata = metadata
        builder.streamType = UserDefaults.standard.string(forKey: "castStreamingType") == "live" ? .live : .buffered
        
        if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
            let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
            if lastPlayedTime > 0 {
                let options = GCKMediaLoadOptions()
                options.playPosition = TimeInterval(lastPlayedTime)
                remoteMediaClient.loadMedia(builder.build(), with: options)
            } else {
                remoteMediaClient.loadMedia(builder.build())
            }
        }
    }
    
    private func playOrCastVideo(url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewController.didMove(toParent: self)
        
        let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
        if lastPlayedTime > 0 {
            player.seek(to: CMTime(seconds: lastPlayedTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
        
        player.play()
        self.player = player
        self.playerViewController = playerViewController
        addPeriodicTimeObserver()
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let currentItem = self.player?.currentItem, currentItem.duration.seconds.isFinite else {
                return
            }
            
            self.updatePlaybackProgress(time: time, duration: currentItem.duration.seconds)
        }
    }
    
    private func updatePlaybackProgress(time: CMTime, duration: Double) {
        let currentTime = time.seconds
        let progress = currentTime / duration
        let remainingTime = duration - currentTime
        
        cell.updatePlaybackProgress(progress: Float(progress), remainingTime: remainingTime)
        UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(fullURL)")
        UserDefaults.standard.set(duration, forKey: "totalTime_\(fullURL)")
        
        updateContinueWatchingItem(currentTime: currentTime, duration: duration)
        sendPushUpdates(remainingTime: remainingTime)
    }
    
    private func updateContinueWatchingItem(currentTime: Double, duration: Double) {
        if let viewController = self.animeDetailsViewController,
           let episodeNumber = viewController.episodes[safe: viewController.currentEpisodeIndex]?.number {
            
            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
            
            let continueWatchingItem = ContinueWatchingItem(
                animeTitle: viewController.animeTitle ?? "Unknown Anime",
                episodeTitle: "Ep. \(episodeNumber)",
                episodeNumber: Int(episodeNumber) ?? 0,
                imageURL: viewController.imageUrl ?? "",
                fullURL: fullURL,
                lastPlayedTime: currentTime,
                totalTime: duration,
                source: selectedMediaSource
            )
            ContinueWatchingManager.shared.saveItem(continueWatchingItem)
        }
    }
    
    private func sendPushUpdates(remainingTime: Double) {
        guard let animeDetailsViewController = animeDetailsViewController, UserDefaults.standard.bool(forKey: "sendPushUpdates"), remainingTime < 120, !animeDetailsViewController.hasSentUpdate else {
            return
        }
        
        let cleanedTitle = animeDetailsViewController.cleanTitle(animeDetailsViewController.animeTitle ?? "Unknown Anime")
        animeDetailsViewController.fetchAnimeID(title: cleanedTitle) { [weak self] animeID in
            let aniListMutation = AniListMutation()
            aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: Int(self?.cell.episodeNumber ?? "0") ?? 0) { result in
                switch result {
                case .success: print("Successfully updated anime progress.")
                case .failure(let error): print("Failed to update anime progress: \(error.localizedDescription)")
                }
            }
            animeDetailsViewController.hasSentUpdate = true
        }
    }
    
    private func retryExtraction() {
        retryCount += 1
        if retryCount < maxRetries {
            print("Retrying extraction (Attempt \(retryCount + 1))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadInitialURL()
            }
        } else {
            print("Max retries reached. Unable to find video sources.")
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.dismiss(animated: true)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if UserDefaults.standard.bool(forKey: "AutoPlay"), let animeDetailsViewController = animeDetailsViewController {
            let hasNextEpisode = animeDetailsViewController.isReverseSorted ?
            (animeDetailsViewController.currentEpisodeIndex > 0) :
            (animeDetailsViewController.currentEpisodeIndex < animeDetailsViewController.episodes.count - 1)
            
            if hasNextEpisode {
                dismiss(animated: true) { [weak self] in
                    self?.playNextEpisode()
                }
            } else {
                dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    private func playNextEpisode() {
        guard let animeDetailsViewController = animeDetailsViewController else {
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
}

extension ExternalVideoPlayerKura: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        extractVideoSources()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
        retryExtraction()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
        retryExtraction()
    }
}

extension ExternalVideoPlayerKura: CustomPlayerViewDelegate {
    func customPlayerViewDidDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}
