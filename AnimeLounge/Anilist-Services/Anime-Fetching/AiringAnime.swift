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
        let startTime = Int(Date().timeIntervalSince1970)
        let endTime = startTime + (7 * 24 * 60 * 60)
        
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let variables: [String: Any] = [
            "page": 1,
            "perPage": 50,
            "startTime": startTime - timezoneOffset,
            "endTime": endTime - timezoneOffset
        ]
        
        let query = """
        query($page: Int, $perPage: Int, $startTime: Int, $endTime: Int) {
            Page(page: $page, perPage: $perPage) {
                pageInfo {
                    total
                    hasNextPage
                }
                airingSchedules(
                    sort: TIME,
                    airingAt_greater: $startTime,
                    airingAt_lesser: $endTime
                ) {
                    id
                    episode
                    airingAt
                    media {
                        id
                        isAdult
                        episodes
                        description
                        coverImage {
                            extraLarge
                        }
                        title {
                            userPreferred
                            romaji
                            english
                            native
                        }
                        mediaListEntry {
                            status
                            progress
                        }
                    }
                }
            }
        }
        """
        
        let parameters: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        AF.request("https://graphql.anilist.co", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    guard let data = value as? [String: Any],
                          let pageData = data["data"] as? [String: Any],
                          let page = pageData["Page"] as? [String: Any],
                          let airingSchedules = page["airingSchedules"] as? [[String: Any]] else {
                        
                        print("Error parsing JSON or missing expected fields")
                        completion(nil)
                        return
                    }
                    
                    let airingAnime: [Anime] = airingSchedules.compactMap { schedule -> Anime? in
                        guard let media = schedule["media"] as? [String: Any],
                              let id = media["id"] as? Int,
                              let titleData = media["title"] as? [String: Any],
                              let romaji = titleData["romaji"] as? String,
                              let english = titleData["english"] as? String?,
                              let native = titleData["native"] as? String?,
                              let coverImageData = media["coverImage"] as? [String: Any],
                              let extraLargeImageUrl = coverImageData["extraLarge"] as? String,
                              let imageUrl = URL(string: extraLargeImageUrl) else {
                            return nil
                        }
                        
                        let episodes = media["episodes"] as? Int
                        let description = media["description"] as? String
                        let airingAt = schedule["airingAt"] as? Int
                        
                        return Anime(
                            id: id,
                            title: Title(romaji: romaji, english: english, native: native),
                            coverImage: CoverImage(large: imageUrl.absoluteString),
                            episodes: episodes,
                            description: description,
                            airingAt: airingAt
                        )
                    }
                    
                    completion(airingAnime)
                    
                case .failure(let error):
                    print("Error fetching airing anime: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }
}
