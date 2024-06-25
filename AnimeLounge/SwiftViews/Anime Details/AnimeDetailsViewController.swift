//
//  AnimeDetailsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import AVKit
import SwiftSoup

extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}

class AnimeDetailViewController: UITableViewController {
    private var animeTitle: String?
    private var imageUrl: String?
    private var href: String?
    
    private var episodes: [Episode] = []
    private var synopsis: String = ""
    private var aliases: String = ""
    private var isSynopsisExpanded = false
    
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

    func configure(title: String, imageUrl: String, href: String) {
        self.animeTitle = title
        self.imageUrl = imageUrl
        self.href = href
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
        setupNotifications()
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        tableView.backgroundColor = .secondarySystemBackground
        tableView.register(AnimeHeaderCell.self, forCellReuseIdentifier: "AnimeHeaderCell")
        tableView.register(SynopsisCell.self, forCellReuseIdentifier: "SynopsisCell")
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: "EpisodeCell")
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            player?.pause()
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                player?.play()
            } catch {
                print("Failed to reactivate AVAudioSession: \(error)")
            }
        default:
            break
        }
    }

    private func updateUI() {
        if let href = href {
            AnimeDetailService.fetchAnimeDetails(from: href) { [weak self] (result) in
                switch result {
                case .success(let details):
                    self?.aliases = details.aliases
                    self?.synopsis = details.synopsis
                    self?.episodes = details.episodes
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1: return 1
        case 2: return episodes.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnimeHeaderCell", for: indexPath) as! AnimeHeaderCell
            cell.configure(title: animeTitle, imageUrl: imageUrl, aliases: aliases)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SynopsisCell", for: indexPath) as! SynopsisCell
            cell.configure(synopsis: synopsis, isExpanded: isSynopsisExpanded)
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell
            let episode = episodes[indexPath.row]
            cell.configure(episodeNumber: episode.number)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            let episode = episodes[indexPath.row]
            episodeSelected(episode: episode)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Synopsis"
        case 2: return "Episodes"
        default: return nil
        }
    }

    private func episodeSelected(episode: Episode) {
        let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "animeheaven"
        
        var baseURL: String
        var fullURL: String
        var episodeId: String
        
        switch selectedSource {
        case "AnimeWorld":
            baseURL = "https://www.animeworld.so/api/episode/serverPlayerAnimeWorld?id="
            episodeId = episode.href.components(separatedBy: "/").last ?? episode.href
            fullURL = baseURL + episodeId
        case "AnimeHeaven":
            baseURL = "https://animeheaven.me/"
            episodeId = episode.href
            fullURL = baseURL + episodeId
        default:
            baseURL = ""
            episodeId = episode.href
            fullURL = baseURL + episodeId
        }
        
        print("Selected source: \(selectedSource)")
        print("Full URL: \(fullURL)")
        playEpisode(url: fullURL)
    }
    
    private func fetchHTMLContent(from url: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "Invalid data", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(htmlString))
        }.resume()
    }

    private func playEpisode(url: String) {
        guard let videoURL = URL(string: url) else {
            print("Invalid URL")
            return
        }

        if url.contains(".mp4") || url.contains(".m3u8") || url.contains("animeheaven.me/video.mp4") {
            DispatchQueue.main.async {
                self.playVideoWithAVPlayer(sourceURL: videoURL)
            }
        } else {
            URLSession.shared.dataTask(with: videoURL) { [weak self] (data, response, error) in
                guard let self = self,
                      let data = data,
                      let htmlString = String(data: data, encoding: .utf8),
                      let srcURL = self.extractVideoSourceURL(from: htmlString) else {
                    print("Error fetching or parsing video data")
                    return
                }
                
                DispatchQueue.main.async {
                    self.playVideoWithAVPlayer(sourceURL: srcURL)
                }
            }.resume()
        }
    }

    private func extractVideoSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let videoElement = try doc.select("video").first(),
                  let sourceElement = try videoElement.select("source").first(),
                  let sourceURLString = try sourceElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                return nil
            }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            
            // Fallback to regex method if SwiftSoup fails
            let mp4Pattern = #"<source src="(.*?)" type="video/mp4">"#
            let m3u8Pattern = #"<source src="(.*?)" type="application/x-mpegURL">"#
            
            if let mp4URL = extractURL(from: htmlString, pattern: mp4Pattern) {
                return mp4URL
            } else if let m3u8URL = extractURL(from: htmlString, pattern: m3u8Pattern) {
                return m3u8URL
            }
            return nil
        }
    }
    
    private func extractURL(from htmlString: String, pattern: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let urlRange = Range(match.range(at: 1), in: htmlString) else {
            return nil
        }
        
        let urlString = String(htmlString[urlRange])
        return URL(string: urlString)
    }

    private func playVideoWithAVPlayer(sourceURL: URL) {
        player = AVPlayer(url: sourceURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        present(playerViewController!, animated: true) {
            self.player?.play()
        }
    }
}

