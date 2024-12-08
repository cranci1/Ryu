//
//  AniList-Airing.swift
//  Ryu
//
//  Created by Francesco on 22/06/24.
//

import Alamofire
import Foundation

class AnilistServiceAiringAnime {
    let session = proxySession.createAlamofireProxySession()
    
    func fetchAiringAnime(completion: @escaping ([Anime]?) -> Void) {
        let query = """
        query($page: Int, $perPage: Int, $startTime: Int, $endTime: Int) {
            Page(page: $page, perPage: $perPage) {
                pageInfo {
                    total
                    hasNextPage
                }
                airingSchedules(
                    sort: [TIME],
                    airingAt_greater: $startTime,
                    airingAt_lesser: $endTime
                ) {
                    id
                    airingAt
                    media {
                        id
                        isAdult
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
                        nextAiringEpisode {
                            episode
                            airingAt
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
        
        let variables: [String: Any] = [
            "page": 1,
            "perPage": 100,
            "startTime": Int(Date().timeIntervalSince1970),
            "endTime": Int(Date().timeIntervalSince1970) + (7 * 24 * 60 * 60)
        ]
        
        let parameters: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        session.request("https://graphql.anilist.co", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                DispatchQueue.main.async {
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
                                      let english = titleData["english"] as? String?,
                                      let native = titleData["native"] as? String?,
                                      let coverImageData = media["coverImage"] as? [String: Any],
                                      let extraLargeImageUrl = coverImageData["extraLarge"] as? String,
                                      let imageUrl = URL(string: extraLargeImageUrl),
                                      let nextAiringEpisode = media["nextAiringEpisode"] as? [String: Any],
                                      let episode = nextAiringEpisode["episode"] as? Int,
                                      let airingAt = nextAiringEpisode["airingAt"] as? Int else {
                                          return nil
                                      }
                                
                                let description = media["description"] as? String
                                
                                let anime = Anime(
                                    id: id,
                                    title: Title(romaji: romaji, english: english, native: native),
                                    coverImage: CoverImage(large: imageUrl.absoluteString),
                                    episodes: episode,
                                    description: description,
                                    airingAt: airingAt
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
}
