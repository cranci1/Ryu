//
//  AnimeDetailsViewController.swift
//  Ryu
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import AVKit
import SwiftSoup
import GoogleCast
import SafariServices

class AnimeDetailViewController: UITableViewController, GCKRemoteMediaClientListener, AVPlayerViewControllerDelegate {
    var animeTitle: String?
    var imageUrl: String?
    var href: String?
    var source: String?
    
    var episodes: [Episode] = []
    var synopsis: String = ""
    var aliases: String = ""
    var airdate: String = ""
    var stars: String = ""
    
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    var currentEpisodeIndex: Int = 0
    var timeObserverToken: Any?
    
    var isFavorite: Bool = false
    var isSynopsisExpanded = false
    var isReverseSorted = false
    var hasSentUpdate = false
    
    var availableQualities: [String] = []
    var qualityOptions: [(name: String, fileName: String)] = []
    
    func configure(title: String, imageUrl: String, href: String, source: String) {
        self.animeTitle = title
        self.href = href
        self.source = source
        
        if imageUrl == "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg" && (source == "AniWorld" || source == "TokyoInsider") {
            self.imageUrl = imageUrl
            fetchImageUrl(source: source, href: href, fallback: imageUrl)
        } else {
            self.imageUrl = imageUrl
        }
    }
    
    private func fetchImageUrl(source: String, href: String, fallback: String) {
        guard let url = URL(string: href.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? href) else {
            self.imageUrl = fallback
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self?.imageUrl = fallback
                }
                return
            }
            
