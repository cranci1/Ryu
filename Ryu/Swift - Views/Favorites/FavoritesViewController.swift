//
//  FavoritesViewController.swift
//  Ryu
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher

struct FavoriteItem: Codable, Hashable {
    let title: String
    let imageURL: URL
    let contentURL: URL
    let source: String
}

enum SortOption: String, CaseIterable {
    case normal = "Normal"
    case alphabetical = "A-Z"
    case alphabeticalReversed = "Z-A"
}

class FavoritesViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, FavoriteItem>!
    private var favorites: [FavoriteItem] = []
    private var sortedFavorites: [FavoriteItem] = []
    private var currentSortOption: SortOption = .normal
    private var isEditingMode = false {
        didSet {
            updateEditingState()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupDataSource()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        let nib = UINib(nibName: "FavoriteCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "FavoriteCell")
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, FavoriteItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath) as! FavoriteCell
            cell.configure(with: item)
            return cell
        }
    }
    
    private func setupNavigationBar() {
        let tealColor = UIColor.systemTeal

        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped))
        editButton.tintColor = tealColor
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(sortButtonTapped))
        sortButton.tintColor = tealColor
        
        navigationItem.rightBarButtonItems = [editButton, sortButton]
        navigationController?.navigationBar.tintColor = tealColor
    }
    
    private func loadFavorites() {
        favorites = FavoritesManager.shared.getFavorites()
        sortFavorites()
        applySnapshot()
    }
    
    private func sortFavorites() {
        switch currentSortOption {
        case .normal:
            sortedFavorites = favorites
        case .alphabetical:
            sortedFavorites = favorites.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .alphabeticalReversed:
            sortedFavorites = favorites.sorted { $0.title.lowercased() > $1.title.lowercased() }
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, FavoriteItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(sortedFavorites)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func updateEditingState() {
        navigationItem.rightBarButtonItem?.title = isEditingMode ? "Done" : "Edit"
        collectionView.visibleCells.forEach { cell in
            if isEditingMode {
                addShakeAnimation(to: cell)
            } else {
                removeShakeAnimation(from: cell)
            }
        }
    }
    
    @objc private func editButtonTapped() {
        isEditingMode.toggle()
    }
    
    @objc private func sortButtonTapped() {
        showSortOptions()
    }
    
    private func showSortOptions() {
        let alertController = UIAlertController(title: "Sort Favorites", message: nil, preferredStyle: .actionSheet)
        
        for option in SortOption.allCases {
            let action = UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                self?.currentSortOption = option
                self?.sortFavorites()
                self?.applySnapshot()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: point) {
            showRemoveMenu(for: indexPath)
        }
    }
    
    private func showRemoveMenu(for indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let removeAction = UIAlertAction(title: "Remove from Favorites", style: .destructive) { [weak self] _ in
            self?.removeFavorite(at: indexPath)
        }
        alertController.addAction(removeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            if let cell = collectionView.cellForItem(at: indexPath) {
                popoverController.sourceView = cell
                popoverController.sourceRect = cell.bounds
            }
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func removeFavorite(at indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        favorites.removeAll { $0 == item }
        FavoritesManager.shared.saveFavorites(favorites)
        sortFavorites()
        applySnapshot()
        NotificationCenter.default.post(name: FavoritesManager.favoritesChangedNotification, object: nil)
    }
    
    private func addShakeAnimation(to view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
        animation.values = [-0.02, 0.02, -0.02]
        animation.duration = 0.25
        animation.repeatCount = Float.infinity
        view.layer.add(animation, forKey: "shake")
    }
    
    private func removeShakeAnimation(from view: UIView) {
        view.layer.removeAnimation(forKey: "shake")
    }
}

extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isEditingMode, let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        UserDefaults.standard.set(item.source, forKey: "selectedMediaSource")
        
        navigateToAnimeDetail(title: item.title, imageUrl: item.imageURL.absoluteString, href: item.contentURL.absoluteString)
    }
    
    func navigateToAnimeDetail(title: String, imageUrl: String, href: String) {
        let detailVC = AnimeDetailViewController()
        detailVC.configure(title: title, imageUrl: imageUrl, href: href)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension FavoritesViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingMode, let item = dataSource.itemIdentifier(for: indexPath) else { return [] }
        let itemProvider = NSItemProvider(object: item.title as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard isEditingMode else { return UICollectionViewDropProposal(operation: .forbidden) }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let dragItem = item.dragItem.localObject as? FavoriteItem else { return }
        
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([dragItem])
        snapshot.insertItems([dragItem], beforeItem: snapshot.itemIdentifiers[destinationIndexPath.item])
        
        dataSource.apply(snapshot, animatingDifferences: true) {
            self.sortedFavorites = snapshot.itemIdentifiers
            self.favorites = self.sortedFavorites
            FavoritesManager.shared.saveFavorites(self.favorites)
        }
        
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
    }
}
