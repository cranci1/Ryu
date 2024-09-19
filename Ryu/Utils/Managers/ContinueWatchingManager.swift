//
//  ContinueWatchingManager.swift
//  Ryu
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
    
    var progress: Double {
        return min(max(lastPlayedTime / totalTime, 0), 1)
    }
}

class ContinueWatchingManager {
    static let shared = ContinueWatchingManager()
    
    private let userDefaults: UserDefaults
    private let continueWatchingKey = "continueWatchingItems"
    private let mergeWatchingKey = "mergeWatching"
    
    private var items: [ContinueWatchingItem] = []
    private let queue = DispatchQueue(label: "com.continuewatching.queue", attributes: .concurrent)
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadItems()
    }
    
    private func loadItems() {
        queue.async(flags: .barrier) { [weak self] in
            guard let data = self?.userDefaults.data(forKey: self?.continueWatchingKey ?? ""),
                  let loadedItems = try? JSONDecoder().decode([ContinueWatchingItem].self, from: data) else {
                return
            }
            self?.items = loadedItems
        }
    }
    
    func saveItem(_ item: ContinueWatchingItem) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if let index = self.items.firstIndex(where: { $0.fullURL == item.fullURL }) {
                self.items.remove(at: index)
            }
            
            if self.getMergeWatching() {
                if let existingIndex = self.items.firstIndex(where: { $0.animeTitle == item.animeTitle }) {
                    let existingItem = self.items[existingIndex]
                    if item.episodeNumber > existingItem.episodeNumber {
                        self.items.remove(at: existingIndex)
                        self.items.insert(item, at: 0)
                    }
                } else {
                    self.items.insert(item, at: 0)
                }
            } else {
                self.items.insert(item, at: 0)
            }
            
            self.saveItemsToDisk()
        }
    }
    
    func getItems() -> [ContinueWatchingItem] {
        var result: [ContinueWatchingItem] = []
        queue.sync {
            result = self.items.filter { $0.shouldDisplay }
        }
        return result
    }
    
    func clearItem(fullURL: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.items.removeAll { $0.fullURL == fullURL }
            self?.saveItemsToDisk()
        }
    }
    
    func clearAllItems() {
        queue.async(flags: .barrier) { [weak self] in
            self?.items.removeAll()
            self?.saveItemsToDisk()
        }
    }
    
    func setMergeWatching(_ value: Bool) {
        userDefaults.set(value, forKey: mergeWatchingKey)
    }
    
    func getMergeWatching() -> Bool {
        return userDefaults.bool(forKey: mergeWatchingKey)
    }
    
    private func saveItemsToDisk() {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: continueWatchingKey)
        } catch {
            print("Error saving continue watching items: \(error)")
        }
    }
}
