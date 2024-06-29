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
    var isEditingMode = false {
        didSet {
            updateShakeAnimation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupEditButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        let nib = UINib(nibName: "FavoriteCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "FavoriteCell")
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    private func setupEditButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped))
    }
    
    private func loadFavorites() {
        favorites = FavoritesManager.shared.getFavorites()
        collectionView.reloadData()
    }
    
    @objc private func editButtonTapped() {
        isEditingMode.toggle()
        navigationItem.rightBarButtonItem?.title = isEditingMode ? "Done" : "Edit"
        collectionView.reloadData()
    }
    
    private func updateShakeAnimation() {
        for cell in collectionView.visibleCells {
            if isEditingMode {
                addShakeAnimation(to: cell)
            } else {
                removeShakeAnimation(from: cell)
            }
        }
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
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point) {
                showRemoveMenu(for: indexPath)
            }
        }
    }
    
    func showRemoveMenu(for indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let reorderAction = UIAlertAction(title: "Reorder Favorites", style: .default) { [weak self] _ in
            self?.isEditingMode = true
            self?.navigationItem.rightBarButtonItem?.title = "Done"
            self?.collectionView.reloadData()
        }
        reorderAction.setValue(UIImage(systemName: "arrow.up.arrow.down"), forKey: "image")
        alertController.addAction(reorderAction)
        
        let removeAction = UIAlertAction(title: "Remove from Favorites", style: .destructive) { [weak self] _ in
            self?.removeFavorite(at: indexPath)
        }
        removeAction.setValue(UIImage(systemName: "trash"), forKey: "image")
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
    
    func removeFavorite(at indexPath: IndexPath) {
        favorites.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        FavoritesManager.shared.saveFavorites(favorites)
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
        
        if isEditingMode {
            addShakeAnimation(to: cell)
        } else {
            removeShakeAnimation(from: cell)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isEditingMode {
            let item = favorites[indexPath.item]
            navigateToAnimeDetail(title: item.title, imageUrl: item.imageURL.absoluteString, href: item.contentURL.absoluteString)
        }
    }
    
    func navigateToAnimeDetail(title: String, imageUrl: String, href: String) {
        let detailVC = AnimeDetailViewController()
        detailVC.configure(title: title, imageUrl: imageUrl, href: href)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @IBAction func selectSourceButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Select Source", message: "Choose your preferred source for AnimeLounge.", preferredStyle: .actionSheet)
        
        let worldAction = UIAlertAction(title: "AnimeWorld", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animeWorld
        }
        setUntintedImage(for: worldAction, named: "AnimeWorld")
        
        let gogoAction = UIAlertAction(title: "GoGoAnime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .gogoanime
        }
        setUntintedImage(for: gogoAction, named: "GoGoAnime")
        
        let heavenAction = UIAlertAction(title: "AnimeHeaven", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animeheaven
        }
        setUntintedImage(for: heavenAction, named: "AnimeHeaven")
        
        let fireAction = UIAlertAction(title: "AnimeFire", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animefire
        }
        setUntintedImage(for: fireAction, named: "AnimeFire")
        
        let kuraAction = UIAlertAction(title: "Kuramanime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .kuramanime
        }
        setUntintedImage(for: kuraAction, named: "Kuramanime")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(worldAction)
        alertController.addAction(gogoAction)
        alertController.addAction(heavenAction)
        alertController.addAction(fireAction)
        alertController.addAction(kuraAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func setUntintedImage(for action: UIAlertAction, named imageName: String) {
        if let originalImage = UIImage(named: imageName) {
            let resizedImage = resizeImage(originalImage, targetSize: CGSize(width: 35, height: 35))
            if let untintedImage = resizedImage?.withRenderingMode(.alwaysOriginal) {
                action.setValue(untintedImage, forKey: "image")
            }
        }
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension FavoritesViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingMode else { return [] }
        let item = favorites[indexPath.item]
        let itemProvider = NSItemProvider(object: item.title as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard isEditingMode else { return UICollectionViewDropProposal(operation: .forbidden) }
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath {
            collectionView.performBatchUpdates({
                let movedItem = favorites.remove(at: sourceIndexPath.item)
                favorites.insert(movedItem, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: { _ in
                FavoritesManager.shared.saveFavorites(self.favorites)
            })
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
}

extension FavoritesViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { favorites[$0.item].imageURL }
        ImagePrefetcher(urls: urls).start()
    }
}
