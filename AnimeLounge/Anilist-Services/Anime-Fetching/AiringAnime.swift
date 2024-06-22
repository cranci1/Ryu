//
//  AiringAnime.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import Alamofire
import Foundation

class AnilistServiceAiringAnime {
    
    func fetchAiringAnime(completion: @escaping ([Anime]?) -> Void) {
        let query = """
        query($page: Int, $perPage: Int, $startTime: Int, $endTime: Int) {
            Page(page: $page, perPage: $perPage) {
                airingSchedules(
                    sort: [TIME],
                    airingAt_greater: $startTime,
                    airingAt_lesser: $endTime
                ) {
                    id
                    airingAt
                    media {
                        id
                        title {
                            romaji
                            english
                            native
                        }
                        coverImage {
                            extraLarge
                        }
                    }
                }
            }
        }
        """
        
        // Set up variables for the GraphQL query
        let variables: [String: Any] = [
            "page": 1,
            "perPage": 50,
            "startTime": Int(Date().timeIntervalSince1970),
            "endTime": Int(Date().timeIntervalSince1970) + (7 * 24 * 60 * 60)  // Fetch for the next 7 days
        ]
        
        let parameters: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        AF.request("https://graphql.anilist.co", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let page = data["Page"] as? [String: Any],
                       let airingSchedules = page["airingSchedules"] as? [[String: Any]] {
                        
                        let airingAnime: [Anime] = airingSchedules.compactMap { schedule -> Anime? in
                            guard let media = schedule["media"] as? [String: Any],
                                  let id = media["id"] as? Int,
                                  let titleData = media["title"] as? [String: Any],
                                  let romaji = titleData["romaji"] as? String,
                                  let coverImageData = media["coverImage"] as? [String: Any],
                                  let extraLargeImageUrl = coverImageData["extraLarge"] as? String,
                                  let imageUrl = URL(string: extraLargeImageUrl),
                                  let _ = schedule["airingAt"] as? Int else {
                                return nil
                            }
                            
                            let anime = Anime(id: id, title: Title(romaji: romaji), coverImage: CoverImage(large: imageUrl.absoluteString))
                            
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
