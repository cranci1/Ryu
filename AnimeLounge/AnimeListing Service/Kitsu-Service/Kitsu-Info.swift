//
//  Kitsu-Info.swift
//  AnimeLounge
//
//  Created by Francesco on 04/08/24.
//

import Foundation

class KitsuService {
    static func fetchAnimeDetails(animeID: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "https://kitsu.io/api/edge/anime/\(animeID)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "KitsuService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "KitsuService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let animeData = json["data"] as? [String: Any],
                   let attributes = animeData["attributes"] as? [String: Any] {
                    
                    // Process the animeData to match the expected format
                    var processedData: [String: Any] = [:]
                    
                    // Title
                    if let titles = attributes["titles"] as? [String: String] {
                        processedData["title"] = [
                            "romaji": titles["en_jp"] ?? "",
                            "english": titles["en"] ?? ""
                        ]
                    }
                    
                    // Description
                    processedData["description"] = attributes["synopsis"] as? String
                    
                    // Cover Image
                    if let posterImage = attributes["posterImage"] as? [String: Any],
                       let originalImageURL = posterImage["original"] as? String {
                        processedData["coverImage"] = ["extraLarge": originalImageURL]
                    }
                    
                    // Episodes
                    processedData["episodes"] = attributes["episodeCount"] as? Int
                    
                    // Status
                    if let status = attributes["status"] as? String {
                        processedData["status"] = status.capitalized
                    }
                    
                    // Start Date
                    if let startDate = attributes["startDate"] as? String {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: startDate) {
                            let calendar = Calendar.current
                            let components = calendar.dateComponents([.year, .month, .day], from: date)
                            processedData["startDate"] = [
                                "year": components.year,
                                "month": components.month,
                                "day": components.day
                            ]
                        }
                    }
                    
                    // Genres (Note: Kitsu API doesn't provide genres in this endpoint, you might need an additional API call)
                    processedData["genres"] = []
                    
                    completion(.success(processedData))
                } else {
                    completion(.failure(NSError(domain: "KitsuService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
