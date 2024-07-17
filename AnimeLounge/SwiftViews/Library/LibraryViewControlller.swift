//
//  LibraryView.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit

class LibraryViewControlller: UIViewController {
    
    @IBOutlet weak var favoriteCountLabel: UILabel!
    @IBOutlet weak var downloadCountLabel: UILabel!
    
    @IBOutlet var FavoritesBox: UIView!
    @IBOutlet var RecentsBox: UIView!
    @IBOutlet var DownloadBox: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FavoritesBox.layer.cornerRadius = 12
        RecentsBox.layer.cornerRadius = 12
        DownloadBox.layer.cornerRadius = 12
        
        updateFavoriteCount()
        updateDownloadCount()
        
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged), name: FavoritesManager.favoritesChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadsChanged), name: DownloadListViewController.downloadRemovedNotification, object: nil)
    }
    
    func updateFavoriteCount() {
        let count = FavoritesManager.shared.getFavorites().count
        favoriteCountLabel.text = "\(count)"
    }
    
    @objc func favoritesChanged() {
        updateFavoriteCount()
    }
    
    @objc func downloadsChanged() {
        updateDownloadCount()
    }
    
    func updateDownloadCount() {
        let count = fetchDownloadCount()
        downloadCountLabel.text = "\(count)"
    }
    
    func fetchDownloadCount() -> Int {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let downloadURLs = fileURLs.filter { $0.pathExtension == "mpeg" || $0.pathExtension == "mp4" }
            return downloadURLs.count
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return 0
        }
    }
     
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
