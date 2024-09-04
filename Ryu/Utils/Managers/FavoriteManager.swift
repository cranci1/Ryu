//
//  FavoriteManager.swift
//  Ryu
//
//  Created by Francesco on 26/06/24.
//

import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    private let favoritesKey = "FavoriteItems"
    static let favoritesChangedNotification = Notification.Name("FavoritesChangedNotification")
    
    private init() {}
    
    func addFavorite(_ item: FavoriteItem) {
        var favorites = getFavorites()
        if !favorites.contains(where: { $0.contentURL == item.contentURL }) {
            favorites.append(item)
            saveFavorites(favorites)
            NotificationCenter.default.post(name: FavoritesManager.favoritesChangedNotification, object: nil)
        }
    }
    
    func removeFavorite(_ item: FavoriteItem) {
        var favorites = getFavorites()
        if let index = favorites.firstIndex(where: { $0.contentURL == item.contentURL }) {
            favorites.remove(at: index)
            saveFavorites(favorites)
            NotificationCenter.default.post(name: FavoritesManager.favoritesChangedNotification, object: nil)
        }
    }
    
    func getFavorites() -> [FavoriteItem] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return [] }
        return (try? JSONDecoder().decode([FavoriteItem].self, from: data)) ?? []
    }
    
    func saveFavorites(_ favorites: [FavoriteItem]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("Failed to encode favorites: \(error)")
        }
    }
    
    func isFavorite(_ item: FavoriteItem) -> Bool {
        let favorites = getFavorites()
        return favorites.contains(where: { $0.contentURL == item.contentURL })
    }
}
