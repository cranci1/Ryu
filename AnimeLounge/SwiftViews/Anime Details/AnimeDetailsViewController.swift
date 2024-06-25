//
//  AnimeDetailsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher
import Alamofire
import SwiftSoup
import AVKit

struct Episode {
    let number: String
    let href: String
}

class AnimeDetailViewController: UITableViewController {
    private var animeTitle: String?
    private var imageUrl: String?
    private var href: String?
    
    private var episodes: [Episode] = []
    private var synopsis: String = ""
    private var aliases: String = ""
    private var isSynopsisExpanded = false

    func configure(title: String, imageUrl: String, href: String) {
        self.animeTitle = title
        self.imageUrl = imageUrl
        self.href = href
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        tableView.backgroundColor = .secondarySystemBackground
        tableView.register(AnimeHeaderCell.self, forCellReuseIdentifier: "AnimeHeaderCell")
        tableView.register(SynopsisCell.self, forCellReuseIdentifier: "SynopsisCell")
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: "EpisodeCell")
    }

    private func updateUI() {
        if let href = href {
            fetchAnimeDetails(from: href)
        }
    }

    private func fetchAnimeDetails(from href: String) {
        guard let selectedSource = UserDefaults.standard.selectedMediaSource else {
            showAlert(title: "Error", message: "No media source selected.")
            return
        }
        
        let baseUrl: String
        switch selectedSource {
        case .animeWorld:
            baseUrl = "https://animeworld.so"
        case .gogoanime:
            baseUrl = "https://anitaku.pe"
        case .tioanime:
            baseUrl = "https://tioanime.com"
        case .animeheaven:
            baseUrl = "https://animeheaven.me/"
        }
        
        let fullUrl = baseUrl + href
        AF.request(fullUrl).responseString { [weak self] response in
            guard let self = self else { return }
            switch response.result {
            case .success(let html):
                self.parseAnimeDetails(html: html, for: selectedSource)
            case .failure(let error):
                print("Failed to fetch anime details: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to fetch anime details. Please try again later.")
            }
        }
    }
    
    private func parseAnimeDetails(html: String, for source: MediaSource) {
        do {
            let document = try SwiftSoup.parse(html)
            
            switch source {
            case .animeWorld:
                aliases = ""
                synopsis = try document.select("div.info div.desc").text()
            case .gogoanime:
                aliases = try document.select("div.anime_info_body_bg p.other-name a").text()
                synopsis = try document.select("div.anime_info_body_bg div.description").text()
            case .tioanime:
                aliases = try document.select("p.original-title").text()
                synopsis = try document.select("p.sinopsis").text()
            case .animeheaven:
                aliases = try document.select("div.infodiv div.infotitlejp").text()
                synopsis = try document.select("div.infodiv div.infodes").text()
            }
            
            fetchEpisodes(document: document, for: source)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error parsing anime details HTML: \(error.localizedDescription)")
        }
    }
    
    private func fetchEpisodes(document: Document, for source: MediaSource) {
        do {
            var episodeElements: Elements
            
            switch source {
            case .animeWorld:
                episodeElements = try document.select("div.server.active ul.episodes li.episode a")
            case .gogoanime:
                episodeElements = try document.select("a.active")
            case .tioanime:
                episodeElements = try document.select("ul.episodes-list li a")
            case .animeheaven:
                episodeElements = try document.select("div.linetitle2 a")
            }
            
            switch source {
            case .gogoanime:
                episodes = episodeElements.flatMap { element -> [Episode] in
                    guard let episodeText = try? element.text() else { return [] }
                    
                    let parts = episodeText.split(separator: "-")
                    guard parts.count == 2,
                          let start = Int(parts[0]),
                          let end = Int(parts[1]) else {
                        return []
                    }
                    
                    return (max(1, start)...end).map { episodeNumber in
                        let formattedEpisode = "Episode \(episodeNumber)"
                        let baseHref = self.href ?? ""
                        let episodeHref = "\(baseHref)-episode-\(episodeNumber)"
                        
                        return Episode(number: formattedEpisode, href: episodeHref)
                    }
                }
            case .tioanime:
                episodes = episodeElements.compactMap { element in
                    guard let href = try? element.attr("href") else { return nil }
                    
                    let episodeNumber = (try? element.select("p span").text()) ?? "Unknown"
                    
                    return Episode(number: episodeNumber, href: href)
                }
            default:
                episodes = episodeElements.compactMap { element in
                    guard let episodeText = try? element.text(),
                          let href = try? element.attr("href") else { return nil }
                    return Episode(number: episodeText, href: href)
                }
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error parsing episodes: \(error.localizedDescription)")
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
        let baseURL = "https://www.animeworld.so/api/episode/serverPlayerAnimeWorld?id="
        let episodeId = episode.href.components(separatedBy: "/").last ?? episode.href
        let fullURL = baseURL + episodeId
        playEpisode(url: fullURL)
    }

    private func playEpisode(url: String) {
        guard let videoURL = URL(string: url) else {
            print("Invalid URL")
            return
        }
        
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

    private func extractVideoSourceURL(from htmlString: String) -> URL? {
        let pattern = #"<source src="(.*?)" type="video/mp4">"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let urlRange = Range(match.range(at: 1), in: htmlString) else {
            return nil
        }
        
        let urlString = String(htmlString[urlRange])
        return URL(string: urlString)
    }

    private func playVideoWithAVPlayer(sourceURL: URL) {
        let player = AVPlayer(url: sourceURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
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
