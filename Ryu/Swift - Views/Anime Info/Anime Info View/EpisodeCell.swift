//
//  EpisodeCell.swift
//  Ryu
//
//  Created by Francesco on 25/06/24.
//

import UIKit

struct Episode {
    let number: String
    let href: String
    let downloadUrl: String
    
    var episodeNumber: Int {
        return Int(number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0
    }
}

class EpisodeCell: UITableViewCell {
    let episodeLabel = UILabel()
    let downloadButton = UIButton(type: .system)
    let startnowLabel = UILabel()
    let playbackProgressView = UIProgressView(progressViewStyle: .default)
    let remainingTimeLabel = UILabel()
    
    var episodeNumber: String = ""
    let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
    
    var episode: Episode?
    weak var delegate: AnimeDetailViewController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = UIColor.secondarySystemBackground
        
        contentView.addSubview(episodeLabel)
        contentView.addSubview(downloadButton)
        contentView.addSubview(startnowLabel)
        contentView.addSubview(playbackProgressView)
        contentView.addSubview(remainingTimeLabel)
        
        episodeLabel.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        startnowLabel.translatesAutoresizingMaskIntoConstraints = false
        playbackProgressView.translatesAutoresizingMaskIntoConstraints = false
        remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        episodeLabel.font = UIFont.systemFont(ofSize: 16)
        
        startnowLabel.font = UIFont.systemFont(ofSize: 13)
        startnowLabel.text = "Watch Now"
        startnowLabel.textColor = .secondaryLabel
        
        downloadButton.setImage(UIImage(systemName: "icloud.and.arrow.down"), for: .normal)
        downloadButton.tintColor = .systemTeal
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        
        remainingTimeLabel.font = UIFont.systemFont(ofSize: 12)
        remainingTimeLabel.textColor = .secondaryLabel
        remainingTimeLabel.textAlignment = .right
        
        NSLayoutConstraint.activate([
            episodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            startnowLabel.leadingAnchor.constraint(equalTo: episodeLabel.leadingAnchor),
            startnowLabel.topAnchor.constraint(equalTo: episodeLabel.bottomAnchor, constant: 5),
            
            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 50),
            downloadButton.heightAnchor.constraint(equalToConstant: 50),
            
            playbackProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playbackProgressView.centerYAnchor.constraint(equalTo: startnowLabel.centerYAnchor),
            playbackProgressView.widthAnchor.constraint(equalToConstant: 130),
            
            remainingTimeLabel.leadingAnchor.constraint(equalTo: playbackProgressView.trailingAnchor, constant: 8),
            remainingTimeLabel.centerYAnchor.constraint(equalTo: startnowLabel.centerYAnchor),
            
            contentView.bottomAnchor.constraint(equalTo: startnowLabel.bottomAnchor, constant: 10)
        ])
    }
    
    func updatePlaybackProgress(progress: Float, remainingTime: TimeInterval) {
        playbackProgressView.isHidden = false
        startnowLabel.isHidden = true
        remainingTimeLabel.isHidden = false
        playbackProgressView.progress = progress
        
        if remainingTime < 120 {
            remainingTimeLabel.text = "Finished"
        } else {
            remainingTimeLabel.text = formatRemainingTime(remainingTime)
        }
    }
    
    func resetPlaybackProgress() {
        playbackProgressView.isHidden = true
        startnowLabel.isHidden = false
        remainingTimeLabel.isHidden = true
        playbackProgressView.progress = 0.0
        remainingTimeLabel.text = ""
    }
    
    private func formatRemainingTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if time < 120 {
            return "Finished"
        } else if hours > 0 {
            return String(format: "%d:%02d:%02d left", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d left", minutes, seconds)
        }
    }
    
    func loadSavedProgress(for fullURL: String) {
        let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
        let totalTime = UserDefaults.standard.double(forKey: "totalTime_\(fullURL)")
        
        if totalTime > 0 {
            let progress = Float(lastPlayedTime / totalTime)
            let remainingTime = totalTime - lastPlayedTime
            updatePlaybackProgress(progress: progress, remainingTime: remainingTime)
        } else {
            resetPlaybackProgress()
        }
    }

    func configure(episode: Episode, delegate: AnimeDetailViewController) {
        self.episode = episode
        self.delegate = delegate
        self.episodeNumber = episode.number
        updateEpisodeLabel()
        updateDownloadButtonVisibility()
    }
    
    private func updateEpisodeLabel() {
        episodeLabel.text = "Episode \(episodeNumber)"
    }
    
    private func updateDownloadButtonVisibility() {
        if selectedMediaSource == "GoGoAnime" || selectedMediaSource == "JKAnime" {
            downloadButton.isHidden = true
            downloadButton.isEnabled = false
        } else {
            downloadButton.isHidden = false
            downloadButton.isEnabled = true
        }
    }
    
    @objc private func downloadButtonTapped() {
        if let episode = episode, let delegate = delegate {
            delegate.downloadMedia(for: episode)
        }
    }
}
