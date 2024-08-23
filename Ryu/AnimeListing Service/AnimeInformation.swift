//
//  AnimeInformation.swift
//  Ryu
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher
import SafariServices

class AnimeInformation: UIViewController, UITableViewDataSource {
    var animeID: Int = 0
    private var animeData: [String: Any]?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let coverImageView = UIImageView()
    private let bannerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionView = DescriptionView()
    private let infoView = AnimeInfoView()
    private let statsView = StatsView()
    private let charactersView = CharactersView()
    private let relationsView = RelationsView()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    private let searchEpisodesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search Episodes", for: .normal)
        button.addTarget(self, action: #selector(searchEpisodesButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemTeal
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        setupUI()
        fetchAnimeData()
        
        let anilistButton = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openAniListPage))
        navigationItem.rightBarButtonItem = anilistButton
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        setupScrollView()
        setupHeaderView()
        setupContentViews()
        setupLoadingIndicator()
    }
    
    @objc private func openAniListPage() {
        guard let url = URL(string: "https://anilist.co/anime/\(animeID)") else {
            showError(message: "Unable to open AniList page.")
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
    
    private func setupHeaderView() {
        contentView.addSubview(bannerImageView)
        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(searchEpisodesButton)
        
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        searchEpisodesButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 220),
            
            coverImageView.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: -60),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.widthAnchor.constraint(equalToConstant: 120),
            coverImageView.heightAnchor.constraint(equalToConstant: 180),
            
            titleLabel.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            searchEpisodesButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            searchEpisodesButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            searchEpisodesButton.widthAnchor.constraint(equalToConstant: 140),
            searchEpisodesButton.heightAnchor.constraint(equalToConstant: 33)
        ])
        
        coverImageView.layer.cornerRadius = 8
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
    }
    
    @objc private func searchEpisodesButtonTapped() {
        guard let query = titleLabel.text, !query.isEmpty else {
            showError(message: "Could not find anime title.")
            return
        }
        searchMedia(query: query)
    }
    
    private func searchMedia(query: String) {
        let resultsVC = SearchResultsViewController()
        resultsVC.query = query
        navigationController?.pushViewController(resultsVC, animated: true)
    }
    
    private func setupContentViews() {
        let stackView = UIStackView(arrangedSubviews: [
            descriptionView, statsView, infoView, charactersView, relationsView
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
    }
    
    private func fetchAnimeData() {
        AnimeService.fetchAnimeDetails(animeID: animeID) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let animeData):
                    self?.animeData = animeData
                    self?.updateUI()
                case .failure(let error):
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func updateUI() {
        guard let animeData = animeData else { return }

        var bannerImageUrl: URL?
        
        if let titleDict = animeData["title"] as? [String: String] {
            titleLabel.text = titleDict["english"] ?? titleDict["romaji"]
        }
        
        if let coverImage = (animeData["coverImage"] as? [String: String])?["extraLarge"],
           let coverImageUrl = URL(string: coverImage) {
            coverImageView.kf.setImage(with: coverImageUrl)
        }
        
        if let bannerImage = animeData["bannerImage"] as? String {
            bannerImageUrl = URL(string: bannerImage)
        }
        if bannerImageUrl == nil, let coverImage = (animeData["coverImage"] as? [String: String])?["extraLarge"] {
            bannerImageUrl = URL(string: coverImage)
        }
        if let bannerUrl = bannerImageUrl {
            bannerImageView.kf.setImage(with: bannerUrl)
        }
        
        descriptionView.configure(with: animeData["description"] as? String)
        infoView.configure(with: animeData)
        statsView.configure(with: animeData["stats"] as? [String: Any])
        
        if let characters = animeData["characters"] as? [String: Any], !characters.isEmpty {
            charactersView.isHidden = false
            charactersView.configure(with: characters)
        } else {
            charactersView.isHidden = true
        }
        
        if let relations = animeData["relations"] as? [String: Any],
           let edges = relations["edges"] as? [Any], !edges.isEmpty {
            relationsView.isHidden = false
            relationsView.configure(with: relations)
        } else {
            relationsView.removeFromSuperview()
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AnimeInformation {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath)
        return cell
    }
}

class AnimeInfoView: UIView {
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with animeData: [String: Any]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        addInfoRow(title: "Type", value: formatValue(for: animeData["type"], mapping: typeMapping))
        addInfoRow(title: "Format", value: formatValue(for: animeData["format"], mapping: formatMapping))
        addInfoRow(title: "Status", value: formatValue(for: animeData["status"], mapping: statusMapping))
        addInfoRow(title: "Season", value: formatValue(for: animeData["season"], mapping: seasonMapping))
        addInfoRow(title: "Episodes", value: animeData["episodes"] as? Int)
        addInfoRow(title: "Duration", value: formatDuration(animeData["duration"] as? Int))
        addInfoRow(title: "Source", value: formatValue(for: animeData["source"], mapping: sourceMapping))
        addInfoRow(title: "Start Date", value: formatDate(animeData["startDate"] as? [String: Int]))
        addInfoRow(title: "End Date", value: formatDate(animeData["endDate"] as? [String: Int]))
    }
    
    private func addInfoRow(title: String, value: Any?) {
        let rowView = UIView()
        let titleLabel = UILabel()
        let valueLabel = UILabel()
        
        rowView.addSubview(titleLabel)
        rowView.addSubview(valueLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            rowView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        
        titleLabel.text = title
        valueLabel.text = "\(value ?? "N/A")"
        
        stackView.addArrangedSubview(rowView)
    }
    
    private func formatDate(_ dateDict: [String: Int]?) -> String {
        guard let year = dateDict?["year"],
              let month = dateDict?["month"],
              let day = dateDict?["day"] else {
            return "N/A"
        }
        return "\(String(format: "%02d", day))/\(String(format: "%02d", month))/\(year)"
    }
    
    private func formatDuration(_ duration: Int?) -> String {
        guard let duration = duration else { return "N/A" }
        return "\(duration) Mins"
    }
    
    private func formatValue(for key: Any?, mapping: [String: String]) -> String {
        guard let key = key as? String else { return "N/A" }
        return mapping[key] ?? "N/A"
    }
    
    private let typeMapping = [
        "ANIME": "Anime",
        "MANGA": "Manga",
        "LIGHT_NOVEL": "Light Novel"
    ]
    
    private let formatMapping = [
        "TV": "TV Series",
        "TV_SHORT": "TV Short",
        "MOVIE": "Movie",
        "OVA": "OVA",
        "ONA": "ONA",
        "SPECIAL": "Special",
        "MUSIC": "Music"
    ]
    
    private let statusMapping = [
        "FINISHED": "Finished",
        "RELEASING": "Releasing",
        "NOT_YET_RELEASED": "Not yet released",
        "CANCELLED": "Cancelled"
    ]
    
    private let seasonMapping = [
        "WINTER": "Winter",
        "SPRING": "Spring",
        "SUMMER": "Summer",
        "FALL": "Fall"
    ]
    
    private let sourceMapping = [
        "ORIGINAL": "Original",
        "MANGA": "Manga",
        "LIGHT_NOVEL": "Light Novel",
        "VISUAL_NOVEL": "Visual Novel",
        "VIDEO_GAME": "Video Game",
        "OTHER": "Other"
    ]
}

class DescriptionView: UIView {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = "Description"
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
    }
    
    func configure(with description: String?) {
        var cleanedDescription = description ?? "No description available."
        cleanedDescription = cleanedDescription.replacingOccurrences(of: "<br>", with: "")
        cleanedDescription = cleanedDescription.replacingOccurrences(of: "<i>", with: "")
        cleanedDescription = cleanedDescription.replacingOccurrences(of: "</i>", with: "")
        descriptionLabel.text = cleanedDescription
    }
}

class RelationsView: UIView {
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private var relations: [[String: Any]] = []
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 90, height: 150)
        layout.minimumInteritemSpacing = 10
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(collectionView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -18),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 210)
        ])
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.text = "Related Content"
        
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(RelationCell.self, forCellWithReuseIdentifier: "RelationCell")
    }
    
    func configure(with relations: [String: Any]?) {
        if let nodes = relations?["nodes"] as? [[String: Any]] {
            self.relations = nodes
            collectionView.reloadData()
        }
    }
}

