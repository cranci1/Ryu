//
//  AnimeInformation.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher

class AnimeInformation: UIViewController, UITableViewDataSource {
    
    var animeID: Int = 0
    private var animeData: [String: Any]?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let coverImageView = UIImageView()
    private let bannerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let ratingView = RatingView()
    private let genresView = GenresView()
    private let descriptionView = DescriptionView()
    private let infoView = AnimeInfoView()
    private let statsView = StatsView()
    private let charactersView = CharactersView()
    private let relationsView = RelationsView()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAnimeData()
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        setupScrollView()
        setupHeaderView()
        setupContentViews()
        setupLoadingIndicator()
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
        contentView.addSubview(ratingView)
        contentView.addSubview(genresView)
        
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        genresView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 200),
            
            coverImageView.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: -60),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.widthAnchor.constraint(equalToConstant: 120),
            coverImageView.heightAnchor.constraint(equalToConstant: 180),
            
            titleLabel.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ratingView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            ratingView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            ratingView.heightAnchor.constraint(equalToConstant: 30),
            
            genresView.topAnchor.constraint(equalTo: ratingView.bottomAnchor, constant: 8),
            genresView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            genresView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            genresView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        coverImageView.layer.cornerRadius = 12
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.numberOfLines = 0
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
            stackView.topAnchor.constraint(equalTo: genresView.bottomAnchor, constant: 16),
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
        
        if let titleDict = animeData["title"] as? [String: String] {
            self.title = titleDict["romaji"]
            titleLabel.text = titleDict["english"] ?? titleDict["romaji"]
        }
        
        if let coverImage = (animeData["coverImage"] as? [String: String])?["extraLarge"],
           let coverImageUrl = URL(string: coverImage) {
            coverImageView.kf.setImage(with: coverImageUrl)
        }
        
        if let bannerImage = animeData["bannerImage"] as? String,
           let bannerImageUrl = URL(string: bannerImage) {
            bannerImageView.kf.setImage(with: bannerImageUrl)
        }
        
        if let averageScore = animeData["averageScore"] as? Int {
            ratingView.setRating(score: averageScore)
        }
        
        if let genres = animeData["genres"] as? [String] {
            genresView.setGenres(genres)
        }
        
        descriptionView.configure(with: animeData["description"] as? String)
        infoView.configure(with: animeData)
        statsView.configure(with: animeData["stats"] as? [String: Any])
        charactersView.configure(with: animeData["characters"] as? [String: Any])
        relationsView.configure(with: animeData["relations"] as? [String: Any])
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

class RatingView: UIView {
    private let starStackView = UIStackView()
    private let scoreLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(starStackView)
        addSubview(scoreLabel)
        
        starStackView.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        starStackView.axis = .horizontal
        starStackView.spacing = 4
        
