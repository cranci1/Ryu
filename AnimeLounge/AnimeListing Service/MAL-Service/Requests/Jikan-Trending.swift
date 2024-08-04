//
//  Jakin-Trending.swift
//  AnimeLounge
//
//  Created by Francesco on 27/07/24.
//

import Alamofire
import Foundation

class JikanServiceTrendingAnime {
    func fetchTrendingAnime(completion: @escaping ([Anime]?) -> Void) {
        let url = "https://api.jikan.moe/v4/top/anime?filter=airing"
        
        AF.request(url)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [[String: Any]] {
                        
                        let trendingAnime: [Anime] = data.compactMap { item in
                            guard let id = item["mal_id"] as? Int,
                                  let title = item["title"] as? String,
                                  let images = item["images"] as? [String: Any],
                                  let jpg = images["jpg"] as? [String: Any],
                                  let imageUrl = jpg["large_image_url"] as? String else {
                                return nil
                            }
                            
                            return Anime(
                                id: id,
                                title: Title(romaji: title, english: title, native: title),
                                coverImage: CoverImage(large: imageUrl),
                                episodes: nil,
                                description: nil,
                                airingAt: nil
                            )
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
