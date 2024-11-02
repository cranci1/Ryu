//
//  ContinueWatchingCell.swift
//  Ryu
//
//  Created by Francesco on 19/09/24.
//

import UIKit
import Kingfisher

class ContinueWatchingCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressView = UIProgressView()
    private let blurEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: effect)
        blurEffectView.alpha = 0.75
        return blurEffectView
    }()
    
    private var imageLoadTask: DownloadTask?
    private var currentAnimeTitle: String?
    private var currentEpisodeNumber: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        progressView.progress = 0
        currentAnimeTitle = nil
        currentEpisodeNumber = nil
    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.addSubview(blurEffectView)
        imageView.addSubview(progressView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left
        
        progressView.progressTintColor = .systemTeal
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentView.heightAnchor.constraint(equalToConstant: 120),
            
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.6),
            
            blurEffectView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            
            progressView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            progressView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            titleLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -4),
            titleLabel.trailingAnchor.constraint(equalTo: progressView.trailingAnchor),
            titleLabel.widthAnchor.constraint(equalTo: progressView.widthAnchor)
        ])
    }
    
    private func getPlaceholderImage() -> UIImage {
        UIImage(systemName: "photo.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal) ?? UIImage()
    }
    
    private func getErrorPlaceholderImage() -> UIImage {
        UIImage(systemName: "exclamationmark.triangle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal) ?? UIImage()
    }
    
    func configure(with item: ContinueWatchingItem) {
        titleLabel.text = "\(item.animeTitle), Ep. \(item.episodeNumber)"
        progressView.progress = Float(item.lastPlayedTime / item.totalTime)
        
        currentAnimeTitle = item.animeTitle
        currentEpisodeNumber = item.episodeNumber
        
        imageView.image = getPlaceholderImage()
        
        AnimeThumbnailFetcher.fetchAnimeThumbnails(for: item.animeTitle, episodeNumber: item.episodeNumber) { [weak self] imageURL in
            DispatchQueue.main.async {
                guard let self = self,
                      let imageURL = imageURL,
                      self.currentAnimeTitle == item.animeTitle,
                      self.currentEpisodeNumber == item.episodeNumber else {
                    return
                }
                
                if let url = URL(string: imageURL) {
                    self.imageLoadTask = self.imageView.kf.setImage(
                        with: url,
                        placeholder: self.getPlaceholderImage(),
                        options: [
                            .transition(.fade(0.2)),
                            .cacheOriginalImage,
                            .callbackQueue(.mainAsync)
                        ]
                    ) { result in
                        switch result {
                        case .success(_):
                            break
                        case .failure(let error):
                            print("Error loading image: \(error)")
                            self.imageView.image = self.getErrorPlaceholderImage()
                        }
                    }
                }
            }
        }
    }
}

class AnimeThumbnailFetcher {
    static let apiUrl = "https://api.ani.zip/mappings?anilist_id="
    
    static func fetchAnimeThumbnails(for title: String, episodeNumber: Int, completion: @escaping (String?) -> Void) {
        fetchAnimeID(for: title) { anilistId in
            guard let anilistId = anilistId else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let url = URL(string: "\(self.apiUrl)\(anilistId)")!
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("Error fetching anime thumbnails: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonDict = json as? [String: Any],
                       let episodes = jsonDict["episodes"] as? [String: Any],
                       let episodeInfo = episodes["\(episodeNumber)"] as? [String: Any],
                       let imageUrl = episodeInfo["image"] as? String {
                        DispatchQueue.main.async {
                            completion(imageUrl)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
            task.resume()
        }
    }
    
    static func fetchAnimeID(for title: String, completion: @escaping (Int?) -> Void) {
        if let customID = UserDefaults.standard.string(forKey: "customAniListID_\(title)"),
           let id = Int(customID) {
            DispatchQueue.main.async {
                completion(id)
            }
            return
        }
        
        let cleanedTitle = cleanTitle(title: title)
        AnimeService.fetchAnimeID(byTitle: cleanedTitle) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let id):
                    completion(id)
                case .failure(let error):
                    print("Error fetching anime ID: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
    
    static func cleanTitle(title: String) -> String {
        let unwantedStrings = ["(ITA)", "(Dub)", "(Dub ID)", "(Dublado)"]
        var cleanedTitle = title
        
        for unwanted in unwantedStrings {
            cleanedTitle = cleanedTitle.replacingOccurrences(of: unwanted, with: "")
        }
        
        cleanedTitle = cleanedTitle.replacingOccurrences(of: "\"", with: "")
        return cleanedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

