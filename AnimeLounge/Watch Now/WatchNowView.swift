//
//  WatchNowView.swift
//  AnimeLounge
//
//  Created by Francesco on 20/06/24.
//

import UIKit

class WatchNowView: UIViewController {
    
    @IBOutlet var AnimeImageContainer: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AnimeImageContainer.layer.cornerRadius = 13
    }
    
}
