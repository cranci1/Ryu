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

    init(streamURL: String, cell: EpisodeCell, fullURL: String, animeDetailsViewController: AnimeDetailViewController) {
        self.streamURL = streamURL
        self.cell = cell
        self.fullURL = fullURL
        self.animeDetailsViewController = animeDetailsViewController
        
        let userDefaultsRetries = UserDefaults.standard.integer(forKey: "maxRetries")
        self.maxRetries = userDefaultsRetries > 0 ? userDefaultsRetries : 10

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
    
    private func extractVideoSource() {
        webView?.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            guard let self = self, let htmlString = result as? String else {
                print("Error getting HTML: \(error?.localizedDescription ?? "Unknown error")")
                self?.retryExtraction()
                return
            }
            
            let qualityOptions = self.extractQualityOptions(from: htmlString)
            
            if !qualityOptions.isEmpty {
                DispatchQueue.main.async {
                    self.selectPreferredQuality(options: qualityOptions)
                }
            } else {
                print("No quality options found")
                self.retryExtraction()
            }
        }
    }
    
    private func extractVideoSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let videoElement = try doc.select("video").first(),
                  let sourceURLString = try videoElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            
            let pattern = #"<video[^>]+src="([^"]+)"#
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
                  let urlRange = Range(match.range(at: 1), in: htmlString) else {
                return nil
            }
            
            let urlString = String(htmlString[urlRange])
            return URL(string: urlString)
        }
    }
    
    private func extractQualityOptions(from htmlString: String) -> [(String, URL)] {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let qualityButtons = try doc.select("button[data-plyr='quality']")
            
            var qualityOptions: [(String, URL)] = []
            
            for button in qualityButtons {
                var quality = try button.attr("value")
                quality = quality.replacingOccurrences(of: "HD", with: "").replacingOccurrences(of: "SD", with: "").trimmingCharacters(in: .whitespaces)
                if let sourceElement = try doc.select("source[size='\(quality)']").first(),
                   let sourceURL = URL(string: try sourceElement.attr("src")) {
                    qualityOptions.append((quality, sourceURL))
                }
            }

            return qualityOptions
        } catch {
            print("Error parsing HTML for quality options: \(error)")
            return []
        }
    }
    
    private func selectPreferredQuality(options: [(String, URL)]) {
        let preferredQuality = UserDefaults.standard.string(forKey: "preferredQuality") ?? "1080p"
        
        var selectedOption: (String, URL)? = nil
        var closestOption: (String, URL)? = nil
        
        for option in options {
            let availableQuality = option.0
            if availableQuality == preferredQuality {
                selectedOption = option
                break
            } else if closestOption == nil || abs(preferredQuality.compare(availableQuality).rawValue) < abs(preferredQuality.compare(closestOption!.0).rawValue) {
                closestOption = option
            }
        }
        
        if let selectedOption = selectedOption {
            self.handleVideoURL(url: selectedOption.1)
        } else if let closestOption = closestOption {
            self.handleVideoURL(url: closestOption.1)
        } else {
            print("No suitable quality option found")
            retryExtraction()
        }
    }
    
    private func presentQualityOptionsMenu(options: [(String, URL)]) {
        let alertController = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)
        
        for (label, url) in options {
            let action = UIAlertAction(title: label, style: .default) { [weak self] _ in
                self?.handleVideoURL(url: url)
            }
            alertController.addAction(action)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func handleVideoURL(url: URL) {
        DispatchQueue.main.async {
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
            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
            
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
            
            if remainingTime < 120 && !(self.animeDetailsViewController!.hasSentUpdate) {
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
}

extension ExternalVideoPlayerKura: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        extractVideoSource()
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
