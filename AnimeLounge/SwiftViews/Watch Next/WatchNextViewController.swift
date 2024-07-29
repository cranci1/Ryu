//
//  WatchNextViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit

class WatchNextViewController: UITableViewController {
    
    @IBOutlet private weak var airingCollectionView: UICollectionView!
    @IBOutlet private weak var trendingCollectionView: UICollectionView!
    @IBOutlet private weak var seasonalCollectionView: UICollectionView!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    private var airingAnime: [Anime] = []
    private var trendingAnime: [Anime] = []
    private var seasonalAnime: [Anime] = []
    
    private let aniListServiceAiring = AnilistServiceAiringAnime()
    private let aniListServiceTrending = AnilistServiceTrendingAnime()
    private let aniListServiceSeasonal = AnilistServiceSeasonalAnime()
    
    private let kitsuServiceAiring = KitsuServiceAiringAnime()
    private let kitsuServiceTrending = KitsuServiceTrendingAnime()
    private let kitsuServiceSeasonal = KitsuServiceSeasonalAnime()
    
    private let malServiceAiring = JikanServiceAiringAnime()
    private let malServiceTrending = JikanServiceTrendingAnime()
    private let malServiceSeasonal = JikanServiceSeasonalAnime()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionViews()
        setupDateLabel()
        setupRefreshControl()
        fetchAnimeData()
    }
    
    func setupCollectionViews() {
        let collectionViews = [airingCollectionView, trendingCollectionView, seasonalCollectionView]
        let cellIdentifiers = ["AiringAnimeCell", "SlimmAnimeCell", "SlimmAnimeCell"]

        for (collectionView, identifier) in zip(collectionViews, cellIdentifiers) {
            collectionView?.delegate = self
            collectionView?.dataSource = self
            collectionView?.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
        }
    }
    
    func setupDateLabel() {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        let dateString = dateFormatter.string(from: currentDate)
        dateLabel.text = "on \(dateString)"
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    @objc func refreshData() {
        fetchAnimeData()
    }
    
    func fetchAnimeData() {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        fetchTrendingAnime { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        fetchSeasonalAnime { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        fetchAiringAnime { dispatchGroup.leave() }
        
        dispatchGroup.notify(queue: .main) {
            self.refreshUI()
            self.refreshControl?.endRefreshing()
        }
    }
    
    func fetchTrendingAnime(completion: @escaping () -> Void) {
        let animeListingService = UserDefaults.standard.string(forKey: "AnimeListingService") ?? "AniList"
        
        switch animeListingService {
        case "Kitsu":
            kitsuServiceTrending.fetchTrendingAnime { [weak self] animeList in
                self?.trendingAnime = animeList ?? []
                completion()
            }
        case "MAL":
            malServiceTrending.fetchTrendingAnime { [weak self] animeList in
                self?.trendingAnime = animeList ?? []
                completion()
            }
        default:
            aniListServiceTrending.fetchTrendingAnime { [weak self] animeList in
                self?.trendingAnime = animeList ?? []
                completion()
            }
        }
    }
    
    func fetchSeasonalAnime(completion: @escaping () -> Void) {
        let animeListingService = UserDefaults.standard.string(forKey: "AnimeListingService") ?? "AniList"
        
        switch animeListingService {
        case "Kitsu":
            kitsuServiceSeasonal.fetchSeasonalAnime { [weak self] animeList in
                self?.seasonalAnime = animeList ?? []
                completion()
            }
        case "MAL":
            malServiceSeasonal.fetchSeasonalAnime { [weak self] animeList in
                self?.seasonalAnime = animeList ?? []
                completion()
            }
        default:
            aniListServiceSeasonal.fetchSeasonalAnime { [weak self] animeList in
                self?.seasonalAnime = animeList ?? []
                completion()
            }
        }
    }
    
    func fetchAiringAnime(completion: @escaping () -> Void) {
        let animeListingService = UserDefaults.standard.string(forKey: "AnimeListingService") ?? "AniList"
        
        switch animeListingService {
        case "Kitsu":
            kitsuServiceAiring.fetchAiringAnime { [weak self] animeList in
                self?.airingAnime = animeList ?? []
                completion()
            }
        case "MAL":
            malServiceAiring.fetchAiringAnime { [weak self] animeList in
                self?.airingAnime = animeList ?? []
                completion()
            }
        default:
            aniListServiceAiring.fetchAiringAnime { [weak self] animeList in
                self?.airingAnime = animeList ?? []
                completion()
            }
        }
    }
    
    func refreshUI() {
        DispatchQueue.main.async {
            self.airingCollectionView.reloadData()
            self.trendingCollectionView.reloadData()
            self.seasonalCollectionView.reloadData()
            self.setupDateLabel()
        }
    }
    
    @IBAction func selectSourceButtonTapped(_ sender: UIButton) {
        SourceMenu.showSourceSelector(from: self, sourceView: sender)
    }
}

extension WatchNextViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case trendingCollectionView:
            return trendingAnime.count
        case seasonalCollectionView:
            return seasonalAnime.count
        case airingCollectionView:
            return airingAnime.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        
        switch collectionView {
        case trendingCollectionView, seasonalCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SlimmAnimeCell", for: indexPath)
            if let trendingCell = cell as? SlimmAnimeCell {
                configureTrendingCell(trendingCell, at: indexPath, for: collectionView)
            }
        case airingCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AiringAnimeCell", for: indexPath)
            if let airingCell = cell as? AiringAnimeCell {
                configureAiringCell(airingCell, at: indexPath)
            }
        default:
            fatalError("Unexpected collection view")
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)
        
        return cell
    }
    
    private func configureTrendingCell(_ cell: SlimmAnimeCell, at indexPath: IndexPath, for collectionView: UICollectionView) {
        let anime: Anime
        if collectionView == trendingCollectionView {
            anime = trendingAnime[indexPath.item]
        } else {
            anime = seasonalAnime[indexPath.item]
        }
        let imageUrl = URL(string: anime.coverImage.large)
        cell.configure(with: anime.title.romaji, imageUrl: imageUrl)
    }
    
    private func configureAiringCell(_ cell: AiringAnimeCell, at indexPath: IndexPath) {
        let anime = airingAnime[indexPath.item]
        let imageUrl = URL(string: anime.coverImage.large)
        cell.configure(
            with: anime.title.romaji,
            imageUrl: imageUrl,
            episodes: anime.episodes,
            description: anime.description,
            airingAt: anime.airingAt
        )
    }
}

