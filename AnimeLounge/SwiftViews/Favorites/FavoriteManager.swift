//
//  FavoriteManager.swift
//  AnimeLounge
//
//  Created by Francesco on 26/06/24.
//

import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    private let favoritesKey = "FavoriteItems"
    
    private init() {}
    
    func addFavorite(_ item: FavoriteItem) {
        var favorites = getFavorites()
        favorites.append(item)
        saveFavorites(favorites)
    }
    
    func removeFavorite(_ item: FavoriteItem) {
        var favorites = getFavorites()
        favorites.removeAll { $0.contentURL == item.contentURL }
        saveFavorites(favorites)
    }
    
    func getFavorites() -> [FavoriteItem] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return [] }
        return (try? JSONDecoder().decode([FavoriteItem].self, from: data)) ?? []
    }
    
    private func saveFavorites(_ favorites: [FavoriteItem]) {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
    
    func isFavorite(_ item: FavoriteItem) -> Bool {
        return getFavorites().contains { $0.contentURL == item.contentURL }
    }
}
