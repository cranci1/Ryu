//
//  WatchNextViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Alamofire

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
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "TrendingAnimeCell", bundle: nil), forCellWithReuseIdentifier: "TrendingAnimeCell")
        
        seasonalCollectionView.delegate = self
        seasonalCollectionView.dataSource = self
        seasonalCollectionView.register(UINib(nibName: "SeasonalAnimeCell", bundle: nil), forCellWithReuseIdentifier: "SeasonalAnimeCell")
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        
        let dateString = dateFormatter.string(from: currentDate)
        dateLabel.text = "on \(dateString)"
        
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
                print("Failed to fetch trending anime")
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

// Models for decoding JSON response
struct Anime: Codable {
    let id: Int
    let title: Title
    let coverImage: CoverImage
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case coverImage = "coverImage"
    }
}

struct Title: Codable {
    let romaji: String
}

struct CoverImage: Codable {
    let large: String
}

extension WatchNextViewController: UICollectionViewDelegate {
}