extension RelationsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return relations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RelationCell", for: indexPath) as! RelationCell
        cell.configure(with: relations[indexPath.item])
        return cell
    }
}

class RelationCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.5),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 3
    }
    
    func configure(with relation: [String: Any]) {
        if let title = relation["title"] as? [String: String],
           let coverImage = relation["coverImage"] as? [String: String],
           let imageUrlString = coverImage["extraLarge"],
           let imageUrl = URL(string: imageUrlString) {
            titleLabel.text = title["userPreferred"]
            imageView.kf.setImage(with: imageUrl)
        }
    }
}

class StatsView: UIView {
    private let titleLabel = UILabel()
    private let barChartView = UIView()
    private let averageScoreLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 12
        
        addSubview(titleLabel)
        addSubview(barChartView)
        addSubview(averageScoreLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        barChartView.translatesAutoresizingMaskIntoConstraints = false
        averageScoreLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            barChartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            barChartView.leadingAnchor.constraint(equalTo: leadingAnchor),
            barChartView.trailingAnchor.constraint(equalTo: trailingAnchor),
            barChartView.heightAnchor.constraint(equalToConstant: 150),
            
            averageScoreLabel.topAnchor.constraint(equalTo: barChartView.bottomAnchor, constant: 20),
            averageScoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            averageScoreLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.text = "Ratings & Statistics"
        titleLabel.textColor = .label
        
        averageScoreLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        averageScoreLabel.textColor = .secondaryLabel
    }

