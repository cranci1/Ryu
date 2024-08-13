//
//  ContinueWatchingManager.swift
//  AnimeLounge
//
//  Created by Francesco on 07/08/24.
//

import Foundation

struct ContinueWatchingItem: Codable {
    let animeTitle: String
    let episodeTitle: String
    let episodeNumber: Int
    let imageURL: String
    let fullURL: String
    let lastPlayedTime: Double
    let totalTime: Double
    let source: String
    
    var shouldDisplay: Bool {
        let remainingTime = totalTime - lastPlayedTime
        return remainingTime > 120
    }
}

class ContinueWatchingManager {
    static let shared = ContinueWatchingManager()
    
    private let userDefaults = UserDefaults.standard
    private let continueWatchingKey = "continueWatchingItems"
    private let mergeWatchingKey = "mergeWatching"
    
    private init() {}
    
    func saveItem(_ item: ContinueWatchingItem) {
        var items = getItems()
        
        if let index = items.firstIndex(where: { $0.fullURL == item.fullURL }) {
            items.remove(at: index)
        }
        
        if userDefaults.bool(forKey: mergeWatchingKey) {
            if let existingIndex = items.firstIndex(where: { $0.animeTitle == item.animeTitle }) {
                let existingItem = items[existingIndex]
                if item.episodeNumber > existingItem.episodeNumber {
                    items.remove(at: existingIndex)
                    items.insert(item, at: 0)
                }
            } else {
                items.insert(item, at: 0)
            }
        } else {
            items.insert(item, at: 0)
        }
        
        userDefaults.set(try? JSONEncoder().encode(items), forKey: continueWatchingKey)
    }
    
    func getItems() -> [ContinueWatchingItem] {
        guard let data = userDefaults.data(forKey: continueWatchingKey),
              let items = try? JSONDecoder().decode([ContinueWatchingItem].self, from: data) else {
            return []
        }
        return items.filter { $0.shouldDisplay }
    }
    
    func clearItem(fullURL: String) {
        var items = getItems()
        items.removeAll { $0.fullURL == fullURL }
        userDefaults.set(try? JSONEncoder().encode(items), forKey: continueWatchingKey)
    }
    
    func setMergeWatching(_ value: Bool) {
        userDefaults.set(value, forKey: mergeWatchingKey)
    }
    
    func getMergeWatching() -> Bool {
        return userDefaults.bool(forKey: mergeWatchingKey)
    }
}
