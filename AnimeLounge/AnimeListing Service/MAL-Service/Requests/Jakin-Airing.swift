//
//  Jakin-Airing.swift
//  AnimeLounge
//
//  Created by Francesco on 27/07/24.
//

import Alamofire
import Foundation

class JikanServiceAiringAnime {
    
    func fetchAiringAnime(completion: @escaping ([Anime]?) -> Void) {
        let url = "https://api.jikan.moe/v4/schedules"
        
        AF.request(url)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [[String: Any]] {
                        
                        let airingAnime: [Anime] = data.compactMap { item in
                            guard let id = item["mal_id"] as? Int,
                                  let title = item["title"] as? String,
                                  let images = item["images"] as? [String: Any],
                                  let jpg = images["jpg"] as? [String: Any],
                                  let imageUrl = jpg["large_image_url"] as? String,
                                  let description = item["synopsis"] as? String else {
                                return nil
                            }
                            
                            return Anime(
                                id: id,
                                title: Title(romaji: title, english: title, native: title),
                                coverImage: CoverImage(large: imageUrl),
                                episodes: nil,
                                description: description,
                                airingAt: nil
                            )
                        }
                        
                        completion(airingAnime)
                    } else {
                        print("Error parsing JSON or missing expected fields")
                        completion(nil)
                    }
                    
                case .failure(let error):
                    print("Error fetching airing anime: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }
}
