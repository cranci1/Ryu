//
//  FeaturedViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit
import SwiftSoup
import Kingfisher

class AnimeItem: NSObject {
    let title: String
    let episode: String
    let imageURL: String
    let href: String
    
    init(title: String, episode: String, imageURL: String, href: String) {
        self.title = title
        self.episode = episode
        self.imageURL = imageURL
        self.href = href
    }
}

class FeaturedViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var animeList: [AnimeItem] = []
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupRefreshControl()
        fetchRecentAnime()
        
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AnimeTableViewCell.self, forCellReuseIdentifier: "AnimeCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .secondarySystemBackground
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        fetchRecentAnime()
    }
    
    private func fetchRecentAnime() {
        let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
        let (sourceURL, parseStrategy) = getSourceInfo(for: selectedSource)
        
        guard let url = URL(string: sourceURL) else {
            self.refreshControl.endRefreshing()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing()
                }
                return
            }
            
            do {
                let html = String(data: data, encoding: .utf8) ?? ""
                let doc: Document = try SwiftSoup.parse(html)
                
                let animeItems = try parseStrategy(doc)
                
                DispatchQueue.main.async {
                    self?.animeList = animeItems
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
            } catch {
                print("Error parsing HTML: \(error)")
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing()
                }
            }
        }.resume()
    }
    
    private func getSourceInfo(for source: String) -> (String, (Document) throws -> [AnimeItem]) {
        switch source {
        case "AnimeWorld":
            return ("https://www.animeworld.so", parseAnimeWorldFeatured)
        case "GoGoAnime":
            return ("https://anitaku.pe/home.html", parseGoGoFeatured)
        case "AnimeHeaven":
            return ("https://animeheaven.me/new.php", parseAnimeHeavenFeatured)
        case "AnimeFire":
            return ("https://animefire.plus/", parseAnimeFireFeatured)
        case "Kuramanime":
            return ("https://kuramanime.boo/quick/ongoing?order_by=updated", parseKuramanimeFeatured)
        case "JKanime":
            return ("https://jkanime.net/", parseJKAnimeFeatured)
        default:
            return ("https://www.animeworld.so", parseAnimeWorldFeatured)
        }
    }
    
    private func parseAnimeWorldFeatured(_ doc: Document) throws -> [AnimeItem] {
        let contentDiv = try doc.select("div.content[data-name=all]").first()
          guard let animeItems = try contentDiv?.select("div.item") else {
              throw NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find anime items"])
          }
          
          return try animeItems.array().compactMap { item in
              let titleElement = try item.select("a.name").first()
              let title = try titleElement?.text() ?? ""
              
              let imageElement = try item.select("img").first()
              let imageURL = try imageElement?.attr("src") ?? ""
              
              let episodeElement = try item.select("div.ep").first()
              let episodeText = try episodeElement?.text() ?? ""
              let episode = episodeText.replacingOccurrences(of: "Ep ", with: "")
              
              let hrefElement = try item.select("a.poster").first()
              let href = try hrefElement?.attr("href") ?? ""
              
              return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
          }
      }
    
    private func parseGoGoFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.last_episodes li")
        return try animeItems.array().compactMap { item in
            let title = try item.select("p.name a").text()
            
            let episodeText = try item.select("p.episode").text()
            let episode = episodeText.replacingOccurrences(of: "Episode ", with: "")
            
            let imageURL = try item.select("div.img img").attr("src")
            var href = try item.select("div.img a").attr("href")
            
            if let range = href.range(of: "-episode-\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            href = "/category" + href
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    private func parseAnimeHeavenFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.boldtext div.chart.bc1")
        return try animeItems.array().compactMap { item in
            let title = try item.select("div.chartinfo a.c").text()
            let episode = try item.select("div.chartep").text()
            
            let imageURL = try item.select("div.chartimg img").attr("src")
            let image = "https://animeheaven.me/" + imageURL
            
            let href = try item.select("div.chartimg a").attr("href")
            
            return AnimeItem(title: title, episode: episode, imageURL: image, href: href)
        }
    }
    
    private func parseAnimeFireFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.container.eps div.card-group div.col-12")
        return try animeItems.array().compactMap { item in
            
            var title = try item.select("h3.animeTitle").text()
            
            if let range = title.range(of: "- Episódio \\d+", options: .regularExpression) {
                title.removeSubrange(range)
            }
            
            let episodeText = try item.select("span.numEp").text()
            let episode = episodeText.replacingOccurrences(of: "Episódio ", with: "")
            
            let imageURL = try item.select("article.card img").attr("src")
            let href = try item.select("article.card a").attr("href")
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    private func parseKuramanimeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.product__page__content div#animeList div.col-lg-4")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("h5 a").text()
            
            let episodeText = try item.select("div.ep span").text()
            let episodeRegex = try NSRegularExpression(pattern: "^Ep (\\d+)", options: [])
            let matches = episodeRegex.matches(in: episodeText, options: [], range: NSRange(location: 0, length: episodeText.utf16.count))
            let episode = matches.first.flatMap {
                String(episodeText[Range($0.range(at: 1), in: episodeText)!])
            } ?? ""
            
            let imageURL = try item.select("div.product__item__pic").attr("data-setbg")
            
            var href = try item.select("a").attr("href")
            if let range = href.range(of: "/episode/\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    private func parseJKAnimeFeatured(_ doc: Document) throws -> [AnimeItem] {
        let animeItems = try doc.select("div.listadoanime-home div.anime_programing a.bloqq")
        return try animeItems.array().compactMap { item in
            
            let title = try item.select("div.anime__sidebar__comment__item__text h5").text()
            let episodeText = try item.select("div.anime__sidebar__comment__item__text h6").text()
            let episode = episodeText.replacingOccurrences(of: "Episodio ", with: "")
            let imageURL = try item.select("img").attr("src")
            
            var href = try item.select("a").attr("href")
            if let range = href.range(of: "/\\d+", options: .regularExpression) {
                href.removeSubrange(range)
            }
            
            return AnimeItem(title: title, episode: episode, imageURL: imageURL, href: href)
        }
    }
    
    private func navigateToAnimeDetail(title: String, imageUrl: String, href: String) {
        let detailVC = AnimeDetailViewController()
        detailVC.configure(title: title, imageUrl: imageUrl, href: href)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension FeaturedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnimeCell", for: indexPath) as! AnimeTableViewCell
        let anime = animeList[indexPath.row]
        cell.configure(with: anime)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAnime = animeList[indexPath.row]
        navigateToAnimeDetail(title: selectedAnime.title, imageUrl: selectedAnime.imageURL, href: selectedAnime.href)
    }
}

class AnimeTableViewCell: UITableViewCell {
    private let animeImageView = UIImageView()
    private let nameLabel = UILabel()
    private let episodeLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 8
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        animeImageView.contentMode = .scaleAspectFit
        animeImageView.clipsToBounds = true
        animeImageView.layer.cornerRadius = 8
        animeImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(animeImageView)
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.numberOfLines = 3
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        episodeLabel.font = UIFont.systemFont(ofSize: 14)
        episodeLabel.textColor = .secondaryLabel
        episodeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(episodeLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            animeImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animeImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            animeImageView.widthAnchor.constraint(equalToConstant: 100),
            animeImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.leadingAnchor.constraint(equalTo: animeImageView.trailingAnchor, constant: 4),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            episodeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            episodeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            episodeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ])
    }
    
    func configure(with anime: AnimeItem) {
        nameLabel.text = anime.title
        episodeLabel.text = "Episode: \(anime.episode)"
        
        if let url = URL(string: anime.imageURL) {
            animeImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            animeImageView.image = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        animeImageView.kf.cancelDownloadTask()
    }
}
