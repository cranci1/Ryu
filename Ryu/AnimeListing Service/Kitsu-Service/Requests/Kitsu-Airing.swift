//
//  Kitsu-Airing.swift
//  Ryu
//
//  Created by Francesco on 27/07/24.
//

import Alamofire
import Foundation

class KitsuServiceAiringAnime {
    let session = proxySession.createAlamofireProxySession()
    
    func fetchAiringAnime(completion: @escaping ([Anime]?) -> Void) {
        let url = "https://kitsu.io/api/edge/anime?filter[status]=current"
        
        session.request(url)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [[String: Any]] {
                        
                        let airingAnime: [Anime] = data.compactMap { item in
                            guard let id = item["id"] as? String,
                                  let attributes = item["attributes"] as? [String: Any],
                                  let titles = attributes["titles"] as? [String: String],
                                  let posterImage = attributes["posterImage"] as? [String: Any],
                                  let originalImageUrl = posterImage["original"] as? String else {
                                return nil
                            }
                            
                            let title = titles["en"] ?? titles["en_jp"] ?? "Title Not Available"
                            let episodes = attributes["episodeCount"] as? Int
                            let description = attributes["synopsis"] as? String
                            
                            let anime = Anime(
                                id: Int(id) ?? 0,
                                title: Title(romaji: title, english: title, native: title),
                                coverImage: CoverImage(large: originalImageUrl),
                                episodes: episodes,
                                description: description,
                                airingAt: nil
                            )
                            return anime
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
