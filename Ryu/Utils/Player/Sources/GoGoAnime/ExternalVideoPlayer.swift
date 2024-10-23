//
//  ExternalVideoPlayer.swift
//  Ryu
//
//  Created by Francesco on 03/07/24.
//

import AVKit
import WebKit
import Combine
import GoogleCast

class ExternalVideoPlayer: UIViewController, WKNavigationDelegate, CustomPlayerViewDelegate {
    func customPlayerViewDidDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private var webView: WKWebView?
    private var playerViewController: AVPlayerViewController?
    private var streamURL: String
    private var activityIndicator: UIActivityIndicatorView?
    private var cell: EpisodeCell
    private var fullURL: String
    private weak var animeDetailsViewController: AnimeDetailViewController?
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var isVideoPlaying = false
    private var extractionTimer: Timer?
    
    private var retryCount = 0
    private var maxRetries: Int {
        UserDefaults.standard.integer(forKey: "maxRetries")
    }
    
    private var originalRate: Float = 1.0
    private var holdGesture: UILongPressGestureRecognizer?
    private var qualityOptions: [(name: String, url: String)] = []
    
    private let userAgents = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (iPad; CPU OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    ]
    
    private var extractionCancellable: AnyCancellable?
    
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
        view.backgroundColor = .secondarySystemBackground
        setupWebView()
        setupActivityIndicator()
        setupHoldGesture()
        setupNotificationObserver()
        startExtractionProcess()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
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
    
    private func setupHoldGesture() {
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
        let configuration = WKWebViewConfiguration()
        
        let randomUserAgent = userAgents.randomElement() ?? userAgents[0]
        configuration.applicationNameForUserAgent = randomUserAgent
        
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.isHidden = true
        
        if let webView = webView {
            view.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        if let url = URL(string: streamURL) {
            let request = URLRequest(url: url)
            webView?.load(request)
        }
    }
    
    private func startExtractionProcess() {
        extractionCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.extractVideoLinks()
            }
    }
    
    private func stopExtractionProcess() {
        extractionCancellable?.cancel()
        extractionCancellable = nil
    }
    
    private func extractVideoLinks() {
        guard !isVideoPlaying else {
            stopExtractionProcess()
            return
        }
        
        let script = """
         function extractLinks() {
             const links = [];
             const downloadDivs = document.querySelectorAll('#content-download .mirror_link .dowload a');
             for (const a of downloadDivs) {
                 if (a.textContent.includes('Download') && a.textContent.includes('mp4')) {
                     const text = a.textContent.trim();
                     const qualityMatch = text.match(/\\((\\d+P) - mp4\\)/);
                     const quality = qualityMatch ? qualityMatch[1].replace('P', 'p') : '';
                     if (quality) {
                         links.push({name: quality, url: a.href});
                     }
                 }
             }
             return links;
         }
         extractLinks();
         """
        
        webView?.evaluateJavaScript(script) { [weak self] (result, error) in
            guard let self = self, !self.isVideoPlaying else { return }
            
            if let links = result as? [[String: String]], !links.isEmpty {
                self.qualityOptions = links.compactMap { link in
                    guard let name = link["name"], !name.isEmpty, let url = link["url"] else { return nil }
                    return (name: name, url: url)
                }
                self.stopExtractionProcess()
                self.handleQualitySelection()
            } else if let error = error {
                print("Error extracting video links: \(error)")
                self.retryExtractVideoLinks()
            }
        }
    }
    
