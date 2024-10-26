//
//  EpisodeCell.swift
//  Ryu
//
//  Created by Francesco on 25/06/24.
//

import UIKit
import Kingfisher

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
    let downloadButton = UIImageView()
    let startnowLabel = UILabel()
    let playbackProgressView = UIProgressView(progressViewStyle: .default)
    let remainingTimeLabel = UILabel()
    let infoButton = UIButton(type: .infoLight)
    
    private let progressFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var currentProgress: Float = 0
    private var currentRemainingTime: TimeInterval = 0
    
    var episodeNumber: String = ""
    let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
    
    weak var delegate: AnimeDetailViewController?
    var episode: Episode?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        setupGestureRecognizers()
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
        contentView.addSubview(infoButton)
        
        episodeLabel.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        startnowLabel.translatesAutoresizingMaskIntoConstraints = false
        playbackProgressView.translatesAutoresizingMaskIntoConstraints = false
        remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        
        episodeLabel.font = UIFont.systemFont(ofSize: 16)
        
        startnowLabel.font = UIFont.systemFont(ofSize: 13)
        startnowLabel.text = "Start Watching"
        startnowLabel.textColor = .secondaryLabel
        
        downloadButton.image = UIImage(systemName: "icloud.and.arrow.down")
        downloadButton.tintColor = .systemOrange
        downloadButton.contentMode = .scaleAspectFit
        downloadButton.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(downloadButtonTapped))
        downloadButton.addGestureRecognizer(tapGesture)
        
        remainingTimeLabel.font = UIFont.systemFont(ofSize: 12)
        remainingTimeLabel.textColor = .secondaryLabel
        remainingTimeLabel.textAlignment = .right
        
        infoButton.tintColor = .systemOrange
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        
        playbackProgressView.tintColor = .systemOrange
        
        NSLayoutConstraint.activate([
            episodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            startnowLabel.leadingAnchor.constraint(equalTo: episodeLabel.leadingAnchor),
            startnowLabel.topAnchor.constraint(equalTo: episodeLabel.bottomAnchor, constant: 5),
            
            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 30),
            downloadButton.heightAnchor.constraint(equalToConstant: 30),
            
            playbackProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playbackProgressView.centerYAnchor.constraint(equalTo: startnowLabel.centerYAnchor),
            playbackProgressView.widthAnchor.constraint(equalToConstant: 130),
            
            remainingTimeLabel.leadingAnchor.constraint(equalTo: playbackProgressView.trailingAnchor, constant: 8),
            remainingTimeLabel.centerYAnchor.constraint(equalTo: startnowLabel.centerYAnchor),
            
            infoButton.centerYAnchor.constraint(equalTo: episodeLabel.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: episodeLabel.trailingAnchor, constant: 4),
            infoButton.widthAnchor.constraint(equalToConstant: 22),
            infoButton.heightAnchor.constraint(equalToConstant: 22),
            
            contentView.bottomAnchor.constraint(equalTo: startnowLabel.bottomAnchor, constant: 10)
        ])
    }
    
    func updatePlaybackProgress(progress: Float, remainingTime: TimeInterval) {
        currentProgress = progress
        currentRemainingTime = remainingTime
        
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
        currentProgress = 0
        currentRemainingTime = 0
        playbackProgressView.isHidden = true
        startnowLabel.isHidden = false
        remainingTimeLabel.isHidden = true
        playbackProgressView.progress = 0.0
        remainingTimeLabel.text = ""
    }
    
    private func formatRemainingTime(_ time: TimeInterval) -> String {
        if time < 120 {
            return "Finished"
        } else {
            let hours = Int(time) / 3600
            let minutes = (Int(time) % 3600) / 60
            let seconds = Int(time) % 60
            
            var components = [String]()
            
            if hours > 0 {
                components.append(String(format: "%d:%02d:%02d", hours, minutes, seconds))
            } else if minutes > 0 {
                components.append(String(format: "%d:%02d", minutes, seconds))
            } else {
                components.append(String(format: "0:%02d", seconds))
            }
            
            components.append("left")
            return components.joined(separator: " ")
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
        infoButton.accessibilityLabel = "Info for Episode \(episodeNumber)"
        infoButton.accessibilityHint = "Tap to view more information about this episode"
    }
    
    private func updateEpisodeLabel() {
        episodeLabel.text = "Episode \(episodeNumber)"
    }
    
    private func updateDownloadButtonVisibility() {
        if selectedMediaSource == "JKanime" || selectedMediaSource == "HiAnime" || selectedMediaSource == "Anilibria" || selectedMediaSource == "AnimeSRBIJA" {
            downloadButton.isHidden = true
        } else {
            downloadButton.isHidden = false
        }
    }
    
    @objc private func downloadButtonTapped() {
        if let episode = episode, let delegate = delegate {
            delegate.downloadMedia(for: episode)
        }
    }
    
    @objc private func infoButtonTapped() {
        guard let delegate = delegate, let animeTitle = delegate.animeTitle else { return }
        
        let cleanedTitle = delegate.cleanTitle(animeTitle)
        
        delegate.fetchAnimeID(title: cleanedTitle) { anilistID in
            self.fetchEpisodeInfo(anilistID: anilistID, episodeNumber: self.episodeNumber)
        }
    }
    
    private func fetchEpisodeInfo(anilistID: Int, episodeNumber: String) {
        guard let url = URL(string: "https://api.ani.zip/mappings?anilist_id=\(anilistID)") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching episode info: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Failed to fetch episode information")
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let episodes = json["episodes"] as? [String: [String: Any]],
                   let episodeInfo = episodes[episodeNumber] {
                    DispatchQueue.main.async {
                        self.showEpisodeInfoView(episodeInfo)
                    }
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Failed to parse episode information")
                }
            }
        }.resume()
    }
    
    private func showEpisodeInfoView(_ info: [String: Any]) {
        let episodeInfoVC = EpisodeInfoAlertController()
        
        let imageUrl = info["image"] as? String ?? ""
        
        episodeInfoVC.configure(with: info, imageUrl: imageUrl)
        episodeInfoVC.modalPresentationStyle = .overFullScreen
        episodeInfoVC.modalTransitionStyle = .crossDissolve
        
        if let viewController = self.delegate {
            viewController.present(episodeInfoVC, animated: true, completion: nil)
        }
    }
    
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let viewController = self.delegate {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func setupGestureRecognizers() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        becomeFirstResponder()
        
        var menuItems: [UIMenuItem] = []
        
        if let episode = episode, let fullURL = episode.href as String? {
            let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullURL)")
            let totalTime = UserDefaults.standard.double(forKey: "totalTime_\(fullURL)")
            let remainingTime = totalTime - lastPlayedTime
            
            if lastPlayedTime > 0 || totalTime > 0 {
                if remainingTime < 120 {
                    menuItems.append(UIMenuItem(title: "Clear Progress", action: #selector(clearProgress)))
                    menuItems.append(UIMenuItem(title: "Rewatch", action: #selector(rewatch)))
                } else {
                    menuItems.append(UIMenuItem(title: "Mark as Finished", action: #selector(markAsFinished)))
                    
                    if playbackProgressView.progress > 0 {
                        menuItems.append(UIMenuItem(title: "Clear Progress", action: #selector(clearProgress)))
                        menuItems.append(UIMenuItem(title: "Rewatch", action: #selector(rewatch)))
                    }
                }
            } else {
                menuItems.append(UIMenuItem(title: "Mark as Finished", action: #selector(markAsFinished)))
            }
        }
        
        UIMenuController.shared.menuItems = menuItems
        UIMenuController.shared.showMenu(from: self, rect: self.bounds)
    }
    
    @objc private func rewatch() {
        guard let episode = episode, let delegate = delegate else { return }
        clearProgress()
        delegate.episodeSelected(episode: episode, cell: self)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc private func markAsFinished() {
        guard let episode = episode else { return }
        let fullURL = episode.href
        
        let totalTime = "9999999999.9"
        
        UserDefaults.standard.set(totalTime, forKey: "lastPlayedTime_\(fullURL)")
        UserDefaults.standard.set(totalTime, forKey: "totalTime_\(fullURL)")
        
        updatePlaybackProgress(progress: 1.0, remainingTime: 0)
    }
    
    @objc private func clearProgress() {
        guard let episode = episode else { return }
        let fullURL = episode.href
        
        UserDefaults.standard.removeObject(forKey: "lastPlayedTime_\(fullURL)")
        UserDefaults.standard.removeObject(forKey: "totalTime_\(fullURL)")
        
        resetPlaybackProgress()
    }
}

class EpisodeInfoAlertController: UIViewController {
    let containerView = UIView()
    let titleLabel = UILabel()
    let airDateLabel = UILabel()
    let runtimeLabel = UILabel()
    let overviewLabel = UILabel()
    let episodeImageView = UIImageView()
    let okButton = UIButton(type: .system)
    let topSeparatorLine = UIView()
    let bottomSeparatorLine = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        containerView.backgroundColor = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 14
        containerView.clipsToBounds = true
        
        episodeImageView.contentMode = .scaleAspectFit
        episodeImageView.clipsToBounds = true
        episodeImageView.layer.cornerRadius = 8
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        airDateLabel.font = UIFont.systemFont(ofSize: 14)
        airDateLabel.textColor = .secondaryLabel
        airDateLabel.textAlignment = .left
        
        runtimeLabel.font = UIFont.systemFont(ofSize: 14)
        runtimeLabel.textColor = .secondaryLabel
        runtimeLabel.textAlignment = .right
        
        overviewLabel.font = UIFont.systemFont(ofSize: 13)
        overviewLabel.numberOfLines = 4
        overviewLabel.textColor = .secondaryLabel
        
        topSeparatorLine.backgroundColor = UIColor.systemGray.withAlphaComponent(0.4)
        bottomSeparatorLine.backgroundColor = UIColor.systemGray.withAlphaComponent(0.4)
        
        okButton.setTitle("OK", for: .normal)
        okButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        okButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        
        view.addSubview(containerView)
        containerView.addSubview(episodeImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(airDateLabel)
        containerView.addSubview(runtimeLabel)
        containerView.addSubview(overviewLabel)
        containerView.addSubview(bottomSeparatorLine)
        containerView.addSubview(topSeparatorLine)
        containerView.addSubview(okButton)
        
        setConstraints()
    }
    
    private func setConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        episodeImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        airDateLabel.translatesAutoresizingMaskIntoConstraints = false
        runtimeLabel.translatesAutoresizingMaskIntoConstraints = false
        overviewLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        topSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        okButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            
            episodeImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            episodeImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            episodeImageView.widthAnchor.constraint(equalToConstant: 245),
            episodeImageView.heightAnchor.constraint(equalToConstant: 140),
            
            titleLabel.topAnchor.constraint(equalTo: episodeImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            airDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            airDateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            airDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            runtimeLabel.centerYAnchor.constraint(equalTo: airDateLabel.centerYAnchor),
            runtimeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            runtimeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            topSeparatorLine.topAnchor.constraint(equalTo: runtimeLabel.bottomAnchor, constant: 8),
            topSeparatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topSeparatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            overviewLabel.topAnchor.constraint(equalTo: topSeparatorLine.bottomAnchor, constant: 8),
            overviewLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            overviewLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            bottomSeparatorLine.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 8),
            bottomSeparatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomSeparatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            okButton.topAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor, constant: 4),
            okButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
            okButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            okButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            okButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
    
    @objc private func dismissAlert() {
        dismiss(animated: true, completion: nil)
    }
    
    func configure(with info: [String: Any], imageUrl: String) {
        guard let title = (info["title"] as? [String: String])?["en"],
              let airDate = info["airDate"] as? String,
              let runtime = info["runtime"] as? Int,
              let overview = info["overview"] as? String,
              !imageUrl.isEmpty else {
            showErrorMessage()
            return
        }
        
        titleLabel.text = title
        airDateLabel.text = "Air Date: \(airDate)"
        runtimeLabel.text = "Runtime: \(runtime)m"
        overviewLabel.text = overview
        
        if let url = URL(string: imageUrl) {
            episodeImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { [weak self] result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        self?.episodeImageView.image = UIImage(systemName: "exclamationmark.triangle")
                    }
                }
            )
        } else {
            episodeImageView.image = UIImage(systemName: "exclamationmark.triangle")
        }
    }
    
    private func showErrorMessage() {
        titleLabel.text = "Error"
        airDateLabel.text = ""
        runtimeLabel.text = ""
        overviewLabel.text = "Not enough information available for this episode. This may be cause of the Anime Titlte"
        episodeImageView.image = UIImage(systemName: "exclamationmark.triangle")
    }
}