        NSLayoutConstraint.activate([
            starStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            starStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            scoreLabel.leadingAnchor.constraint(equalTo: starStackView.trailingAnchor, constant: 8),
            scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            scoreLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
        
        for _ in 0..<5 {
            let starImageView = UIImageView(image: UIImage(systemName: "star.fill"))
            starImageView.tintColor = .systemYellow
            starStackView.addArrangedSubview(starImageView)
        }
        
        scoreLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    }
    
    func setRating(score: Int) {
        let starCount = Int((Float(score) / 20.0).rounded())
        for (index, view) in starStackView.arrangedSubviews.enumerated() {
            if let starImageView = view as? UIImageView {
                starImageView.image = UIImage(systemName: index < starCount ? "star.fill" : "star")
            }
        }
        scoreLabel.text = "\(score)/100"
    }
}

class GenresView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.showsHorizontalScrollIndicator = false
        
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    func setGenres(_ genres: [String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for genre in genres {
            let genreLabel = PaddedLabel()
            genreLabel.text = genre
            genreLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            genreLabel.textColor = .secondaryLabel
            genreLabel.clipsToBounds = false
            stackView.addArrangedSubview(genreLabel)
        }
    }
}

class PaddedLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 16, height: size.height + 8)
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
        
        addInfoRow(title: "Type", value: animeData["type"] as? String)
        addInfoRow(title: "Format", value: animeData["format"] as? String)
        addInfoRow(title: "Status", value: animeData["status"] as? String)
        addInfoRow(title: "Episodes", value: animeData["episodes"] as? Int)
        addInfoRow(title: "Duration", value: animeData["duration"] as? Int)
        addInfoRow(title: "Source", value: animeData["source"] as? String)
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
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        
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
        return "\(year)-\(String(format: "%02d", month))-\(String(format: "%02d", day))"
    }
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
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.text = "Description"
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 0
    }
    
    func configure(with description: String?) {
        descriptionLabel.text = description ?? "No description available."
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
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 170)
        ])
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
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
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(barChartView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        barChartView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            barChartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            barChartView.leadingAnchor.constraint(equalTo: leadingAnchor),
            barChartView.trailingAnchor.constraint(equalTo: trailingAnchor),
            barChartView.bottomAnchor.constraint(equalTo: bottomAnchor),
            barChartView.heightAnchor.constraint(equalToConstant: 100)
        ])

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.text = "Ratings & Statistics"
        titleLabel.textColor = .lightGray
    }

    func configure(with stats: [String: Any]?) {
        barChartView.subviews.forEach { $0.removeFromSuperview() }

        if let scoreDistribution = stats?["scoreDistribution"] as? [[String: Int]] {
            let sortedDistribution = scoreDistribution.sorted { $0["score"] ?? 0 < $1["score"] ?? 0 }
            let maxAmount = sortedDistribution.max { ($0["amount"] ?? 0) < ($1["amount"] ?? 0) }?["amount"] ?? 1

            for (index, scoreStat) in sortedDistribution.enumerated() {
                if let score = scoreStat["score"], let amount = scoreStat["amount"] {
                    let barView = UIView()
                    barView.backgroundColor = .systemTeal
                    barView.layer.cornerRadius = 2
                    barChartView.addSubview(barView)

                    barView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        barView.bottomAnchor.constraint(equalTo: barChartView.bottomAnchor),
                        barView.leadingAnchor.constraint(equalTo: barChartView.leadingAnchor, constant: CGFloat(index) * (barChartView.bounds.width / CGFloat(sortedDistribution.count))),
                        barView.widthAnchor.constraint(equalToConstant: (barChartView.bounds.width / CGFloat(sortedDistribution.count)) - 2),
                        barView.heightAnchor.constraint(equalTo: barChartView.heightAnchor, multiplier: CGFloat(amount) / CGFloat(maxAmount))
                    ])

                    let scoreLabel = UILabel()
                    scoreLabel.text = "\(score)"
                    scoreLabel.font = UIFont.systemFont(ofSize: 10)
                    scoreLabel.textAlignment = .center
                    barChartView.addSubview(scoreLabel)

                    scoreLabel.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        scoreLabel.topAnchor.constraint(equalTo: barView.bottomAnchor, constant: 2),
                        scoreLabel.centerXAnchor.constraint(equalTo: barView.centerXAnchor)
                    ])
                }
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
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.text = "Characters"
    }
    
    func configure(with characters: [String: Any]?) {
        if let edges = characters?["edges"] as? [[String: Any]] {
            self.characters = edges
            collectionView.reloadData()
        }
    }
}

extension CharactersView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CharacterCollectionViewCell
        cell.configure(with: characters[indexPath.item])
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
            
            nameLabel.topAnchor.constraint(equalTo: characterImageView.bottomAnchor, constant: 8),
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
        if let node = character["node"] as? [String: Any],
           let name = node["name"] as? [String: String] {
            let firstName = name["first"] ?? ""
            let lastName = name["last"] ?? ""
            let nativeName = name["native"] ?? ""
            
            let fullName = "\(firstName) \(lastName)"
            let displayName = fullName + (nativeName.isEmpty ? "" : " (\(nativeName))")
            
            nameLabel.text = displayName
        }
        
        if let node = character["node"] as? [String: Any],
           let image = node["image"] as? [String: String],
           let imageUrlString = image["large"] ?? image["medium"],
           let imageUrl = URL(string: imageUrlString) {
            characterImageView.kf.setImage(with: imageUrl, placeholder: UIImage(systemName: "questionmark.circle.fill"))
        }
    }
}

class AnimeService {
    static func fetchAnimeDetails(animeID: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let query = """
        query {
            Media(id: \(animeID), type: ANIME) {
                id
                idMal
                title {
                    romaji
                    english
                    native
                    userPreferred
                }
                type
                format
                status
                description
                startDate {
                    year
                    month
                    day
                }
                endDate {
                    year
                    month
                    day
                }
                season
                episodes
                duration
                countryOfOrigin
                isLicensed
                source
                hashtag
                trailer {
                    id
                    site
                }
                updatedAt
                coverImage {
                    extraLarge
                }
                bannerImage
                genres
                popularity
                tags {
                    id
                    name
                }
                relations {
                    nodes {
                        id
                        coverImage { extraLarge }
                        title { userPreferred },
                        mediaListEntry { status }
                    }
                }
                characters {
                    edges {
                        node {
                            name {
                                first
                                last
                                native
                            }
                            image {
                                large
                                medium
                            }
                        }
                        role
                        voiceActors {
                            name {
                                first
                                last
                                native
                            }
                        }
                    }
                }
                siteUrl
                stats {
                    scoreDistribution {
                        score
                        amount
                    }
                }
                airingSchedule(notYetAired: true) {
                    nodes {
                        airingAt
                        episode
                    }
                }
            }
        }
        """
        
        let apiUrl = URL(string: "https://graphql.anilist.co")!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": query], options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AnimeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let media = data["Media"] as? [String: Any] {
                    completion(.success(media))
                } else {
                    completion(.failure(NSError(domain: "AnimeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
