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

class AnimeDetailViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let aliasLabel = UILabel()
    private let favoriteButton = UIButton()
    private let infoButton = UIButton()
    private let ratingLabel = UILabel()
    private let airDateLabel = UILabel()
    private let synopsisLabel = UILabel()
    private let synopsisDescriptionLabel = UILabel()
    private let toggleSynopsisButton = UIButton()
    private let tableView = UITableView()

    private var animeTitle: String?
    private var imageUrl: String?
    private var href: String?
    
    private var episodes: [Episode] = []
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        setupScrollView()
        setupImageView()
        setupTitleSection()
        setupRatingSection()
        setupSynopsisSection()
        setupTableView()
    }

    private func updateUI() {
        titleLabel.text = animeTitle
        aliasLabel.text = ""

        if let url = URL(string: imageUrl ?? "") {
            imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        }

        if let href = href {
            fetchAnimeDetails(from: href)
        }
    }

    private func fetchAnimeDetails(from href: String) {
        let fullUrl = "https://animeworld.so" + href
        AF.request(fullUrl).responseString { [weak self] response in
            guard let self = self else { return }
            switch response.result {
            case .success(let html):
                self.parseAnimeDetails(html: html)
            case .failure(let error):
                print("Failed to fetch anime details: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to fetch anime details. Please try again later.")
            }
        }
    }

    private func parseAnimeDetails(html: String) {
        do {
            let document = try SwiftSoup.parse(html)
            let aliases = try document.select("selector-for-alias").text()
            let airDate = try document.select("dt:contains(Data di Uscita) + dd").text()
            let rating = try document.select("dd.rating span#average-vote").text()
            let synopsis = try document.select("div.info div.desc").text()
            
            fetchEpisodes(document: document)
            
            DispatchQueue.main.async {
                self.aliasLabel.text = aliases
                self.airDateLabel.text = "Air Date: \(airDate)"
                self.ratingLabel.text = "Rating: \(rating)"
                self.synopsisDescriptionLabel.text = synopsis
            }
        } catch {
            print("Error parsing anime details HTML: \(error.localizedDescription)")
        }
    }
    
    private func fetchEpisodes(document: Document) {
        do {
            let episodeElements = try document.select("div.server.active ul.episodes li.episode a")
            episodes = episodeElements.compactMap { element in
                guard let episodeNumber = try? element.text(),
                      let href = try? element.attr("href") else { return nil }
                return Episode(number: episodeNumber, href: href)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateContentSize()
            }
        } catch {
            print("Error parsing episodes: \(error.localizedDescription)")
        }
    }

    private func updateContentSize() {
        let totalHeight = tableView.frame.maxY + 20
        contentView.frame.size = CGSize(width: view.frame.width, height: totalHeight)
        scrollView.contentSize = contentView.frame.size
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupImageView() {
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .gray
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
    }
    
    private func setupTitleSection() {
        [titleLabel, aliasLabel, favoriteButton, infoButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        aliasLabel.font = UIFont.systemFont(ofSize: 14)
        aliasLabel.textColor = .secondaryLabel
        aliasLabel.numberOfLines = 0

        favoriteButton.setTitle("FAVORITE", for: .normal)
        favoriteButton.setTitleColor(.black, for: .normal)
        favoriteButton.backgroundColor = UIColor.systemTeal
        favoriteButton.layer.cornerRadius = 16

        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = UIColor.systemTeal

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            aliasLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            aliasLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            aliasLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            favoriteButton.topAnchor.constraint(equalTo: aliasLabel.bottomAnchor, constant: 16),
            favoriteButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 100),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30),

            infoButton.centerYAnchor.constraint(equalTo: favoriteButton.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor, constant: 8),
            infoButton.widthAnchor.constraint(equalToConstant: 30),
            infoButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupRatingSection() {
        contentView.addSubview(ratingLabel)
        contentView.addSubview(airDateLabel)
        
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        airDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.textColor = .secondaryLabel
        
        airDateLabel.font = UIFont.systemFont(ofSize: 14)
        airDateLabel.textColor = .secondaryLabel
        
        NSLayoutConstraint.activate([
            ratingLabel.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor, constant: 16),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            airDateLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 4),
            airDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        ])
    }
    
    private func setupSynopsisSection() {
        contentView.addSubview(synopsisLabel)
        contentView.addSubview(synopsisDescriptionLabel)
        contentView.addSubview(toggleSynopsisButton)
        
        synopsisLabel.translatesAutoresizingMaskIntoConstraints = false
        synopsisDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSynopsisButton.translatesAutoresizingMaskIntoConstraints = false
        
        synopsisLabel.font = UIFont.boldSystemFont(ofSize: 16)
        synopsisLabel.textColor = .label
        synopsisLabel.text = "Synopsis"
        
        synopsisDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        synopsisDescriptionLabel.textColor = .secondaryLabel
        synopsisDescriptionLabel.numberOfLines = 4
        
        toggleSynopsisButton.setTitle("More", for: .normal)
        toggleSynopsisButton.setTitleColor(.systemTeal, for: .normal)
        toggleSynopsisButton.addTarget(self, action: #selector(toggleSynopsis), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            synopsisLabel.topAnchor.constraint(equalTo: airDateLabel.bottomAnchor, constant: 16),
            synopsisLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            synopsisDescriptionLabel.topAnchor.constraint(equalTo: synopsisLabel.bottomAnchor, constant: 8),
            synopsisDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            synopsisDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            toggleSynopsisButton.centerYAnchor.constraint(equalTo: synopsisLabel.centerYAnchor),
            toggleSynopsisButton.leadingAnchor.constraint(equalTo: synopsisLabel.trailingAnchor, constant: 5),
        ])
    }
    
    @objc func toggleSynopsis() {
        if synopsisDescriptionLabel.numberOfLines == 0 {
            synopsisDescriptionLabel.numberOfLines = 4
            toggleSynopsisButton.setTitle("More", for: .normal)
        } else {
            synopsisDescriptionLabel.numberOfLines = 0
            toggleSynopsisButton.setTitle("Less", for: .normal)
        }
        contentView.layoutIfNeeded()
    }

    
    private func setupTableView() {
        contentView.addSubview(tableView)
        tableView.backgroundColor = UIColor.secondarySystemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: "EpisodeCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: synopsisDescriptionLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        tableView.rowHeight = 44
    }
}
extension AnimeDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.row]
        cell.episodeLabel.text = "Episode \(episode.number)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = episodes[indexPath.row]
        episodeSelected(episode: episode)
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

class EpisodeCell: UITableViewCell {
    let episodeLabel = UILabel()
    let downloadButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(episodeLabel)
        contentView.addSubview(downloadButton)
        
        episodeLabel.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        
        episodeLabel.font = UIFont.systemFont(ofSize: 16)
        downloadButton.setImage(UIImage(systemName: "icloud.and.arrow.down"), for: .normal)
        downloadButton.tintColor = .systemTeal
        
        NSLayoutConstraint.activate([
            episodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 30),
            downloadButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