    func configure(with stats: [String: Any]?) {
        barChartView.subviews.forEach { $0.removeFromSuperview() }

        guard let scoreDistribution = stats?["scoreDistribution"] as? [[String: Int]] else {
            return
        }

        let sortedDistribution = scoreDistribution.sorted { $0["score"] ?? 0 < $1["score"] ?? 0 }
        let maxAmount = sortedDistribution.max { ($0["amount"] ?? 0) < ($1["amount"] ?? 0) }?["amount"] ?? 1
        
        let totalScore = sortedDistribution.reduce(0) { $0 + ($1["score"] ?? 0) * ($1["amount"] ?? 0) }
        let totalAmount = sortedDistribution.reduce(0) { $0 + ($1["amount"] ?? 0) }
        let averageScore = Double(totalScore) / Double(totalAmount)
        
        averageScoreLabel.text = String(format: "Average Score: %.1f", averageScore)

        for (index, scoreStat) in sortedDistribution.enumerated() {
            if let score = scoreStat["score"], let amount = scoreStat["amount"] {
                let barView = UIView()
                barView.layer.cornerRadius = 4
                barView.backgroundColor = .systemTeal
                barChartView.addSubview(barView)

                barView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    barView.bottomAnchor.constraint(equalTo: barChartView.bottomAnchor),
                    barView.leadingAnchor.constraint(equalTo: barChartView.leadingAnchor, constant: CGFloat(index) * (barChartView.bounds.width / CGFloat(sortedDistribution.count))),
                    barView.widthAnchor.constraint(equalToConstant: (barChartView.bounds.width / CGFloat(sortedDistribution.count)) - 4),
                    barView.heightAnchor.constraint(equalTo: barChartView.heightAnchor, multiplier: CGFloat(amount) / CGFloat(maxAmount))
                ])
                
                let scoreLabel = UILabel()
                scoreLabel.text = "\(score)"
                scoreLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                scoreLabel.textAlignment = .center
                scoreLabel.textColor = .secondaryLabel
                barChartView.addSubview(scoreLabel)

                scoreLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    scoreLabel.topAnchor.constraint(equalTo: barView.bottomAnchor, constant: 4),
                    scoreLabel.centerXAnchor.constraint(equalTo: barView.centerXAnchor)
                ])
            }
        }
    }
}
 
class CharactersView: UIView {
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private let cellId = "CharacterCollectionViewCell"
    private var characters: [[String: Any]] = []

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.itemSize = CGSize(width: 120, height: 140)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(collectionView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.backgroundColor = UIColor.secondarySystemBackground
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.dataSource = self
        collectionView.register(CharacterCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.text = "Characters"
    }
    
    func configure(with charactersData: [String: Any]?) {
        guard let edges = charactersData?["edges"] as? [[String: Any]] else {
            return
        }
        
        self.characters = edges.compactMap { edge in
            guard let node = edge["node"] as? [String: Any] else {
                return nil
            }
            return node
        }
        
        collectionView.reloadData()
    }
}

extension CharactersView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CharacterCollectionViewCell
        let character = characters[indexPath.item]
        cell.configure(with: character)
        return cell
    }
}

class CharacterCollectionViewCell: UICollectionViewCell {
    private let characterImageView = UIImageView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        characterImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(characterImageView)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            characterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            characterImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            characterImageView.widthAnchor.constraint(equalToConstant: 100),
            characterImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: characterImageView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        
        characterImageView.contentMode = .scaleAspectFill
        characterImageView.clipsToBounds = true
        characterImageView.layer.cornerRadius = 50
        
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.numberOfLines = 3
    }
    
    func configure(with character: [String: Any]) {
        if let name = character["name"] as? [String: String],
           let image = character["image"] as? [String: String] {
            
            let fullName = name["full"] ?? ""
            let nativeName = name["native"] ?? ""
            
            if !nativeName.isEmpty {
                nameLabel.text = "\(fullName)\n(\(nativeName))"
            } else {
                nameLabel.text = fullName
            }
            
            if let largeImage = image["large"], let imageUrl = URL(string: largeImage) {
                characterImageView.kf.setImage(with: imageUrl)
            } else if let mediumImage = image["medium"], let imageUrl = URL(string: mediumImage) {
                characterImageView.kf.setImage(with: imageUrl)
            }
        }
    }
}
