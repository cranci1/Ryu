//
//  TrendingAnimeCell-Swift.swift
//  Ryu
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Kingfisher

class SlimmAnimeCell: UICollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var animeImageView: UIImageView!
    
    func configure(with title: String, imageUrl: URL?) {
        titleLabel.text = title
        
        animeImageView.kf.indicatorType = .activity
        animeImageView.kf.setImage(with: imageUrl, placeholder: UIImage(named: "no_image"), options: [.transition(.fade(0.2))])
    }
}

