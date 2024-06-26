//
//  FavoritesViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher

struct FavoriteItem: Codable {
    let title: String
    let imageURL: URL
    let contentURL: URL
}

class FavoritesViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var favorites: [FavoriteItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        
        let nib = UINib(nibName: "FavoriteCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "FavoriteCell")
    }
    
    private func loadFavorites() {
        favorites = FavoritesManager.shared.getFavorites()
        collectionView.reloadData()
    }
}

extension FavoritesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath) as! FavoriteCell
        let item = favorites[indexPath.item]
        cell.configure(with: item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = favorites[indexPath.item]
        navigateToAnimeDetail(title: item.title, imageUrl: item.imageURL.absoluteString, href: item.contentURL.absoluteString)
    }
    
    func navigateToAnimeDetail(title: String, imageUrl: String, href: String) {
        let detailVC = AnimeDetailViewController()
        detailVC.configure(title: title, imageUrl: imageUrl, href: href)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension FavoritesViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { favorites[$0.item].imageURL }
        ImagePrefetcher(urls: urls).start()
    }
}
