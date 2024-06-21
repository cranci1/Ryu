//
//  LibraryView.swift
//  AnimeLounge
//
//  Created by Francesco on 20/06/24.
//

import UIKit

class LibraryView: UIViewController {
    
    @IBOutlet var FavoritesBox: UIView!
    @IBOutlet var RecentsBox: UIView!
    @IBOutlet var DownloadBox: UIView!
    
    @IBOutlet var AnilistConnect: UIView!
    @IBOutlet var AnilistImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FavoritesBox.layer.cornerRadius = 12
        RecentsBox.layer.cornerRadius = 12
        DownloadBox.layer.cornerRadius = 12
        
        AnilistImage.layer.cornerRadius = 12
        AnilistImage.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        AnilistConnect.layer.cornerRadius = 12
    }
    
}
