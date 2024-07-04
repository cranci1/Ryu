//
//  LibraryView.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit

class LibraryViewControlller: UIViewController {
    
    @IBOutlet weak var favoriteCountLabel: UILabel!
    
    @IBOutlet var FavoritesBox: UIView!
    @IBOutlet var RecentsBox: UIView!
    @IBOutlet var DownloadBox: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FavoritesBox.layer.cornerRadius = 12
        RecentsBox.layer.cornerRadius = 12
        DownloadBox.layer.cornerRadius = 12
        
        updateFavoriteCount()
                
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged), name: FavoritesManager.favoritesChangedNotification, object: nil)
    }
    
    func updateFavoriteCount() {
         let count = FavoritesManager.shared.getFavorites().count
         favoriteCountLabel.text = "\(count)"
     }
     
     @objc func favoritesChanged() {
         updateFavoriteCount()
     }
     
     deinit {
         NotificationCenter.default.removeObserver(self)
     }
}
