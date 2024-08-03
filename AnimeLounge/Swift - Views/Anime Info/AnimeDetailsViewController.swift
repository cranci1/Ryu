//
//  AnimeDetailsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import AVKit
import WebKit
import SwiftSoup
import GoogleCast
import Foundation
import MediaPlayer

extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}

class AnimeDetailViewController: UITableViewController, WKNavigationDelegate, GCKRemoteMediaClientListener {
    var animeTitle: String?
    var imageUrl: String?
    private var href: String?
    
    private var episodes: [Episode] = []
    private var synopsis: String = ""
    private var aliases: String = ""
    private var airdate: String = ""
    private var stars: String = ""
    
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    
    var currentEpisodeIndex: Int = 0
    var timeObserverToken: Any?
    
    private var isFavorite: Bool = false
    private var isSynopsisExpanded = false
    
    var availableQualities: [String] = []

    func configure(title: String, imageUrl: String, href: String) {
        self.animeTitle = title
        self.imageUrl = imageUrl
        self.href = href
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
        setupNotifications()
        checkFavoriteStatus()
        setupCastButton()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        for (index, episode) in episodes.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 2)) as? EpisodeCell {
                cell.loadSavedProgress(for: episode.href)
            }
        }
        
        if let firstEpisodeHref = episodes.first?.href {
             currentEpisodeIndex = episodes.firstIndex(where: { $0.href == firstEpisodeHref }) ?? 0
         }
    }
    
    private func setupCastButton() {
        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        if let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession,
           let remoteMediaClient = castSession.remoteMediaClient {
            remoteMediaClient.remove(self)
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        if let anime = createFavoriteAnime() {
            if isFavorite {
                FavoritesManager.shared.addFavorite(anime)
            } else {
                FavoritesManager.shared.removeFavorite(anime)
            }
        }
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
    
    private func createFavoriteAnime() -> FavoriteItem? {
        guard let title = animeTitle,
              let imageURL = URL(string: imageUrl ?? ""),
              let contentURL = URL(string: href ?? "") else {
            return nil
        }
        return FavoriteItem(title: title, imageURL: imageURL, contentURL: contentURL)
    }
    
    private func checkFavoriteStatus() {
        if let anime = createFavoriteAnime() {
            isFavorite = FavoritesManager.shared.isFavorite(anime)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        tableView.register(AnimeHeaderCell.self, forCellReuseIdentifier: "AnimeHeaderCell")
        tableView.register(SynopsisCell.self, forCellReuseIdentifier: "SynopsisCell")
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: "EpisodeCell")
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            player?.pause()
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                player?.play()
            } catch {
                print("Failed to reactivate AVAudioSession: \(error)")
            }
        default:
            break
        }
    }

    private func updateUI() {
        if let href = href {
            AnimeDetailService.fetchAnimeDetails(from: href) { [weak self] (result) in
                switch result {
                case .success(let details):
                    self?.aliases = details.aliases
                    self?.synopsis = details.synopsis
                    self?.airdate = details.airdate
                    self?.stars = details.stars
                    self?.episodes = details.episodes
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let topController = windowScene.windows.first?.rootViewController?.presentedViewController ?? windowScene.windows.first?.rootViewController {
            topController.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1: return 1
        case 2: return episodes.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnimeHeaderCell", for: indexPath) as! AnimeHeaderCell
            cell.configure(title: animeTitle, imageUrl: imageUrl, aliases: aliases, isFavorite: isFavorite, airdate: airdate, stars: stars, href: href)
            cell.favoriteButtonTapped = { [weak self] in
                self?.toggleFavorite()
            }
            cell.showOptionsMenu = { [weak self] in
                self?.showOptionsMenu()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SynopsisCell", for: indexPath) as! SynopsisCell
            cell.configure(synopsis: synopsis, isExpanded: isSynopsisExpanded)
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell
            let episode = episodes[indexPath.row]
            cell.configure(episode: episode, delegate: self)
            cell.loadSavedProgress(for: episode.href)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    private func showOptionsMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let openOnWebAction = UIAlertAction(title: "Open on Web", style: .default) { [weak self] _ in
            self?.openAnimeOnWeb()
        }
        openOnWebAction.setValue(UIImage(systemName: "safari"), forKey: "image")
        alertController.addAction(openOnWebAction)
        
        let refreshAction = UIAlertAction(title: "Refresh", style: .default) { [weak self] _ in
            self?.refreshAnimeDetails()
        }
        refreshAction.setValue(UIImage(systemName: "arrow.clockwise"), forKey: "image")
        alertController.addAction(refreshAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func openAnimeOnWeb() {
        guard let path = href else {
            print("Invalid URL string: \(href ?? "nil")")
            showAlert(withTitle: "Error", message: "The URL is invalid.")
            return
        }
        
        let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
        let baseUrl: String
        
        switch selectedSource {
        case "AnimeWorld":
            baseUrl = "https://animeworld.so"
        case "GoGoAnime":
            baseUrl = "https://anitaku.pe"
        case "AnimeHeaven":
            baseUrl = "https://animeheaven.me"
        case "Anix":
            baseUrl = "https://anix.to"
        default:
            baseUrl = ""
        }
        
        let fullUrlString = baseUrl + path
        
        guard let url = URL(string: fullUrlString) else {
            print("Invalid URL string: \(fullUrlString)")
            showAlert(withTitle: "Error", message: "The URL is invalid.")
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                print("Failed to open URL: \(url)")
                self.showAlert(withTitle: "Error", message: "Failed to open the URL.")
            }
        }
    }

    private func refreshAnimeDetails() {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
            
        if let href = href {
            AnimeDetailService.fetchAnimeDetails(from: href) { [weak self] result in
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem = nil
                    
                    switch result {
                    case .success(let details):
                        self?.updateAnimeDetails(with: details)
                        self?.setupCastButton()
                    case .failure(let error):
                        self?.showAlert(withTitle: "Refresh Failed", message: error.localizedDescription)
                        self?.setupCastButton()
                    }
                }
            }
        } else {
            showAlert(withTitle: "Error", message: "Unable to refresh. No valid URL found.")
        }
    }

    private func updateAnimeDetails(with details: AnimeDetail) {
        aliases = details.aliases
        synopsis = details.synopsis
        airdate = details.airdate
        stars = details.stars
        episodes = details.episodes
        
        tableView.reloadData()
    }
    
    func showAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            let episode = episodes[indexPath.row]
            if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell {
                episodeSelected(episode: episode, cell: cell)
            }
        }
    }

    private func episodeSelected(episode: Episode, cell: EpisodeCell) {
        let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
        currentEpisodeIndex = episodes.firstIndex(where: { $0.href == episode.href }) ?? 0
        
        var baseURL: String
        var fullURL: String
        var episodeId: String
        var episodeTimeURL: String
        
        switch selectedSource {
        case "AnimeWorld":
            baseURL = "https://www.animeworld.so/api/episode/serverPlayerAnimeWorld?id="
            episodeId = episode.href.components(separatedBy: "/").last ?? episode.href
            fullURL = baseURL + episodeId
            episodeTimeURL = episode.href
            checkUserDefault(url: fullURL, cell: cell, fullURL: episodeTimeURL)
            return
        case "AnimeHeaven":
            baseURL = "https://animeheaven.me/"
            episodeId = episode.href
            fullURL = baseURL + episodeId
            episodeTimeURL = episode.href
            checkUserDefault(url: fullURL, cell: cell, fullURL: episodeTimeURL)
            return
        case "GoGoAnime":
            baseURL = "https://anitaku.pe/"
            episodeId = episode.href.components(separatedBy: "/").last ?? episode.href
            fullURL = baseURL + episodeId
            episodeTimeURL = episode.href
            checkUserDefault(url: fullURL, cell: cell, fullURL: episodeTimeURL)
            return
        case "Anix":
            baseURL = "https://anix.to"
            episodeId = episode.href
            fullURL = baseURL + episodeId
            episodeTimeURL = episode.href
            checkUserDefault(url: fullURL, cell: cell, fullURL: episodeTimeURL)
            return
        default:
            baseURL = ""
            episodeId = episode.href
            fullURL = baseURL + episodeId
            checkUserDefault(url: fullURL, cell: cell, fullURL: fullURL)
            return
        }
    }
    
    private func checkUserDefault(url: String, cell: EpisodeCell, fullURL: String) {
        if UserDefaults.standard.bool(forKey: "browserPlayer") {
            openWebView(fullURL: url)
        } else {
            playEpisode(url: url, cell: cell, fullURL: fullURL)
        }
    }
    
    private func openWebView(fullURL: String) {
        let webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        if let url = URL(string: fullURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    @objc func startStreamingButtonTapped(withURL url: String, playerType: String, cell: EpisodeCell, fullURL: String) {
        deleteWebKitFolder()
        presentStreamingView(withURL: url, playerType: playerType, cell: cell, fullURL: fullURL)
    }

    func presentStreamingView(withURL url: String, playerType: String, cell: EpisodeCell, fullURL: String) {
        DispatchQueue.main.async {
            var streamingVC: UIViewController
            switch playerType {
            case VideoPlayerType.standard:
                streamingVC = ExternalVideoPlayer(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
            case VideoPlayerType.player3rb:
                streamingVC = ExternalVideoPlayer3rb(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
            case VideoPlayerType.playerKura:
                streamingVC = ExternalVideoPlayerKura(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
            case VideoPlayerType.playerJK:
                streamingVC = ExternalVideoPlayerJK(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
            case VideoPlayerType.playerAnix:
                streamingVC = ExternalVideoPlayerAnix(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
            default:
                return
            }
            streamingVC.modalPresentationStyle = .fullScreen
            self.present(streamingVC, animated: true, completion: nil)
        }
    }
    
    func deleteWebKitFolder() {
        if let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let webKitFolderPath = libraryPath.appendingPathComponent("WebKit")
            do {
                if FileManager.default.fileExists(atPath: webKitFolderPath.path) {
                    try FileManager.default.removeItem(at: webKitFolderPath)
                    print("Successfully deleted the WebKit folder.")
                } else {
                    print("The WebKit folder does not exist.")
                }
            } catch {
                print("Error deleting the WebKit folder: \(error.localizedDescription)")
            }
        } else {
            print("Could not find the Library directory.")
        }
    }

    func playEpisode(url: String, cell: EpisodeCell, fullURL: String) {
        guard let videoURL = URL(string: url) else {
            print("Invalid URL: \(url)")
            return
        }
        
        if url.contains(".mp4") || url.contains(".m3u8") || url.contains("animeheaven.me/video.mp4") {
            DispatchQueue.main.async {
                self.playVideo(sourceURL: videoURL, cell: cell, fullURL: fullURL)
            }
        } else {
            URLSession.shared.dataTask(with: videoURL) { [weak self] (data, response, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching video data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data,
                      let htmlString = String(data: data, encoding: .utf8) else {
                    print("Error parsing video data")
                    return
                }
                
                let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
                var srcURL: URL?
                
                switch selectedMediaSource {
                case "GoGoAnime":
                    srcURL = self.extractIframeSourceURL(from: htmlString)
                case "AnimeFire":
                    srcURL = self.extractDataVideoSrcURL(from: htmlString)
                case "AnimeWorld", "AnimeHeaven":
                    srcURL = self.extractVideoSourceURL(from: htmlString)
                case "Anime3rb", "Kuramanime", "JKanime":
                    srcURL = URL(string: fullURL)
                case "Anix":
                    srcURL = URL(string: url)
                default:
                    srcURL = self.extractIframeSourceURL(from: htmlString)
                }
                
                guard let finalSrcURL = srcURL else {
                    print("Error extracting source URL")
                    return
                }
                
                DispatchQueue.main.async {
                    switch selectedMediaSource {
                    case "GoGoAnime":
                        self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, playerType: VideoPlayerType.standard, cell: cell, fullURL: fullURL)
                    case "AnimeFire":
                        self.fetchVideoDataAndChooseQuality(from: finalSrcURL.absoluteString) { selectedURL in
                            guard let selectedURL = selectedURL else { return }
                            self.playVideo(sourceURL: selectedURL, cell: cell, fullURL: fullURL)
                            print("\(selectedURL)")
                        }
                    case "Anime3rb":
                        self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, playerType: VideoPlayerType.player3rb, cell: cell, fullURL: fullURL)
                    case "Kuramanime":
                        self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, playerType: VideoPlayerType.playerKura, cell: cell, fullURL: fullURL)
                    case "JKanime":
                        self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, playerType: VideoPlayerType.playerJK, cell: cell, fullURL: fullURL)
                    case "Anix":
                        self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, playerType: VideoPlayerType.playerAnix, cell: cell, fullURL: fullURL)
                    default:
                        self.playVideo(sourceURL: finalSrcURL, cell: cell, fullURL: fullURL)
                    }
                }
            }.resume()
        }
    }
    
    private func fetchHTMLContent(from url: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "Invalid data", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(htmlString))
        }.resume()
    }
    
    private func proceedWithCasting(videoURL: URL) {
        DispatchQueue.main.async {
            let metadata = GCKMediaMetadata(metadataType: .movie)
            
            if UserDefaults.standard.bool(forKey: "fullTitleCast") {
                if let animeTitle = self.animeTitle {
                    metadata.setString(animeTitle, forKey: kGCKMetadataKeyTitle)
                } else {
                    print("Error: Anime title is missing.")
                }
            } else {
                let episodeNumber = self.currentEpisodeIndex + 1
                metadata.setString("Episode \(episodeNumber)", forKey: kGCKMetadataKeyTitle)
            }
            
            if UserDefaults.standard.bool(forKey: "animeImageCast") {
                if let imageURL = URL(string: self.imageUrl ?? "") {
                    metadata.addImage(GCKImage(url: imageURL, width: 480, height: 720))
                } else {
                    print("Error: Anime image URL is missing or invalid.")
                }
            }
            
            let builder = GCKMediaInformationBuilder(contentURL: videoURL)
            
            let contentType: String
            
            if videoURL.absoluteString.contains(".m3u8") {
                contentType = "application/x-mpegurl"
            } else if videoURL.absoluteString.contains(".mp4") {
                contentType = "video/mp4"
            } else {
                contentType = "video/mp4"
            }
            
            builder.contentType = contentType
            builder.metadata = metadata
            
            let streamTypeString = UserDefaults.standard.string(forKey: "castStreamingType") ?? "buffered"
            switch streamTypeString {
            case "live":
                builder.streamType = .live
            default:
                builder.streamType = .buffered
            }
            
            let mediaInformation = builder.build()
            
            let mediaLoadOptions = GCKMediaLoadOptions()
            mediaLoadOptions.autoplay = true
            mediaLoadOptions.playPosition = 0
            
            if let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession,
               let remoteMediaClient = castSession.remoteMediaClient {
                remoteMediaClient.loadMedia(mediaInformation, with: mediaLoadOptions)
                remoteMediaClient.add(self)
            } else {
                print("Error: Failed to load media to Google Cast")
            }
        }
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        if let mediaStatus = mediaStatus, mediaStatus.idleReason == .finished {
            if UserDefaults.standard.bool(forKey: "AutoPlay") {
                DispatchQueue.main.async { [weak self] in
                    self?.playNextEpisode()
                }
            }
        }
    }
    
    private func extractVideoSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let videoElement = try doc.select("video").first(),
                  let sourceElement = try videoElement.select("source").first(),
                  let sourceURLString = try sourceElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            
            let mp4Pattern = #"<source src="(.*?)" type="video/mp4">"#
            let m3u8Pattern = #"<source src="(.*?)" type="application/x-mpegURL">"#
            
            if let mp4URL = extractURL(from: htmlString, pattern: mp4Pattern) {
                return mp4URL
            } else if let m3u8URL = extractURL(from: htmlString, pattern: m3u8Pattern) {
                return m3u8URL
            }
            return nil
        }
    }
    
    private func extractURL(from htmlString: String, pattern: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let urlRange = Range(match.range(at: 1), in: htmlString) else {
            return nil
        }
        
        let urlString = String(htmlString[urlRange])
        return URL(string: urlString)
    }
    
    private func extractIframeSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let iframeElement = try doc.select("iframe").first(),
                  let sourceURLString = try iframeElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            print("Iframe src URL: \(sourceURL.absoluteString)")
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    private func extractDataVideoSrcURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let element = try doc.select("[data-video-src]").first(),
                  let sourceURLString = try element.attr("data-video-src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            print("Data-video-src URL: \(sourceURL.absoluteString)")
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    private func fetchVideoDataAndChooseQuality(from urlString: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL string")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(String(describing: error))")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let videoDataArray = json["data"] as? [[String: Any]] {
                    
                    self.availableQualities.removeAll()
                    
                    for videoData in videoDataArray {
                        if let label = videoData["label"] as? String {
                            self.availableQualities.append(label)
                        }
                    }
                    
                    if self.availableQualities.isEmpty {
                        print("No available video qualities found")
                        completion(nil)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.showQualityPicker(qualities: self.availableQualities) { selectedQuality in
                            guard let selectedQuality = selectedQuality,
                                  let selectedVideoData = videoDataArray.first(where: { $0["label"] as? String == selectedQuality }),
                                  let selectedURLString = selectedVideoData["src"] as? String,
                                  let selectedURL = URL(string: selectedURLString) else {
                                completion(nil)
                                return
                            }
                            
                            completion(selectedURL)
                        }
                    }
                    
                } else {
                    print("JSON structure is invalid or data key is missing")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func showQualityPicker(qualities: [String], completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Choose Video Quality", message: nil, preferredStyle: .actionSheet)
        
        for quality in qualities {
            let action = UIAlertAction(title: quality, style: .default) { _ in
                completion(quality)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        }
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }

    func playVideo(sourceURL: URL, cell: EpisodeCell, fullURL: String) {
        let selectedPlayer = UserDefaults.standard.string(forKey: "mediaPlayerSelected") ?? "Default"
        let isToDownload = UserDefaults.standard.bool(forKey: "isToDownload")

        if isToDownload {
            handleDownload(sourceURL: sourceURL, fullURL: fullURL)
        } else {
            DispatchQueue.main.async {
                self.playVideoWithSelectedPlayer(player: selectedPlayer, sourceURL: sourceURL, cell: cell, fullURL: fullURL)
            }
        }
    }
    
    private func handleDownload(sourceURL: URL, fullURL: String) {
        UserDefaults.standard.set(true, forKey: "activeDownloads")
        UserDefaults.standard.set(false, forKey: "isToDownload")
        
        guard let episode = episodes.first(where: { $0.href == fullURL }) else {
            print("Error: Could not find episode for URL \(fullURL)")
            return
        }
        
        let downloadManager = DownloadManager.shared
        let title = "\(self.animeTitle ?? "Anime") - Ep. \(episode.number)"
        
        downloadManager.startDownload(url: sourceURL, title: title, progress: { progress in
            print("Download progress: \(progress * 100)%")
        }) { [weak self] result in
            DispatchQueue.main.async {
                UserDefaults.standard.set(false, forKey: "activeDownloads")
                self?.handleDownloadResult(result)
            }
        }
    }
    
    private func handleDownloadResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Download completed. File saved at: \(url)")
            self.showAlert(title: "Download Completed!", message: "You can find your download in the Library -> Downloads.")
        case .failure(let error):
            print("Download failed with error: \(error.localizedDescription)")
            self.showAlert(title: "Download Failed", message: error.localizedDescription)
        }
    }

    private func playVideoWithSelectedPlayer(player: String, sourceURL: URL, cell: EpisodeCell, fullURL: String) {
        switch player {
        case "Default":
            playVideoWithAVPlayer(sourceURL: sourceURL, cell: cell, fullURL: fullURL)
        case "Infuse", "VLC", "Outplayer":
            openInExternalPlayer(player: player, url: sourceURL)
        default:
            playVideoWithAVPlayer(sourceURL: sourceURL, cell: cell, fullURL: fullURL)
        }
    }
    
    func openInExternalPlayer(player: String, url: URL) {
        var scheme: String
        switch player {
        case "Infuse":
            scheme = "infuse://x-callback-url/play?url="
        case "VLC":
            scheme = "vlc://"
        case "Outplayer":
            scheme = "outplayer://"
        default:
            print("Unsupported player")
            return
        }
        
        guard let playerURL = URL(string: scheme + url.absoluteString) else {
            print("Failed to create \(player) URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(playerURL) {
            UIApplication.shared.open(playerURL, options: [:], completionHandler: nil)
        } else {
            print("\(player) app is not installed")
            showAlert(title: "\(player) Error", message: "\(player) app is not installed.")
        }
    }

    private func playVideoWithAVPlayer(sourceURL: URL, cell: EpisodeCell, fullURL: String) {
        if GCKCastContext.sharedInstance().castState == .connected {
            proceedWithCasting(videoURL: sourceURL)
        } else {
            player = AVPlayer(url: sourceURL)
            
            playerViewController = UserDefaults.standard.bool(forKey: "AlwaysLandscape") ? LandscapePlayer() : AVPlayerViewController()
            playerViewController?.player = player
            
            let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
            
            present(playerViewController!, animated: true) {
                if lastPlayedTime > 0 {
                    let seekTime = CMTime(seconds: lastPlayedTime, preferredTimescale: 1)
                    self.player?.seek(to: seekTime) { _ in
                        self.player?.play()
                    }
                } else {
                    self.player?.play()
                }
                self.addPeriodicTimeObserver(cell: cell, fullURL: fullURL)
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        }
    }

    private func addPeriodicTimeObserver(cell: EpisodeCell, fullURL: String) {
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
            
            cell.updatePlaybackProgress(progress: Float(progress), remainingTime: remainingTime)
            
            UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(fullURL)")
            UserDefaults.standard.set(duration, forKey: "totalTime_\(fullURL)")
        }
    }
    
    func playNextEpisode() {
        currentEpisodeIndex += 1
        if currentEpisodeIndex < episodes.count {
            let nextEpisode = episodes[currentEpisodeIndex]
            if let cell = tableView.cellForRow(at: IndexPath(row: currentEpisodeIndex, section: 2)) as? EpisodeCell {
                episodeSelected(episode: nextEpisode, cell: cell)
            }
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if UserDefaults.standard.bool(forKey: "AutoPlay") {
            playerViewController?.dismiss(animated: true) { [weak self] in
                self?.playNextEpisode()
            }
        } else {
            playerViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func downloadMedia(for episode: Episode) {
        print("Downloading episode: \(episode.number)")
        guard let cell = tableView.cellForRow(at: IndexPath(row: episodes.firstIndex(where: { $0.href == episode.href }) ?? 0, section: 2)) as? EpisodeCell else {
            print("Error: Could not get cell for episode \(episode.number)")
            return
        }
        
        UserDefaults.standard.set(true, forKey: "isToDownload")
        
        episodeSelected(episode: episode, cell: cell)
    }
}

extension AnimeDetailViewController: SynopsisCellDelegate {
    func synopsisCellDidToggleExpansion(_ cell: SynopsisCell) {
        isSynopsisExpanded.toggle()
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }
}
