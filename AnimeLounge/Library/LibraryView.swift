//
//  LibraryView.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit

class LibraryView: UIViewController {
    
    @IBOutlet var FavoritesBox: UIView!
    @IBOutlet var RecentsBox: UIView!
    @IBOutlet var DownloadBox: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FavoritesBox.layer.cornerRadius = 12
        RecentsBox.layer.cornerRadius = 12
        DownloadBox.layer.cornerRadius = 12
    }
}