extension AnimeDetailViewController: SynopsisCellDelegate {
    func synopsisCellDidToggleExpansion(_ cell: SynopsisCell) {
        isSynopsisExpanded.toggle()
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }
}

class AnimeHeaderCell: UITableViewCell {
    private let animeImageView = UIImageView()
    private let titleLabel = UILabel()
    private let aliasLabel = UILabel()
    private let favoriteButton = UIButton()
    private let infoButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        
        contentView.addSubview(animeImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(aliasLabel)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(infoButton)
        
        animeImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        aliasLabel.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        
        animeImageView.contentMode = .scaleAspectFit
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        aliasLabel.font = UIFont.systemFont(ofSize: 14)
        aliasLabel.textColor = .secondaryLabel
        aliasLabel.numberOfLines = 0

        favoriteButton.setTitle("FAVORITE", for: .normal)
        favoriteButton.setTitleColor(.black, for: .normal)
        favoriteButton.backgroundColor = UIColor.systemTeal
        favoriteButton.layer.cornerRadius = 14

        infoButton.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
        infoButton.tintColor = UIColor.systemTeal
        
        NSLayoutConstraint.activate([
            animeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            animeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            animeImageView.widthAnchor.constraint(equalToConstant: 120),
            animeImageView.heightAnchor.constraint(equalToConstant: 180),
            
            titleLabel.topAnchor.constraint(equalTo: animeImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: animeImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            aliasLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            aliasLabel.leadingAnchor.constraint(equalTo: animeImageView.trailingAnchor, constant: 12),
            aliasLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            favoriteButton.topAnchor.constraint(equalTo: aliasLabel.bottomAnchor, constant: 8),
            favoriteButton.leadingAnchor.constraint(equalTo: animeImageView.trailingAnchor, constant: 12),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),
            favoriteButton.widthAnchor.constraint(equalToConstant: 100),
            
            infoButton.centerYAnchor.constraint(equalTo: favoriteButton.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor, constant: 10),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),
            
            contentView.bottomAnchor.constraint(equalTo: animeImageView.bottomAnchor, constant: 10)
        ])
    }
    
    func configure(title: String?, imageUrl: String?, aliases: String) {
        titleLabel.text = title
        aliasLabel.text = aliases
        if let url = URL(string: imageUrl ?? "") {
            animeImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        }
    }
}

protocol SynopsisCellDelegate: AnyObject {
    func synopsisCellDidToggleExpansion(_ cell: SynopsisCell)
}

class SynopsisCell: UITableViewCell {
    private let synopsisLabel = UILabel()
    private let toggleButton = UIButton()
    
    weak var delegate: SynopsisCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(synopsisLabel)
        contentView.addSubview(toggleButton)
        
        synopsisLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        
        synopsisLabel.numberOfLines = 4
        synopsisLabel.font = UIFont.systemFont(ofSize: 14)
        
        toggleButton.setTitleColor(.systemTeal, for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            synopsisLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            synopsisLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            synopsisLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            toggleButton.topAnchor.constraint(equalTo: synopsisLabel.bottomAnchor, constant: 5),
            toggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            toggleButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(synopsis: String, isExpanded: Bool) {
        synopsisLabel.text = synopsis
        synopsisLabel.numberOfLines = isExpanded ? 0 : 4
        toggleButton.setTitle(isExpanded ? "Less" : "More", for: .normal)
    }
    
    @objc private func toggleButtonTapped() {
        delegate?.synopsisCellDidToggleExpansion(self)
    }
}

class EpisodeCell: UITableViewCell {
    let episodeLabel = UILabel()
    let downloadButton = UIButton(type: .system)
    let startnowLabel = UILabel()
    
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
        
        episodeLabel.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        startnowLabel.translatesAutoresizingMaskIntoConstraints = false
        
        episodeLabel.font = UIFont.systemFont(ofSize: 16)
        
        startnowLabel.font = UIFont.systemFont(ofSize: 13)
        startnowLabel.text = "Start Now"
        startnowLabel.textColor = .secondaryLabel
        
        downloadButton.setImage(UIImage(systemName: "icloud.and.arrow.down"), for: .normal)
        downloadButton.tintColor = .systemTeal
        
        NSLayoutConstraint.activate([
            episodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            startnowLabel.leadingAnchor.constraint(equalTo: episodeLabel.leadingAnchor),
            startnowLabel.topAnchor.constraint(equalTo: episodeLabel.bottomAnchor, constant: 5),
            
            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 30),
            downloadButton.heightAnchor.constraint(equalToConstant: 30),
            
            contentView.bottomAnchor.constraint(equalTo: startnowLabel.bottomAnchor, constant: 10)
        ])
    }
    
    func configure(episodeNumber: String) {
        episodeLabel.text = "Episode \(episodeNumber)"
    }
}
