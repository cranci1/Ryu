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
        
        var cleanDescription = description ?? "Description not available"
        cleanDescription = cleanDescription.replacingOccurrences(of: "<br>", with: "")
        cleanDescription = cleanDescription.replacingOccurrences(of: "<i>", with: "")
        cleanDescription = cleanDescription.replacingOccurrences(of: "</i>", with: "")
        
        descriptionLabel.text = cleanDescription
        
        if let airingAt = airingAt {
            let date = Date(timeIntervalSince1970: TimeInterval(airingAt))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, HH:mm zzz"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale.current
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm zzz"
            timeFormatter.timeZone = TimeZone.current
            timeFormatter.locale = Locale.current
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let airingDate = calendar.startOfDay(for: date)
            
            let dayText: String
            if airingDate == today {
                dayText = "Today, \(timeFormatter.string(from: date))"
            } else if airingDate == tomorrow {
                dayText = "Tomorrow, \(timeFormatter.string(from: date))"
            } else {
                dayText = dateFormatter.string(from: date)
            }
            
            airingAtLabel.text = dayText
        } else {
            airingAtLabel.text = "Airing date: N/A"
        }
    }
}
