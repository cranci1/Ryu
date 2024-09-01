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

class ExternalVideoPlayer: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, GCKRemoteMediaClientListener {
    private var downloader = M3U8Downloader()
    private var qualityOptions: [(name: String, fileName: String)] = []
    
    private var webView: WKWebView?
    private var clickCancellable: AnyCancellable?
    private var loadingObserver: NSKeyValueObservation?
    private var playerViewController: AVPlayerViewController?
    private var isVideoPlaying = false
    private var streamURL: String
    private var activityIndicator: UIActivityIndicatorView?
    private var cell: EpisodeCell
    private var fullURL: String
    private weak var animeDetailsViewController: AnimeDetailViewController?
    private var player: AVPlayer?
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
        setupLoadingView()
        openWebView(fullURL: streamURL)
        setupHoldGesture()
        setupNotificationObserver()
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

    private func setupLoadingView() {
        view.backgroundColor = .secondarySystemBackground
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.color = .label
        activityIndicator?.startAnimating()
        activityIndicator?.center = view.center
        if let activityIndicator = activityIndicator {
            view.addSubview(activityIndicator)
        }
    }

    private func startMonitoringPlayState(interval: TimeInterval) {
        stopMonitoringPlayState()

        clickCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAndClickPlayButton()
            }

        checkAndClickPlayButton()
    }

    private func stopMonitoringPlayState() {
        clickCancellable?.cancel()
        clickCancellable = nil
    }

    private func checkAndClickPlayButton() {
        guard let webView = self.webView, !isVideoPlaying else {
            return
        }

        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "GoGoAnime"

        let script: String

        switch selectedMediaSource {
        case "GoGoAnime":
            script = """
            (function() {
                var player = jwplayer();
                if (player && player.getState() === 'idle') {
                    var playButton = document.querySelector('.jw-icon.jw-icon-display.jw-button-color.jw-reset');
                    if (playButton) {
                        playButton.click();
                        return 'Clicked play button for GoGoAnime';
                    }
                }
                return player ? player.getState() : 'Player not found';
            })();
            """
        default:
            script = """
            (function() {
                return 'Unknown media source';
            })();
            """
        }

        webView.evaluateJavaScript(script) { (result, error) in
            if let error = error {
                print("Error executing JavaScript: \(error)")
            } else if let result = result as? String {
                print("Player state: \(result)")
            }
        }
    }

    private func openWebView(fullURL: String) {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()
        contentController.add(self, name: "videoHandler")
        configuration.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: configuration)
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

        setupLoadingObserver()

        if let url = URL(string: fullURL) {
            let request = URLRequest(url: url)
            webView?.load(request)
        }
    }

    private func setupLoadingObserver() {
        loadingObserver = webView?.observe(\.isLoading, options: [.new]) { [weak self] _, change in
            if let isLoading = change.newValue, !isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.injectCustomJavaScript()
                    self?.startMonitoringPlayState(interval: 1.0)
                }
            }
        }
    }

    private func injectCustomJavaScript() {
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "GoGoAnime"

        let script: String

        switch selectedMediaSource {
        case "GoGoAnime":
            script = """
            function notifyVideoState(state, videoUrl) {
                window.webkit.messageHandlers.videoHandler.postMessage({state: state, url: videoUrl});
            }

            if (typeof jwplayer !== 'undefined') {
                var player = jwplayer();
                player.on('play', function() {
                    var videoUrl = player.getPlaylistItem().file;
                    notifyVideoState('play', videoUrl);
                });
                player.on('pause', function() { notifyVideoState('pause', null); });
                player.on('complete', function() { notifyVideoState('complete', null); });
                player.on('error', function() { notifyVideoState('error', null); });
            }
            """
        default:
            script = ""
        }

        webView?.evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                print("Error injecting custom JavaScript: \(error)")
            } else {
                self?.startCheckingForMediaPlayback()
            }
        }
    }
    
    private func startCheckingForMediaPlayback() {
          let script = """
          function checkMediaPlayback() {
              var video = document.querySelector('video');
              if (video && !video.paused) {
                  window.webkit.messageHandlers.videoHandler.postMessage({state: 'play', url: video.src});
                  return true;
              }
              return false;
          }
          checkMediaPlayback();
          """
          
          Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
              self?.webView?.evaluateJavaScript(script) { result, error in
                  if let isPlaying = result as? Bool, isPlaying {
                      timer.invalidate()
                  }
              }
          }
      }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoHandler" {
            if let dict = message.body as? [String: Any],
               let state = dict["state"] as? String {
                print("Video state changed: \(state)")
                if state == "play" {
                    stopMonitoringPlayState()
                    activityIndicator?.stopAnimating()
                    activityIndicator?.removeFromSuperview()
                    if let videoUrlString = dict["url"] as? String,
                       let videoUrl = URL(string: videoUrlString) {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.handleVideoURL(url: videoUrl)
                        }
                    }
                } else if state == "pause" || state == "complete" || state == "error" {
                    isVideoPlaying = false
                    startMonitoringPlayState(interval: 2.0)
                }
            }
        }
    }
    
    private func handleVideoURL(url: URL) {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            
            if UserDefaults.standard.bool(forKey: "isToDownload") {
                self.handleDownloadorPlayback(url: url)
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
                    self.handleDownloadorPlayback(url: url)
                }
            }
            else {
                self.handleDownloadorPlayback(url: url)
            }
        }
    }
    
    private func handleDownloadorPlayback(url: URL) {
        loadQualityOptions(from: url) { success, error in
            if success {
                self.showQualitySelection()
                self.cleanup()
            } else if let error = error {
                print("Error loading quality options: \(error)")
            }
        }
    }
    
    func showQualitySelection() {
        let preferredQuality = UserDefaults.standard.string(forKey: "preferredQuality")
        
        if let preferredQuality = preferredQuality {
            if let exactMatch = qualityOptions.first(where: { $0.name == preferredQuality }) {
                handleQualitySelection(option: exactMatch)
                return
            }
            let closestMatch = findClosestQuality(to: preferredQuality)
            if let closestMatch = closestMatch {
                handleQualitySelection(option: closestMatch)
                return
            }
        }
        
        presentQualityPicker()
    }

    private func findClosestQuality(to preferredQuality: String) -> (name: String, fileName: String)? {
        let preferredValue = extractQualityValue(from: preferredQuality)
        var closestOption: (name: String, fileName: String)?
        var smallestDifference = Int.max
        
        for option in qualityOptions {
            let optionValue = extractQualityValue(from: option.name)
            let difference = abs(preferredValue - optionValue)
            if difference < smallestDifference {
                smallestDifference = difference
                closestOption = option
            }
        }
        
        return closestOption
    }

    private func extractQualityValue(from qualityString: String) -> Int {
        return Int(qualityString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    }

    private func presentQualityPicker() {
        let alert = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)
        
        for option in qualityOptions {
            alert.addAction(UIAlertAction(title: option.name, style: .default, handler: { _ in
                self.handleQualitySelection(option: option)
            }))
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }

    private func handleQualitySelection(option: (name: String, fileName: String)) {
        print("Selected quality: \(option.name), URL: \(option.fileName)")
        if let url = URL(string: option.fileName) {
            let isToDownload = UserDefaults.standard.bool(forKey: "isToDownload")
            
            if isToDownload {
                let animeTitle = self.animeDetailsViewController?.animeTitle ?? "Anime"
                let episodeNumber = (self.animeDetailsViewController?.currentEpisodeIndex ?? 0) + 1
                let safeAnimeTitle = animeTitle.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
                let baseFileName = "\(safeAnimeTitle)_Episode_\(episodeNumber)"
                let outputFileName = "\(baseFileName)_\(option.name)"
                self.downloader.downloadAndCombineM3U8(url: url, outputFileName: outputFileName)
                self.dismiss(animated: true, completion: nil)
                UserDefaults.standard.set(false, forKey: "isToDownload")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.animeDetailsViewController?.showAlert(title: "Download Started", message: "Check your notifications and also the folder in the Files app to see when your episode is downloaded")
                }
            } else {
                DispatchQueue.main.async {
                    self.playVideoInAVPlayer(url: url)
                }
            }
        } else {
            print("Invalid URL for quality option: \(option.fileName)")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func loadQualityOptions(from url: URL, completion: @escaping (Bool, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading m3u8 file: \(error)")
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }
            
            guard let data = data,
                  let m3u8Content = String(data: data, encoding: .utf8) else {
                print("Failed to decode m3u8 file content")
                let error = NSError(domain: "M3U8ErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse m3u8 file"])
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }
            
            print("m3u8 file content:\n\(m3u8Content)")
            
            let lines = m3u8Content.components(separatedBy: .newlines)
            var currentName: String?
            var newQualityOptions: [(name: String, fileName: String)] = []
            
            for line in lines {
                if line.hasPrefix("#EXT-X-STREAM-INF") {
                    if let nameRange = line.range(of: "NAME=\"") {
                        let nameStartIndex = line.index(nameRange.upperBound, offsetBy: 0)
                        if let nameEndIndex = line[nameStartIndex...].firstIndex(of: "\"") {
                            currentName = String(line[nameStartIndex..<nameEndIndex])
                        }
                    }
                } else if line.hasSuffix(".m3u8"), let name = currentName {
                    let fullURL = URL(string: line, relativeTo: url)?.absoluteString ?? line
                    newQualityOptions.append((name: name, fileName: fullURL))
                    currentName = nil
                }
            }
            
            self.qualityOptions = newQualityOptions
            print("Parsed quality options: \(self.qualityOptions)")
            
            DispatchQueue.main.async {
                completion(true, nil)
            }
        }
        task.resume()
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
    
    private func playVideoInAVPlayer(url: URL) {
        cleanup()
        
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
        
        self.player = player
        self.playerViewController = playerViewController
        self.isVideoPlaying = true
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanup()
    }

    private func cleanup() {
        player?.pause()
        player = nil
        
        playerViewController?.willMove(toParent: nil)
        playerViewController?.view.removeFromSuperview()
        playerViewController?.removeFromParent()
        playerViewController = nil
        
        isVideoPlaying = false
        stopMonitoringPlayState()
        
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
    }

    deinit {
        cleanup()
        loadingObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
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

extension ExternalVideoPlayer: CustomPlayerViewDelegate {
    func customPlayerViewDidDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}
