//
//  TrendingAnimeCell-Swift.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Kingfisher

class AiringAnimeCell: UICollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var animeImageView: UIImageView!
    @IBOutlet private weak var episodesLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var airingAtLabel: UILabel!
    
    func configure(with title: String, imageUrl: URL?, episodes: Int?, description: String?, airingAt: Int?) {
        titleLabel.text = title
        
        animeImageView.kf.indicatorType = .activity
        animeImageView.kf.setImage(with: imageUrl, placeholder: UIImage(named: "no_image"), options: [.transition(.fade(0.2))])
        
        if let episodes = episodes {
            episodesLabel.text = "Ep. \(episodes)"
        } else {
            episodesLabel.text = "Ep. N/A"
        }
        
        descriptionLabel.text = description ?? "Description not available"
        
        if let airingAt = airingAt {
            let date = Date(timeIntervalSince1970: TimeInterval(airingAt))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, HH:mm zzz"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale.current
            airingAtLabel.text = dateFormatter.string(from: date)
        } else {
            airingAtLabel.text = "Airing date: N/A"
        }
    }
}