    private func retryExtractVideoLinks() {
        if !isVideoPlaying && retryCount < maxRetries {
            retryCount += 1
            print("Retrying extraction... Attempt \(retryCount) of \(maxRetries)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.extractVideoLinks()
            }
        } else if !isVideoPlaying {
            stopExtractionProcess()
            activityIndicator?.stopAnimating()
            print("Failed to extract video links after \(maxRetries) attempts.")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func handleQualitySelection() {
        activityIndicator?.stopAnimating()
        
        if qualityOptions.isEmpty {
            print("No quality options available.")
            return
        }
        
        if let preferredQuality = UserDefaults.standard.string(forKey: "preferredQuality"),
           let matchingOption = qualityOptions.first(where: { $0.name.contains(preferredQuality) }) {
            if let url = URL(string: matchingOption.url) {
                handleVideoURL(url: url)
            } else {
                print("Invalid URL for preferred quality.")
            }
        } else {
            showQualityPicker()
        }
    }
    
    private func showQualityPicker() {
        let alert = UIAlertController(title: "Select Prefered Quality", message: nil, preferredStyle: .actionSheet)
        
        for option in qualityOptions {
            alert.addAction(UIAlertAction(title: option.name, style: .default, handler: { [weak self] _ in
                self?.handleVideoURL(url: URL(string: option.url)!)
            }))
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func handleVideoURL(url: URL) {
        DispatchQueue.main.async {
            self.isVideoPlaying = true
            self.stopExtractionProcess()
            self.activityIndicator?.stopAnimating()
            
            if UserDefaults.standard.bool(forKey: "isToDownload") {
                self.handleDownload(url: url)
            }
            else if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
                self.castVideoToGoogleCast(videoURL: url)
                self.dismiss(animated: true, completion: nil)
            }
            else if let selectedPlayer = UserDefaults.standard.string(forKey: "mediaPlayerSelected") {
                if selectedPlayer == "VLC" || selectedPlayer == "Infuse" || selectedPlayer == "OutPlayer" {
                    self.animeDetailsViewController?.openInExternalPlayer(player: selectedPlayer, url: url)
                    self.dismiss(animated: true, completion: nil)
                } else if selectedPlayer == "Custom" {
                    let videoTitle = self.animeDetailsViewController?.animeTitle ?? "Anime"
                    let imageURL = self.animeDetailsViewController?.imageUrl ?? ""
                    let customPlayerVC = CustomPlayerView(videoTitle: videoTitle, videoURL: url, cell: self.cell, fullURL: self.fullURL, image: imageURL)
                    customPlayerVC.modalPresentationStyle = .fullScreen
                    customPlayerVC.delegate = self
                    self.present(customPlayerVC, animated: true, completion: nil)
                } else {
                    self.playVideo(url: url.absoluteString)
                }
            }
            else {
                self.playVideo(url: url.absoluteString)
            }
        }
    }
    
    private func handleDownload(url: URL) {
        UserDefaults.standard.set(false, forKey: "isToDownload")
        
        self.dismiss(animated: true, completion: nil)
        
        let downloadManager = DownloadManager.shared
        let title = self.animeDetailsViewController?.animeTitle ?? "Anime Download"
        
        downloadManager.startDownload(url: url, title: title, progress: { progress in
            DispatchQueue.main.async {
                print("Download progress: \(progress * 100)%")
            }
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
            builder.contentType = "video/mp4"
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
                let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(self.fullURL)")
                if lastPlayedTime > 0 {
                    let options = GCKMediaLoadOptions()
                    options.playPosition = TimeInterval(lastPlayedTime)
                    remoteMediaClient.loadMedia(mediaInformation, with: options)
                } else {
                    remoteMediaClient.loadMedia(mediaInformation)
                }
            }
        }
    }
    
    private func playVideo(url: String) {
        guard let videoURL = URL(string: url) else {
            print("Invalid video URL")
            return
        }
        
        let player = AVPlayer(url: videoURL)
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
        
        self.player = player
        self.playerViewController = playerViewController
        self.addPeriodicTimeObserver()
        
        player.play()
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
            
            if let viewController = self.animeDetailsViewController,
               let episodeNumber = viewController.episodes[safe: viewController.currentEpisodeIndex]?.number {
                
                if let episodeNumberInt = Int(episodeNumber) {
                    let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "GoGoAnime"
                    
                    let continueWatchingItem = ContinueWatchingItem(
                        animeTitle: viewController.animeTitle ?? "Unknown Anime",
                        episodeTitle: "Ep. \(episodeNumberInt)",
                        episodeNumber: episodeNumberInt,
                        imageURL: viewController.imageUrl ?? "",
                        fullURL: self.fullURL,
                        lastPlayedTime: currentTime,
                        totalTime: duration,
                        source: selectedMediaSource
                    )
                    ContinueWatchingManager.shared.saveItem(continueWatchingItem)

                    let shouldSendPushUpdates = UserDefaults.standard.bool(forKey: "sendPushUpdates")

                    if shouldSendPushUpdates && remainingTime < 90 && !(viewController.hasSentUpdate) {
                        let cleanedTitle = viewController.cleanTitle(viewController.animeTitle ?? "Unknown Anime")

                        viewController.fetchAnimeID(title: cleanedTitle) { animeID in
                            let aniListMutation = AniListMutation()
                            aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: episodeNumberInt) { result in
                                switch result {
                                case .success():
                                    print("Successfully updated anime progress.")
                                case .failure(let error):
                                    print("Failed to update anime progress: \(error.localizedDescription)")
                                }
                            }
                            
                            viewController.hasSentUpdate = true
                        }
                    }
                } else {
                    print("Error: Failed to convert episodeNumber '\(episodeNumber)' to an Int.")
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UserDefaults.standard.set(false, forKey: "isToDownload")
        cleanup()
    }
    
    private func cleanup() {
        isVideoPlaying = false
        player?.pause()
        player = nil
        
        playerViewController?.willMove(toParent: nil)
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
        
        stopExtractionProcess()
        
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
    }
    
    deinit {
        cleanup()
        NotificationCenter.default.removeObserver(self)
    }
}
