//
//  SearchResultCell.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Kingfisher

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    func configure(with title: String, imageUrl: String) {
        titleLabel.text = title
        
        if let url = URL(string: imageUrl) {
            thumbnailImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"), options: [.transition(.fade(0.2)), .cacheOriginalImage])
        }
    }
}
