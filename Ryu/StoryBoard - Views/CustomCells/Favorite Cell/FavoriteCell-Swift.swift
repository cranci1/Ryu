//
//  FavoriteCell-Swift.swift
//  AnimeLounge
//
//  Created by Francesco on 26/06/24.
//

import UIKit
import Kingfisher

class FavoriteCell: UICollectionViewCell {
    @IBOutlet weak var animeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        animeImageView.contentMode = .scaleAspectFill
        animeImageView.clipsToBounds = true
        animeImageView.layer.cornerRadius = 8
        
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 4
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.adjustsFontSizeToFitWidth = true
    }
    
    func configure(with item: FavoriteItem) {
        titleLabel.text = item.title
        animeImageView.kf.setImage(with: item.imageURL, placeholder: UIImage(named: "placeholder"))
    }
}
