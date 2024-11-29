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
        view.viewWithTag(999)?.removeFromSuperview()
        navigationController?.navigationBar.prefersLargeTitles = true
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
        dataSource = UICollectionViewDiffableDataSource<Int, FavoriteItem>(collectionView: collectionView) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath) as! FavoriteCell
            cell.configure(with: item)
            
            if self?.isEditingMode == true {
                self?.addShakeAnimation(to: cell)
            } else {
                self?.removeShakeAnimation(from: cell)
            }
            
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
    
    private let emptyStateMessages = [
        "Your favorites list is currently empty. Time to add some gems!",
        "Nothing here yet—start building your collection today!",
        "Your favorites seem to be missing. Why not find something new to love?",
        "This space is waiting for your top picks. Add your favorites now!",
        "Nothing yet? Let’s change that and make this list shine!",
        "Your Library shelf is ready for its first addition.",
        "It’s a little quiet here—perfect time to discover something great.",
        "Your list is empty. Add an item to start your collection.",
        "Looks like you haven’t added anything yet. Start exploring!",
        "This page is just waiting for your personal touch. Add a favorite!"
    ]
    
    private func loadFavorites() {
        favorites = FavoritesManager.shared.getFavorites()
        sortFavorites()
        applySnapshot()
        
        if favorites.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = emptyStateMessages.randomElement()
            emptyLabel.numberOfLines = 0
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyLabel)
            
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
            ])
            
            emptyLabel.tag = 999
        } else {
            view.viewWithTag(999)?.removeFromSuperview()
        }
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
        
        collectionView.performBatchUpdates({
            for cell in collectionView.visibleCells {
                if let indexPath = collectionView.indexPath(for: cell) {
                    if isEditingMode {
                        addShakeAnimation(to: cell)
                    } else {
                        removeShakeAnimation(from: cell)
                        
                        if let favoriteCell = cell as? FavoriteCell,
                           let item = dataSource.itemIdentifier(for: indexPath) {
                            favoriteCell.configure(with: item)
                        }
                    }
                }
            }
        }, completion: nil)
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

extension FavoritesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sortedFavorites.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return dataSource.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if isEditingMode {
            addShakeAnimation(to: cell)
        } else {
            removeShakeAnimation(from: cell)
        }
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
        let selectedMedaiSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
        
        detailVC.configure(title: title, imageUrl: imageUrl, href: href, source: selectedMedaiSource)
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
        guard isEditingMode,
              let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first?.dragItem.localObject as? FavoriteItem else {
                  return
              }
        
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([item])
        
        if destinationIndexPath.item < snapshot.itemIdentifiers.count {
            snapshot.insertItems([item], beforeItem: snapshot.itemIdentifiers[destinationIndexPath.item])
        } else {
            snapshot.appendItems([item])
        }
        
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard let self = self else { return }
            
            self.sortedFavorites = snapshot.itemIdentifiers
            self.favorites = self.sortedFavorites
            FavoritesManager.shared.saveFavorites(self.favorites)
            
            NotificationCenter.default.post(name: FavoritesManager.favoritesChangedNotification, object: nil)
        }
        
        coordinator.drop(coordinator.items.first!.dragItem, toItemAt: destinationIndexPath)
    }
}
