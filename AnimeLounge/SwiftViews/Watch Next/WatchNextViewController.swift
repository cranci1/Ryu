//
//  WatchNextViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit

class WatchNextViewController: UITableViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var seasonalCollectionView: UICollectionView!
    @IBOutlet weak var dateLabel: UILabel!
    
    private var trendingAnime: [Anime] = []
    private var seasonalAnime: [Anime] = []
    
    private let aniListServiceTrending = AnilistServiceTrendingAnime()
    private let aniListServiceSeasonal = AnilistServiceSeasonalAnime()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupDateLabel()
        fetchAnimeData()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "TrendingAnimeCell", bundle: nil), forCellWithReuseIdentifier: "TrendingAnimeCell")
        
        seasonalCollectionView.delegate = self
        seasonalCollectionView.dataSource = self
        seasonalCollectionView.register(UINib(nibName: "SeasonalAnimeCell", bundle: nil), forCellWithReuseIdentifier: "SeasonalAnimeCell")
    }
    
    func setupDateLabel() {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        let dateString = dateFormatter.string(from: currentDate)
        dateLabel.text = "on \(dateString)"
    }
    
    func fetchAnimeData() {
        fetchTrendingAnime()
        fetchSeasonalAnime()
    }
    
    func fetchTrendingAnime() {
        aniListServiceTrending.fetchTrendingAnime { [weak self] animeList in
            guard let self = self else { return }
            if let animeList = animeList {
                self.trendingAnime = animeList
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } else {
                print("Failed to fetch trending anime")
            }
        }
    }
    
    func fetchSeasonalAnime() {
        aniListServiceSeasonal.fetchSeasonalAnime { [weak self] animeList in
            guard let self = self else { return }
            if let animeList = animeList {
                self.seasonalAnime = animeList
                DispatchQueue.main.async {
                    self.seasonalCollectionView.reloadData()
                }
            } else {
                print("Failed to fetch seasonal anime")
            }
        }
    }
    
}

extension WatchNextViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            return trendingAnime.count
        } else if collectionView == self.seasonalCollectionView {
            return seasonalAnime.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingAnimeCell", for: indexPath) as! TrendingAnimeCell
            let anime = trendingAnime[indexPath.item]
            let imageUrl = URL(string: anime.coverImage.large)
            cell.configure(with: anime.title.romaji, imageUrl: imageUrl)
            return cell
        } else if collectionView == self.seasonalCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SeasonalAnimeCell", for: indexPath) as! SeasonalAnimeCell
            let anime = seasonalAnime[indexPath.item]
            let imageUrl = URL(string: anime.coverImage.large)
            cell.configure(with: anime.title.romaji, imageUrl: imageUrl)
            return cell
        }
        fatalError("Unexpected collection view")
    }
}

extension WatchNextViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedAnime: Anime?
        
        if collectionView == self.collectionView {
            selectedAnime = trendingAnime[indexPath.item]
        } else if collectionView == self.seasonalCollectionView {
            selectedAnime = seasonalAnime[indexPath.item]
        }
        
        guard let anime = selectedAnime else { return }
        
        let storyboard = UIStoryboard(name: "AnilistAnimeInformation", bundle: nil)
        if let animeDetailVC = storyboard.instantiateViewController(withIdentifier: "AnimeInformation") as? AnimeInformation {
            animeDetailVC.animeID = anime.id
            navigationController?.pushViewController(animeDetailVC, animated: true)
        }
    }
}

struct Anime {
    let id: Int
    let title: Title
    let coverImage: CoverImage
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
}

struct CoverImage {
    let large: String
}