extension WatchNextViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedAnime: Anime?
        
        switch collectionView {
        case trendingCollectionView:
            selectedAnime = trendingAnime[indexPath.item]
        case seasonalCollectionView:
            selectedAnime = seasonalAnime[indexPath.item]
        case airingCollectionView:
            selectedAnime = airingAnime[indexPath.item]
        default:
            selectedAnime = nil
        }
        
        guard let anime = selectedAnime else { return }
        navigateToAnimeDetail(for: anime)
    }
    
    private func navigateToAnimeDetail(for anime: Anime) {
        let animeListingService = UserDefaults.standard.string(forKey: "AnimeListingService") ?? "AniList"
        
        if animeListingService == "AniList" {
            let storyboard = UIStoryboard(name: "AnilistAnimeInformation", bundle: nil)
            if let animeDetailVC = storyboard.instantiateViewController(withIdentifier: "AnimeInformation") as? AnimeInformation {
                animeDetailVC.animeID = anime.id
                navigationController?.pushViewController(animeDetailVC, animated: true)
            }
        } else {
            showUnsupportedSourceAlert()
        }
    }

    private func showUnsupportedSourceAlert() {
        let alertController = UIAlertController(
            title: "Unsupported Source",
            message: "Detailed anime information is only available for AniList as of now.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension WatchNextViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = interaction.view as? UICollectionViewCell,
              let indexPath = indexPathForCell(cell) else { return nil }
        
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: { [weak self] in
            self?.previewViewController(for: indexPath)
        }, actionProvider: { [weak self] _ in
            guard let self = self else { return nil }
            
            let animeListingService = UserDefaults.standard.string(forKey: "AnimeListingService") ?? "AniList"
            
            var actions: [UIAction] = []
            
            if animeListingService == "AniList" {
                let openAction = UIAction(title: "Open", image: UIImage(systemName: "eye")) { _ in
                    self.openAnimeDetail(for: indexPath)
                }
                actions.append(openAction)
            }
            
            let searchAction = UIAction(title: "Watch Trailer", image: UIImage(systemName: "tv")) { _ in
                self.showError(message: "The trailer implementation is not added yet")
            }
            actions.append(searchAction)
            
            return UIMenu(title: "", children: actions)
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = cellForIndexPath(indexPath) else {
            return nil
        }
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        
        return UITargetedPreview(view: cell, parameters: parameters)
    }
    
    private func previewViewController(for indexPath: IndexPath) -> UIViewController? {
        guard let anime = animeForIndexPath(indexPath) else { return nil }
        
        let storyboard = UIStoryboard(name: "AnilistAnimeInformation", bundle: nil)
        guard let animeDetailVC = storyboard.instantiateViewController(withIdentifier: "AnimeInformation") as? AnimeInformation else {
            return nil
        }
        
        animeDetailVC.animeID = anime.id
        return animeDetailVC
    }
    
    private func openAnimeDetail(for indexPath: IndexPath) {
        guard let anime = animeForIndexPath(indexPath) else { return }
        navigateToAnimeDetail(for: anime)
    }
    
    private func animeForIndexPath(_ indexPath: IndexPath) -> Anime? {
        switch indexPath.section {
        case 0:
            return trendingAnime[indexPath.item]
        case 1:
            return seasonalAnime[indexPath.item]
        case 2:
            return airingAnime[indexPath.item]
        default:
            return nil
        }
    }
    
    private func indexPathForCell(_ cell: UICollectionViewCell) -> IndexPath? {
        let collectionViews = [trendingCollectionView, seasonalCollectionView, airingCollectionView]
        
        for (section, collectionView) in collectionViews.enumerated() {
            if let indexPath = collectionView?.indexPath(for: cell) {
                return IndexPath(item: indexPath.item, section: section)
            }
        }
        return nil
    }
    
    private func cellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell? {
         let collectionViews = [trendingCollectionView, seasonalCollectionView, airingCollectionView]
         guard indexPath.section < collectionViews.count else { return nil }
         return collectionViews[indexPath.section]?.cellForItem(at: IndexPath(item: indexPath.item, section: 0))
     }

    private func searchEpisodes(for indexPath: IndexPath) {
        guard let anime = animeForIndexPath(indexPath) else { return }
        
        let query = anime.title.romaji
        guard !query.isEmpty else {
            showError(message: "Could not find anime title.")
            return
        }
        
        searchMedia(query: query)
    }
    
    private func searchMedia(query: String) {
        let resultsVC = SearchResultsViewController()
        resultsVC.query = query
        navigationController?.pushViewController(resultsVC, animated: true)
    }
    
    private func showError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

struct Anime {
    let id: Int
    let title: Title
    let coverImage: CoverImage
    let episodes: Int?
    let description: String?
    let airingAt: Int?
    var mediaRelations: [MediaRelation] = []
    var characters: [Character] = []
}

struct MediaRelation {
    let node: MediaNode
    
    struct MediaNode {
        let id: Int
        let title: Title
    }
}

struct Character {
    let node: CharacterNode
    let role: String
    
    struct CharacterNode {
        let id: Int
        let name: Name
        
        struct Name {
            let full: String
        }
    }
}

struct Title {
    let romaji: String
    let english: String?
    let native: String?
}

struct CoverImage {
    let large: String
}