            do {
                let doc = try SwiftSoup.parse(html)
                switch source {
                case "AniWorld":
                    if let coverBox = try doc.select("div.seriesCoverBox").first(),
                       let img = try coverBox.select("img").first(),
                       let imgSrc = try? img.attr("data-src") {
                        DispatchQueue.main.async {
                            self.imageUrl = imgSrc.hasPrefix("/") ? "https://aniworld.to\(imgSrc)" : imgSrc
                        }
                    }
                case "TokyoInsider":
                    if let img = try doc.select("img.a_img").first(),
                       let imgSrc = try? img.attr("src") {
                        DispatchQueue.main.async {
                            self.imageUrl = imgSrc
                        }
                    }
                default:
                    break
                }
            } catch {
                print("Error extracting image URL: \(error)")
                DispatchQueue.main.async {
                    self.imageUrl = fallback
                }
            }
        }
        task.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserDefaults.standard.set(source, forKey: "selectedMediaSource")
        sortEpisodes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
        setupNotifications()
        checkFavoriteStatus()
        setupAudioSession()
        setupCastButton()
        
        isReverseSorted = UserDefaults.standard.bool(forKey: "isEpisodeReverseSorted")
        sortEpisodes()
        
        navigationItem.largeTitleDisplayMode = .never
        for (index, episode) in episodes.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 2)) as? EpisodeCell {
                cell.loadSavedProgress(for: episode.href)
            }
        }
        
        if let firstEpisodeHref = episodes.first?.href {
            currentEpisodeIndex = episodes.firstIndex(where: { $0.href == firstEpisodeHref }) ?? 0
        }
        
        setupRefreshControl()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .systemBackground
    }

    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    @objc private func handleRefresh() {
        refreshAnimeDetails()
    }
    
    private func setupCastButton() {
        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        
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
                fetchAniListIDForNotifications()
            } else {
                FavoritesManager.shared.removeFavorite(anime)
                if let animeTitle = animeTitle,
                   let customID = UserDefaults.standard.string(forKey: "customAniListID_\(animeTitle)"),
                   let animeID = Int(customID) {
                    AnimeEpisodeService.cancelNotifications(forAnimeID: animeID)
                } else {
                    let cleanedTitle = cleanTitle(animeTitle ?? "")
                    AnimeService.fetchAnimeID(byTitle: cleanedTitle) { result in
                        switch result {
                        case .success(let id):
                            AnimeEpisodeService.cancelNotifications(forAnimeID: id)
                        case .failure(let error):
                            print("Error fetching anime ID for canceling notifications: \(error)")
                        }
                    }
                }
            }
        }
        
        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.endUpdates()
    }
    
    private func createFavoriteAnime() -> FavoriteItem? {
        guard let title = animeTitle,
              let imageURL = URL(string: imageUrl ?? ""),
              let contentURL = URL(string: href ?? "") else {
                  return nil
              }
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
        
        return FavoriteItem(title: title, imageURL: imageURL, contentURL: contentURL, source: selectedMediaSource)
    }
    
    private func checkFavoriteStatus() {
        if let anime = createFavoriteAnime() {
            isFavorite = FavoritesManager.shared.isFavorite(anime)
            
            if isFavorite && UserDefaults.standard.bool(forKey: "notificationEpisodes") {
                fetchAniListIDForNotifications()
            }
        }
    }
    
    private func fetchAniListIDForNotifications() {
        guard let title = animeTitle else { return }
        
        let mediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "Unknown Source"
        
        if let customID = UserDefaults.standard.string(forKey: "customAniListID_\(title)"),
           let animeID = Int(customID) {
            AnimeEpisodeService.fetchEpisodesSchedule(animeID: animeID, animeName: title, mediaSource: mediaSource)
            return
        }
        
        let cleanedTitle = cleanTitle(title)
        AnimeService.fetchAnimeID(byTitle: cleanedTitle) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let id):
                AnimeEpisodeService.fetchEpisodesSchedule(animeID: id, animeName: title, mediaSource: mediaSource)
                print("scheduling")
            case .failure(let error):
                print("Error fetching anime ID for notifications: \(error)")
                self.showAlert(title: "Notification Error", message: "Unable to set up episode notifications. Please try setting a custom AniList ID.")
            }
        }
    }
    
    private func setupUI() {
        tableView.backgroundColor = .systemBackground
        tableView.register(AnimeHeaderCell.self, forCellReuseIdentifier: "AnimeHeaderCell")
        tableView.register(SynopsisCell.self, forCellReuseIdentifier: "SynopsisCell")
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: "EpisodeCell")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
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
                    self?.sortEpisodes()
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func sortEpisodes() {
        episodes = isReverseSorted ? episodes.sorted(by: { $0.episodeNumber > $1.episodeNumber }) : episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })
    }
    
    @objc private func userDefaultsChanged() {
        let newIsReverseSorted = UserDefaults.standard.bool(forKey: "isEpisodeReverseSorted")
        if newIsReverseSorted != isReverseSorted {
            isReverseSorted = newIsReverseSorted
            sortEpisodes()
            tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
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
            cell.watchNextTapped = { [weak self] in
                self?.watchNextEpisode()
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
        
        let trackingServicesAction = UIAlertAction(title: "Tracking Services", style: .default) { [weak self] _ in
            self?.fetchAnimeIDAndMappings()
        }
        trackingServicesAction.setValue(UIImage(systemName: "list.bullet"), forKey: "image")
        alertController.addAction(trackingServicesAction)
        
        let advancedSettingsAction = UIAlertAction(title: "Advanced Settings", style: .default) { [weak self] _ in
            self?.showAdvancedSettingsMenu()
        }
        advancedSettingsAction.setValue(UIImage(systemName: "gear"), forKey: "image")
        alertController.addAction(advancedSettingsAction)
        
        let fetchIDAction = UIAlertAction(title: "AniList Info", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let cleanedTitle = self.cleanTitle(self.animeTitle ?? "Title")
            self.fetchAndNavigateToAnime(title: cleanedTitle)
        }
        fetchIDAction.setValue(UIImage(systemName: "info.circle"), forKey: "image")
        alertController.addAction(fetchIDAction)
        
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
        if selectedMediaSource != "Anilibria" {
            let openOnWebAction = UIAlertAction(title: "Open in Web", style: .default) { [weak self] _ in
                self?.openAnimeOnWeb()
            }
            openOnWebAction.setValue(UIImage(systemName: "safari"), forKey: "image")
            alertController.addAction(openOnWebAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func fetchAnimeIDAndMappings() {
        guard let title = self.animeTitle else {
            self.showAlert(title: "Error", message: "Anime title is not available.")
            return
        }
        
        let cleanedTitle = cleanTitle(title)
        AnimeService.fetchAnimeID(byTitle: cleanedTitle) { [weak self] result in
            switch result {
            case .success(let id):
                self?.fetchMappingsAndShowOptions(animeID: id)
            case .failure(let error):
                print("Error fetching anime ID: \(error.localizedDescription)")
                self?.showAlert(title: "Error", message: "Unable to find the anime ID from AniList.")
            }
        }
    }
    
    private func fetchMappingsAndShowOptions(animeID: Int) {
        let urlString = "https://api.ani.zip/mappings?anilist_id=\(animeID)"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching mappings: \(error)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Unable to fetch mappings.")
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let mappings = json["mappings"] as? [String: Any] {
                    DispatchQueue.main.async {
                        self.showTrackingOptions(mappings: mappings)
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Unable to parse mappings.")
                }
            }
        }
        task.resume()
    }
    
    private func showTrackingOptions(mappings: [String: Any]) {
        let alertController = UIAlertController(title: "Tracking Services", message: nil, preferredStyle: .actionSheet)
        
        let blacklist: Set<String> = ["type", "anilist_id", "themoviedb_id", "thetvdb_id"]
        
        let filteredMappings = mappings.filter { !blacklist.contains($0.key) }
        let sortedMappings = filteredMappings.sorted { $0.key < $1.key }
        
        for (key, value) in sortedMappings {
            let formattedServiceName = key.replacingOccurrences(of: "_id", with: "").capitalized
            
            if let id = value as? String {
                let action = UIAlertAction(title: formattedServiceName, style: .default) { [weak self] _ in
                    self?.openTrackingServiceURL(for: key, id: id)
                }
                alertController.addAction(action)
            } else if let id = value as? Int {
                let action = UIAlertAction(title: formattedServiceName, style: .default) { [weak self] _ in
                    self?.openTrackingServiceURL(for: key, id: String(id))
                }
                alertController.addAction(action)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.modalPresentationStyle = .popover
            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [.up, .down, .left, .right]
            }
        } else {
            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func openTrackingServiceURL(for service: String, id: String) {
        var prefix = ""
        
        switch service {
        case "animeplanet_id":
            prefix = "https://animeplanet.com/anime/"
        case "kitsu_id":
            prefix = "https://kitsu.app/anime/"
        case "mal_id":
            prefix = "https://myanimelist.net/anime/"
        case "anisearch_id":
            prefix = "https://anisearch.com/anime/"
        case "anidb_id":
            prefix = "https://anidb.net/anime/"
        case "notifymoe_id":
            prefix = "https://notify.moe/anime/"
        case "livechart_id":
            prefix = "https://livechart.me/anime/"
        case "imdb_id":
            prefix = "https://www.imdb.com/title/"
        default:
            print("Unknown service.")
            return
        }
        
        let urlString = "\(prefix)\(id)"
        if let url = URL(string: urlString) {
            let safariVC = SFSafariViewController(url: url)
            DispatchQueue.main.async {
                self.present(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    private func showAdvancedSettingsMenu() {
        let alertController = UIAlertController(title: "Advanced Settings", message: nil, preferredStyle: .actionSheet)
        
        let customAniListIDAction = UIAlertAction(title: "Custom AniList ID", style: .default) { [weak self] _ in
            self?.customAniListID()
        }
        customAniListIDAction.setValue(UIImage(systemName: "pencil"), forKey: "image")
        alertController.addAction(customAniListIDAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func customAniListID() {
        let alert = UIAlertController(title: "Custom AniList ID", message: "Enter a custom AniList ID for this anime:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "AniList ID"
            if let animeTitle = self.animeTitle {
                let customID = UserDefaults.standard.string(forKey: "customAniListID_\(animeTitle)")
                textField.text = customID
            }
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let animeTitle = self?.animeTitle, let textField = alert.textFields?.first, let customID = textField.text, !customID.isEmpty {
                UserDefaults.standard.setValue(customID, forKey: "customAniListID_\(animeTitle)")
            } else {
                self?.showAlert(title: "Error", message: "AniList ID cannot be empty.")
            }
        }
        
        let revertAction = UIAlertAction(title: "Revert", style: .destructive) { [weak self] _ in
            if let animeTitle = self?.animeTitle {
                UserDefaults.standard.removeObject(forKey: "customAniListID_\(animeTitle)")
                self?.showAlert(title: "Reverted", message: "The custom AniList ID has been cleared.")
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(revertAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func cleanTitle(_ title: String) -> String {
        let unwantedStrings = ["(ITA)", "(Dub)", "(Dub ID)", "(Dublado)"]
        var cleanedTitle = title
        
        for unwanted in unwantedStrings {
            cleanedTitle = cleanedTitle.replacingOccurrences(of: unwanted, with: "")
        }
        
        cleanedTitle = cleanedTitle.replacingOccurrences(of: "\"", with: "")
        return cleanedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func fetchAndNavigateToAnime(title: String) {
        if let customID = UserDefaults.standard.string(forKey: "customAniListID_\(animeTitle ?? "")") {
            navigateToAnimeDetail(for: Int(customID) ?? 0)
        } else {
            AnimeService.fetchAnimeID(byTitle: title) { [weak self] result in
                switch result {
                case .success(let id):
                    self?.navigateToAnimeDetail(for: id)
                case .failure(let error):
                    print("Error fetching anime ID: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Unable to find the anime ID from AniList")
                }
            }
        }
    }
    
    private func navigateToAnimeDetail(for animeID: Int) {
        let storyboard = UIStoryboard(name: "AnilistAnimeInformation", bundle: nil)
        if let animeDetailVC = storyboard.instantiateViewController(withIdentifier: "AnimeInformation") as? AnimeInformation {
            animeDetailVC.animeID = animeID
            navigationController?.pushViewController(animeDetailVC, animated: true)
        }
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
            baseUrl = "https://anitaku.bz"
        case "AnimeHeaven":
            baseUrl = "https://animeheaven.me/"
        case "HiAnime":
            baseUrl = "https://hianime.to/watch/"
        default:
            baseUrl = ""
        }
        
        let fullUrlString = baseUrl + path
        
        guard let url = URL(string: fullUrlString) else {
            print("Invalid URL string: \(fullUrlString)")
            showAlert(withTitle: "Error", message: "The URL is invalid.")
            return
        }
        
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    private func refreshAnimeDetails() {
        if let href = href {
            AnimeDetailService.fetchAnimeDetails(from: href) { [weak self] result in
                DispatchQueue.main.async {
                    self?.refreshControl?.endRefreshing()
                    
                    switch result {
                    case .success(let details):
                        self?.updateAnimeDetails(with: details)
                    case .failure(let error):
                        self?.showAlert(withTitle: "Refresh Failed", message: error.localizedDescription)
                    }
                }
            }
        } else {
            refreshControl?.endRefreshing()
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
    
    func episodeSelected(episode: Episode, cell: EpisodeCell) {
        showLoadingBanner()
        
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
        default:
            baseURL = ""
            episodeId = episode.href
            fullURL = baseURL + episodeId
            checkUserDefault(url: fullURL, cell: cell, fullURL: fullURL)
            return
        }
    }
    
    func showLoadingBanner() {
        #if os(iOS)
        let alert = UIAlertController(title: nil, message: "Extracting Video", preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.8
        alert.view.layer.cornerRadius = 15
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 5, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        #endif
    }
    
    private func hideLoadingBanner() {
        #if os(iOS)
        DispatchQueue.main.async {
            if let alert = self.presentedViewController as? UIAlertController {
                alert.dismiss(animated: true, completion: nil)
            }
        }
        #endif
    }
    
    private func checkUserDefault(url: String, cell: EpisodeCell, fullURL: String) {
        if UserDefaults.standard.bool(forKey: "isToDownload") {
            playEpisode(url: url, cell: cell, fullURL: fullURL)
        } else if UserDefaults.standard.bool(forKey: "browserPlayer") {
            openInWeb(fullURL: url)
        } else {
            playEpisode(url: url, cell: cell, fullURL: fullURL)
        }
    }
    
    @objc private func openInWeb(fullURL: String) {
        hideLoadingBanner {
            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource")
            
            switch selectedMediaSource {
            case "HiAnime":
                if let extractedID = self.extractEpisodeId(from: fullURL) {
                    let hiAnimeURL = "https://hianime.to/watch/\(extractedID)"
                    self.openSafariViewController(with: hiAnimeURL)
                } else {
                    self.showAlert(title: "Error", message: "Unable to extract episode ID")
                }
            case "Anilibria":
                self.showAlert(title: "Unsupported Function", message: "Anilibria doesn't support playing in web.")
            default:
                self.openSafariViewController(with: fullURL)
            }
        }
    }
    
    private func openSafariViewController(with urlString: String) {
        guard let url = URL(string: urlString) else {
            showAlert(title: "Error", message: "Unable to open the webpage")
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    @objc func startStreamingButtonTapped(withURL url: String, captionURL: String, playerType: String, cell: EpisodeCell, fullURL: String) {
        deleteWebKitFolder()
        presentStreamingView(withURL: url, captionURL: captionURL, playerType: playerType, cell: cell, fullURL: fullURL)
    }
    
    func playEpisode(url: String, cell: EpisodeCell, fullURL: String) {
        hasSentUpdate = false
        
        guard let videoURL = URL(string: url) else {
            print("Invalid URL: \(url)")
            hideLoadingBanner()
            return
        }
        
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
        
        if selectedMediaSource == "HiAnime" {
            handleHiAnimeSource(url: url, cell: cell, fullURL: fullURL)
        } else if url.contains(".mp4") || url.contains(".m3u8") || url.contains("animeheaven.me/video.mp4") {
            hideLoadingBanner { [weak self] in
                self?.playVideo(sourceURL: videoURL, cell: cell, fullURL: fullURL)
            }
        } else {
            handleSources(url: url, cell: cell, fullURL: fullURL)
        }
    }
    
    func hideLoadingBanner(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            if let alert = self.presentedViewController as? UIAlertController {
                alert.dismiss(animated: true) {
                    completion?()
                }
            } else {
                completion?()
            }
        }
    }
    
    func presentStreamingView(withURL url: String, captionURL: String, playerType: String, cell: EpisodeCell, fullURL: String) {
        hideLoadingBanner { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                var streamingVC: UIViewController
                switch playerType {
                case VideoPlayerType.standard:
                    streamingVC = ExternalVideoPlayer(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
                case VideoPlayerType.player3rb:
                    streamingVC = ExternalVideoPlayer3rb(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
                case VideoPlayerType.playerKura:
                    streamingVC = ExternalVideoPlayerKura(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
                case VideoPlayerType.playerGoGo2:
                    streamingVC = ExternalVideoPlayerGoGo2(streamURL: url, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
                case VideoPlayerType.playerWeb:
                    streamingVC = WebPlayer(streamURL: url, captionURL: captionURL, cell: cell, fullURL: fullURL, animeDetailsViewController: self)
                default:
                    return
                }
                streamingVC.modalPresentationStyle = .fullScreen
                self.present(streamingVC, animated: true, completion: nil)
            }
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
    
    private func handleHiAnimeSource(url: String, cell: EpisodeCell, fullURL: String) {
        guard let episodeId = extractEpisodeId(from: url) else {
            print("Could not extract episodeId from URL")
            hideLoadingBannerAndShowAlert(title: "Error", message: "Could not extract episodeId from URL")
            return
        }
        
        fetchEpisodeOptions(episodeId: episodeId) { [weak self] options in
            guard let self = self else { return }
            
            if options.isEmpty {
                print("No options available for this episode")
                self.hideLoadingBannerAndShowAlert(title: "Error", message: "No options available for this episode")
                return
            }
            
            let preferredAudio = UserDefaults.standard.string(forKey: "audioHiPrefe") ?? ""
            let preferredServer = UserDefaults.standard.string(forKey: "serverHiPrefe") ?? ""
            
            self.selectAudioCategory(options: options, preferredAudio: preferredAudio) { category in
                guard let servers = options[category], !servers.isEmpty else {
                    print("No servers available for selected category")
                    self.hideLoadingBannerAndShowAlert(title: "Error", message: "No server available")
                    return
                }
                
                self.selectServer(servers: servers, preferredServer: preferredServer) { server in
                    let urls = ["https://aniwatch-api-gp1w.onrender.com/anime/episode-srcs?id="]
                    
                    let randomURL = urls.randomElement()!
                    let finalURL = "\(randomURL)\(episodeId)&category=\(category)&server=\(server)"
                    
                    self.fetchHiAnimeData(from: finalURL) { [weak self] sourceURL, captionURLs in
                        guard let self = self else { return }
                        
                        self.hideLoadingBanner {
                            DispatchQueue.main.async {
                                guard let sourceURL = sourceURL else {
                                    print("Error extracting source URL")
                                    self.showAlert(title: "Error", message: "Error extracting source URL")
                                    return
                                }
                                
                                self.selectSubtitles(captionURLs: captionURLs) { selectedSubtitleURL in
                                    let subtitleURL = selectedSubtitleURL ?? URL(string: "https://nosubtitlesfor.you")!
                                    self.openHiAnimeExperimental(url: sourceURL, subURL: subtitleURL, cell: cell, fullURL: fullURL)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func hideLoadingBannerAndShowAlert(title: String, message: String) {
        #if os(iOS)
        hideLoadingBanner { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showAlert(title: title, message: message)
            }
        }
        #endif
    }
    
    private func handleSources(url: String, cell: EpisodeCell, fullURL: String) {
        guard let requestURL = encodedURL(from: url) else { 
            DispatchQueue.main.async {
                self.hideLoadingBanner()
                self.showAlert(title: "Error", message: "Invalid URL: \(url)")
            }
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.hideLoadingBanner()
                    self.showAlert(title: "Error", message: "Error fetching video data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self.hideLoadingBanner()
                    self.showAlert(title: "Error", message: "Error parsing video data")
                    return
                }
                
                let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
                let gogoFetcher = UserDefaults.standard.string(forKey: "gogoFetcher") ?? "Default"
                var srcURL: URL?
                
                switch selectedMediaSource {
                case "GoGoAnime":
                    if gogoFetcher == "Default" {
                        srcURL = self.extractIframeSourceURL(from: htmlString)
                    } else if gogoFetcher == "Secondary" {
                        srcURL = self.extractDownloadLink(from: htmlString)
                    }
                case "AnimeFire":
                    srcURL = self.extractDataVideoSrcURL(from: htmlString)
                case "AnimeWorld", "AnimeHeaven", "AnimeBalkan":
                    srcURL = self.extractVideoSourceURL(from: htmlString)
                case "Kuramanime":
                    srcURL = URL(string: fullURL)
                case "AnimeSRBIJA":
                    srcURL = self.extractAsgoldURL(from: htmlString)
                case "Anime3rb":
                    self.anime3rbGetter  (from: htmlString) { finalUrl in
                        if let url = finalUrl {
                            self.hideLoadingBanner()
                            self.playVideo(sourceURL: url, cell: cell, fullURL: fullURL)
                        } else {
                            self.hideLoadingBannerAndShowAlert(title: "Error", message: "Error extracting source URL")
                            return
                        }
                    }
                    return
                case "AniVibe":
                    srcURL = self.extractAniVibeURL(from: htmlString)
                case "AniBunker":
                    srcURL = self.extractAniBunker(from: htmlString)
                case "TokyoInsider":
                    self.extractTokyoVideo(from: htmlString) { selectedURL in
                        DispatchQueue.main.async {
                            self.hideLoadingBanner()
                            self.playVideo(sourceURL: selectedURL, cell: cell, fullURL: fullURL)
                        }
                    }
                    return
                case "AniWorld":
                    self.extractVidozaVideoURL(from: htmlString) { videoURL in
                        guard let finalURL = videoURL else {
                            self.hideLoadingBannerAndShowAlert(title: "Error", message: "Error extracting source URL")
                            return
                        }
                        DispatchQueue.main.async {
                            self.hideLoadingBanner()
                            self.playVideo(sourceURL: finalURL, cell: cell, fullURL: fullURL)
                        }
                    }
                    return
                case "AnimeUnity":
                    self.extractEmbedUrl(from: htmlString) { finalUrl in
                        if let url = finalUrl {
                            self.hideLoadingBanner()
                            self.playVideo(sourceURL: url, cell: cell, fullURL: fullURL)
                        } else {
                            self.hideLoadingBannerAndShowAlert(title: "Error", message: "Error extracting source URL")
                            return
                        }
                    }
                    return
                case "AnimeFLV":
                    self.extractStreamtapeQueryParameters(from: htmlString) { videoURL in
                        if let url = videoURL {
                            self.hideLoadingBanner()
                            self.playVideo(sourceURL: url, cell: cell, fullURL: fullURL)
                        } else {
                            self.hideLoadingBannerAndShowAlert(title: "Error", message: "Error extracting source URL")
                            return
                        }
                    }
                    return
                default:
                    srcURL = self.extractIframeSourceURL(from: htmlString)
                }
                
                guard let finalSrcURL = srcURL else {
                    self.hideLoadingBannerAndShowAlert(title: "Error", message: "The stream URL wasn't found.")
                    return
                }
                
                self.hideLoadingBanner {
                    DispatchQueue.main.async {
                        switch selectedMediaSource {
                        case "GoGoAnime":
                            let playerType = gogoFetcher == "Secondary" ? VideoPlayerType.standard : VideoPlayerType.playerGoGo2
                            self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, captionURL: "", playerType: playerType, cell: cell, fullURL: fullURL)
                        case "AnimeFire":
                            self.fetchVideoDataAndChooseQuality(from: finalSrcURL.absoluteString) { selectedURL in
                                guard let selectedURL = selectedURL else {
                                    self.showAlert(title: "Error", message: "Failed to fetch video data")
                                    return
                                }
                                self.playVideo(sourceURL: selectedURL, cell: cell, fullURL: fullURL)
                            }
                        case "Kuramanime":
                            self.startStreamingButtonTapped(withURL: finalSrcURL.absoluteString, captionURL: "", playerType: VideoPlayerType.playerKura, cell: cell, fullURL: fullURL)
                        default:
                            self.playVideo(sourceURL: finalSrcURL, cell: cell, fullURL: fullURL)
                        }
                    }
                }
            }
        }.resume()
    }
    
    func encodedURL(from urlString: String) -> URL? {
        let allowedCharacters = CharacterSet.urlQueryAllowed
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else { return nil }
        return URL(string: encodedString)
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
            
            let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(videoURL)")
            if lastPlayedTime > 0 {
                mediaLoadOptions.playPosition = lastPlayedTime
            } else {
                mediaLoadOptions.playPosition = 0
            }
            
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
    
    func playVideo(sourceURL: URL, cell: EpisodeCell, fullURL: String) {
        hideLoadingBanner()
        let selectedPlayer = UserDefaults.standard.string(forKey: "mediaPlayerSelected") ?? "Default"
        let isToDownload = UserDefaults.standard.bool(forKey: "isToDownload")
        
        if isToDownload {
            DispatchQueue.main.async {
                self.hideLoadingBanner()
                self.handleDownload(sourceURL: sourceURL, fullURL: fullURL)
            }
        } else {
            DispatchQueue.main.async {
                self.playVideoWithSelectedPlayer(player: selectedPlayer, sourceURL: sourceURL, cell: cell, fullURL: fullURL)
            }
        }
    }
    
    private func handleDownload(sourceURL: URL, fullURL: String) {
        UserDefaults.standard.set(false, forKey: "isToDownload")
        
        guard let episode = episodes.first(where: { $0.href == fullURL }) else {
            print("Error: Could not find episode for URL \(fullURL)")
            return
        }
        
        let downloadManager = DownloadManager.shared
        let title = "\(self.animeTitle ?? "Anime") - Ep. \(episode.number)"
        
        self.showAlert(title: "Download", message: "Your download has started!")
        
        downloadManager.startDownload(url: sourceURL, title: title, progress: { progress in
            print("Download progress: \(progress * 100)%")
        }) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDownloadResult(result)
            }
        }
    }
    
    private func handleDownloadResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Download completed. File saved at: \(url)")
        case .failure(let error):
            print("Download failed with error: \(error.localizedDescription)")
        }
    }
    
    private func playVideoWithSelectedPlayer(player: String, sourceURL: URL, cell: EpisodeCell, fullURL: String) {
        switch player {
        case "Infuse", "VLC", "OutPlayer", "nPlayer":
            openInExternalPlayer(player: player, url: sourceURL)
        case "Custom":
            let fileExtension = sourceURL.pathExtension.lowercased()
            if fileExtension == "mkv" || fileExtension == "avi" {
                showAlert(title: "Unsupported Video Format", message: "This video file (\(fileExtension)) requires a third-party player like VLC, Infuse, or outplayer to play. Set it up in settings")
                return
            }
            
            let videoTitle = animeTitle
            let imageURL = imageUrl ?? "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg"
            let viewController = CustomPlayerView(videoTitle: videoTitle ?? "", videoURL: sourceURL, cell: cell, fullURL: fullURL, image: imageURL)
            viewController.modalPresentationStyle = .fullScreen
            self.present(viewController, animated: true, completion: nil)
        case "WebPlayer":
            startStreamingButtonTapped(withURL: sourceURL.absoluteString, captionURL: "", playerType: VideoPlayerType.playerWeb, cell: cell, fullURL: fullURL)
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
        case "OutPlayer":
            scheme = "outplayer://"
        case "nPlayer":
            scheme = "nplayer-"
        default:
            print("Unsupported player")
            showAlert(title: "Error", message: "Unsupported player")
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
            print(playerURL)
            showAlert(title: "\(player) Error", message: "\(player) app is not installed.")
        }
    }
    
    func openHiAnimeExperimental(url: URL, subURL: URL, cell: EpisodeCell, fullURL: String) {
        let videoTitle = animeTitle!
        let imageURL = imageUrl ?? "https://s4.anilist.co/file/anilistcdn/character/large/default.jpg"
        let viewController = CustomPlayerView(videoTitle: videoTitle, videoURL: url, subURL: subURL, cell: cell, fullURL: fullURL, image: imageURL)
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true, completion: nil)
    }
    
    private func playVideoWithAVPlayer(sourceURL: URL, cell: EpisodeCell, fullURL: String) {
        let fileExtension = sourceURL.pathExtension.lowercased()
        if fileExtension == "mkv" || fileExtension == "avi" {
            showAlert(title: "Unsupported Video Format", message: "This video file (\(fileExtension)) requires a third-party player like VLC, Infuse, or outplayer to play. Set it up in settings")
            return
        }
        
        if GCKCastContext.sharedInstance().castState == .connected {
            proceedWithCasting(videoURL: sourceURL)
        } else {
            player = AVPlayer(url: sourceURL)
            
            playerViewController = NormalPlayer()
            playerViewController?.player = player
            playerViewController?.delegate = self
            playerViewController?.entersFullScreenWhenPlaybackBegins = true
            playerViewController?.showsPlaybackControls = true
            
            let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
            
            playerViewController?.modalPresentationStyle = .fullScreen
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
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        if self.presentedViewController == nil {
            playerViewController.modalPresentationStyle = .fullScreen
            present(playerViewController, animated: true) {
                completionHandler(true)
            }
        } else {
            completionHandler(true)
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: .mixWithOthers)
            try audioSession.setActive(true)
            
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
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
            
            guard self.currentEpisodeIndex >= 0 && self.currentEpisodeIndex < self.episodes.count else {
                print("Error: currentEpisodeIndex out of bounds")
                return
            }
            
            let episodeNumberString = self.episodes[self.currentEpisodeIndex].number
            let episodeNumber = EpisodeNumberExtractor.extract(from: episodeNumberString)
            let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
            
            let continueWatchingItem = ContinueWatchingItem(
                animeTitle: self.animeTitle ?? "Unknown Anime",
                episodeTitle: "Ep. \(episodeNumber)",
                episodeNumber: episodeNumber,
                imageURL: self.imageUrl ?? "",
                fullURL: fullURL,
                lastPlayedTime: currentTime,
                totalTime: duration,
                source: selectedMediaSource
            )
            ContinueWatchingManager.shared.saveItem(continueWatchingItem)
            
            let shouldSendPushUpdates = UserDefaults.standard.bool(forKey: "sendPushUpdates")
            
            if shouldSendPushUpdates && remainingTime / duration < 0.15 && !self.hasSentUpdate {
                let cleanedTitle = self.cleanTitle(self.animeTitle ?? "Unknown Anime")
                
                self.fetchAnimeID(title: cleanedTitle) { animeID in
                    let aniListMutation = AniListMutation()
                    aniListMutation.updateAnimeProgress(animeId: animeID, episodeNumber: episodeNumber) { result in
                        switch result {
                        case .success():
                            print("Successfully updated anime progress.")
                        case .failure(let error):
                            print("Failed to update anime progress: \(error.localizedDescription)")
                        }
                    }
                    
                    self.hasSentUpdate = true
                }
            }
        }
    }
    
    func fetchAnimeID(title: String, completion: @escaping (Int) -> Void) {
        var updatedTitle = title
        if UserDefaults.standard.string(forKey: "selectedMediaSource") == "Anilibria" {
            if !self.aliases.isEmpty {
                updatedTitle = self.aliases
            }
        } else if let animeTitle = self.animeTitle {
            let customID = UserDefaults.standard.string(forKey: "customAniListID_\(animeTitle)")
            
            if let customID = customID, let id = Int(customID) {
                completion(id)
                return
            }
        }
        
        AnimeService.fetchAnimeID(byTitle: updatedTitle) { result in
            switch result {
            case .success(let id):
                completion(id)
            case .failure(let error):
                print("Error fetching anime ID: \(error.localizedDescription)")
            }
        }
    }
    
    func playNextEpisode() {
        if isReverseSorted {
            currentEpisodeIndex -= 1
            if currentEpisodeIndex >= 0 {
                let nextEpisode = episodes[currentEpisodeIndex]
                if let cell = tableView.cellForRow(at: IndexPath(row: currentEpisodeIndex, section: 2)) as? EpisodeCell {
                    episodeSelected(episode: nextEpisode, cell: cell)
                }
            } else {
                currentEpisodeIndex = 0
            }
        } else {
            currentEpisodeIndex += 1
            if currentEpisodeIndex < episodes.count {
                let nextEpisode = episodes[currentEpisodeIndex]
                if let cell = tableView.cellForRow(at: IndexPath(row: currentEpisodeIndex, section: 2)) as? EpisodeCell {
                    episodeSelected(episode: nextEpisode, cell: cell)
                }
            } else {
                currentEpisodeIndex = episodes.count - 1
            }
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if UserDefaults.standard.bool(forKey: "AutoPlay") {
            let hasNextEpisode = isReverseSorted ? (currentEpisodeIndex > 0) : (currentEpisodeIndex < episodes.count - 1)
            if hasNextEpisode {
                playerViewController?.dismiss(animated: true) { [weak self] in
                    self?.playNextEpisode()
                }
            } else {
                playerViewController?.dismiss(animated: true, completion: nil)
            }
        } else {
            playerViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func downloadMedia(for episode: Episode) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: episodes.firstIndex(where: { $0.href == episode.href }) ?? 0, section: 2)) as? EpisodeCell else {
            print("Error: Could not get cell for episode \(episode.number)")
            return
        }
        
        UserDefaults.standard.set(true, forKey: "isToDownload")
        
        episodeSelected(episode: episode, cell: cell)
    }
    
    private func watchNextEpisode() {
        let sortedEpisodes = isReverseSorted ? episodes.reversed() : episodes
        
        for episode in sortedEpisodes {
            let fullURL = episode.href
            let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
            let totalTime = UserDefaults.standard.double(forKey: "totalTime_\(fullURL)")
            
            if totalTime > 0 {
                let progressDifference = (totalTime - lastPlayedTime) / totalTime
                if progressDifference > 0.15 {
                    if let index = sortedEpisodes.firstIndex(of: episode) {
                        let indexPath = IndexPath(row: index, section: 2)
                        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let cell = self.tableView.cellForRow(at: indexPath) as? EpisodeCell {
                                cell.loadSavedProgress(for: episode.href)
                                self.episodeSelected(episode: episode, cell: cell)
                            }
                        }
                    }
                    break
                }
            } else {
                if let index = sortedEpisodes.firstIndex(of: episode) {
                    let indexPath = IndexPath(row: index, section: 2)
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let cell = self.tableView.cellForRow(at: indexPath) as? EpisodeCell {
                            cell.loadSavedProgress(for: episode.href)
                            self.episodeSelected(episode: episode, cell: cell)
                        }
                    }
                }
                break
            }
        }
    }
}

extension AnimeDetailViewController: SynopsisCellDelegate {
    func synopsisCellDidToggleExpansion(_ cell: SynopsisCell) {
        isSynopsisExpanded.toggle()
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }
}
