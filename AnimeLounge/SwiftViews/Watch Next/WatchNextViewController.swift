//
//  WatchNextViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Alamofire

class WatchNextViewController: UIViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var trendingAnime: [Anime] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register the cell class
        collectionView.register(UINib(nibName: "TrendingAnimeCell", bundle: nil), forCellWithReuseIdentifier: "TrendingAnimeCell")
        
        // Fetch trending anime
        fetchTrendingAnime()
    }
    
    func fetchTrendingAnime() {
        let query = """
        query {
          Page(page: 1, perPage: 10) {
            media(sort: TRENDING_DESC, type: ANIME) {
              id
              title {
                romaji
              }
              coverImage {
                large
              }
            }
          }
        }
        """
        
        let parameters: [String: Any] = ["query": query]
        
        AF.request("https://graphql.anilist.co", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let value):
                    print("Response JSON: \(value)")
                    
                    // Parse the JSON response
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let page = data["Page"] as? [String: Any],
                       let media = page["media"] as? [[String: Any]] {
                        
                        // Map each media item to Anime model
                        self.trendingAnime = media.compactMap { item in
                            guard let id = item["id"] as? Int,
                                  let titleData = item["title"] as? [String: Any],
                                  let romaji = titleData["romaji"] as? String,
                                  let coverImageData = item["coverImage"] as? [String: Any],
                                  let largeImageUrl = coverImageData["large"] as? String,
                                  let imageUrl = URL(string: largeImageUrl) else {
                                return nil
                            }
                            
                            let anime = Anime(id: id, title: Title(romaji: romaji), coverImage: CoverImage(large: imageUrl.absoluteString))
                            return anime
                        }
                        
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    } else {
                        print("Error parsing JSON or missing expected fields")
                    }
                    
                case .failure(let error):
                    print("Error fetching trending anime: \(error.localizedDescription)")
                }
            }
    }
}

extension WatchNextViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trendingAnime.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingAnimeCell", for: indexPath) as! TrendingAnimeCell
        let anime = trendingAnime[indexPath.item]
        let imageUrl = URL(string: anime.coverImage.large)
        cell.configure(with: anime.title.romaji, imageUrl: imageUrl)
        return cell
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

extension WatchNextViewController: UICollectionViewDelegate { // Conform to UICollectionViewDelegate
    // Implement delegate methods as needed
}
