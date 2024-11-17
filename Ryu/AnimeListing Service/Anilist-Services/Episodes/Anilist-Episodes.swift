//
//  Anilist-Episodes.swift
//  Ryu
//
//  Created by Francesco on 20/10/24.
//

import Foundation
import UserNotifications

class AnimeEpisodeService {
    static func fetchEpisodesSchedule(animeID: Int, animeName: String, mediaSource: String) {
        let query = """
        query {
            Media(id: \(animeID), type: ANIME) {
                status
                nextAiringEpisode {
                    airingAt
                    episode
                }
                airingSchedule(notYetAired: true) {
                    nodes {
                        airingAt
                        episode
                    }
                }
            }
        }
        """
        
        let apiUrl = URL(string: "https://graphql.anilist.co")!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": query], options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to fetch episodes: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let media = data["Media"] as? [String: Any],
                   let status = media["status"] as? String {
                    
                    guard status == "RELEASING" else {
                        print("Anime is not currently airing")
                        return
                    }
                    
                    if let airingSchedule = media["airingSchedule"] as? [String: Any],
                       let nodes = airingSchedule["nodes"] as? [[String: Any]] {
                        scheduleNotifications(forAnimeID: animeID, animeName: animeName, episodes: nodes, mediaSource: mediaSource)
                        print("scheduling notifications")
                    } else {
                        print("No airing schedule found")
                    }
                } else {
                    print("Invalid response format")
                }
            } catch {
                print("Failed to parse response: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private static func scheduleNotifications(forAnimeID animeID: Int, animeName: String, episodes: [[String: Any]], mediaSource: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getPendingNotificationRequests { requests in
            let existingIdentifiers = requests.map { $0.identifier }
            
            for episode in episodes {
                guard let timestamp = episode["airingAt"] as? Int,
                      let episodeNumber = episode["episode"] as? Int else {
                    continue
                }
                let notificationDate = Date(timeIntervalSince1970: TimeInterval(timestamp)).addingTimeInterval(3600)
                guard notificationDate > Date() else { continue }
                
                let identifier = "anime_\(animeID)_episode_\(episodeNumber)"
                
                if existingIdentifiers.contains(identifier) {
                    print("Notification for episode \(episodeNumber) is already scheduled, skipping.")
                    continue
                }
                
                let content = UNMutableNotificationContent()
                content.title = "New Episode available"
                content.body = """
                    Episode \(episodeNumber) of "\(animeName)" is now available!
                    You can now watch it on \(mediaSource)
                    """
                content.sound = .default
                
                let triggerDate = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: notificationDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification for \(animeName) episode \(episodeNumber): \(error.localizedDescription)")
                    } else {
                        print("Successfully scheduled notification for \(animeName) episode \(episodeNumber) at \(notificationDate)")
                    }
                }
            }
        }
    }
    
    static func cancelNotifications(forAnimeID animeID: Int) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.filter {
                $0.identifier.starts(with: "anime_\(animeID)_")
            }.map { $0.identifier }
            
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled all notifications for anime ID: \(animeID)")
        }
    }
}
