//
//  Jikan-Info.swift
//  Ryu
//
//  Created by Francesco on 04/08/24.
//

import Foundation

class MALService {
    static func fetchAnimeDetails(animeID: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "https://api.jikan.moe/v4/anime/\(animeID)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "MALService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MALService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let animeData = json["data"] as? [String: Any] {
                    var processedData: [String: Any] = [:]
                    
                    if let titles = animeData["titles"] as? [[String: String]] {
                        var titleData: [String: String] = [:]
                        for title in titles {
                            if let type = title["type"], let titleText = title["title"] {
                                switch type {
                                case "Default":
                                    titleData["romaji"] = titleText
                                case "English":
                                    titleData["english"] = titleText
                                default:
                                    break
                                }
                            }
                        }
                        processedData["title"] = titleData
                    }
                    
                    processedData["description"] = animeData["synopsis"] as? String
                    
                    if let images = animeData["images"] as? [String: Any],
                       let jpgImages = images["jpg"] as? [String: String],
                       let largeImageURL = jpgImages["large_image_url"] {
                        processedData["coverImage"] = ["extraLarge": largeImageURL]
                    }
                    
                    processedData["episodes"] = animeData["episodes"] as? Int
                    
                    processedData["status"] = animeData["status"] as? String
                    
                    if let aired = animeData["aired"] as? [String: Any],
                       let from = aired["from"] as? String {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        if let date = dateFormatter.date(from: from) {
                            let calendar = Calendar.current
                            let components = calendar.dateComponents([.year, .month, .day], from: date)
                            processedData["startDate"] = [
                                "year": components.year,
                                "month": components.month,
                                "day": components.day
                            ]
                        }
                    }
                    
                    if let genres = animeData["genres"] as? [[String: Any]] {
                        processedData["genres"] = genres.compactMap { $0["name"] as? String }
                    }
                    
                    completion(.success(processedData))
                } else {
                    completion(.failure(NSError(domain: "MALService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
