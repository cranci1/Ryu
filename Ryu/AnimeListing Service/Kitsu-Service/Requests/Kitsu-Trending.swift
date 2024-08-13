//
//  Kitsu-Trending.swift
//  Ryu
//
//  Created by Francesco on 27/07/24.
//

import Alamofire
import Foundation

class KitsuServiceTrendingAnime {
    func fetchTrendingAnime(completion: @escaping ([Anime]?) -> Void) {
        let url = "https://kitsu.io/api/edge/trending/anime?page"
        
        AF.request(url)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [[String: Any]] {
                        
                        let trendingAnime: [Anime] = data.compactMap { item in
                            guard let id = item["id"] as? String,
                                  let attributes = item["attributes"] as? [String: Any],
                                  let titles = attributes["titles"] as? [String: String],
                                  let posterImage = attributes["posterImage"] as? [String: Any],
                                  let originalImageUrl = posterImage["original"] as? String else {
                                return nil
                            }
                            
                            let title = titles["en"] ?? titles["en_jp"] ?? "Title Not Available"
                            let anime = Anime(
                                id: Int(id) ?? 0,
                                title: Title(romaji: title, english: title, native: title),
                                coverImage: CoverImage(large: originalImageUrl),
                                episodes: nil,
                                description: nil,
                                airingAt: nil
                            )
                            return anime
                        }
                        
                        completion(trendingAnime)
                    } else {
                        print("Error parsing JSON or missing expected fields")
                        completion(nil)
                    }
                    
                case .failure(let error):
                    print("Error fetching trending anime: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }
}
