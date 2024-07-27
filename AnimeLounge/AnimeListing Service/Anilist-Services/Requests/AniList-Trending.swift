//
//  AniList-Trending.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import Alamofire
import Foundation

class AnilistServiceTrendingAnime {
    
    func fetchTrendingAnime(completion: @escaping ([Anime]?) -> Void) {
        let query = """
        query {
          Page(page: 1, perPage: 100) {
            media(sort: TRENDING_DESC, type: ANIME, isAdult: false) {
              id
              title {
                romaji
                english
                native
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
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let page = data["Page"] as? [String: Any],
                       let media = page["media"] as? [[String: Any]] {
                        
                        let trendingAnime: [Anime] = media.compactMap { item -> Anime? in
                            guard let id = item["id"] as? Int,
                                  let titleData = item["title"] as? [String: Any],
                                  let romaji = titleData["romaji"] as? String,
                                  let english = titleData["english"] as? String?,
                                  let native = titleData["native"] as? String?,
                                  let coverImageData = item["coverImage"] as? [String: Any],
                                  let largeImageUrl = coverImageData["large"] as? String,
                                  let imageUrl = URL(string: largeImageUrl) else {
                                return nil
                            }
                            
                            let anime = Anime(
                                id: id,
                                title: Title(romaji: romaji, english: english, native: native),
                                coverImage: CoverImage(large: imageUrl.absoluteString),
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
