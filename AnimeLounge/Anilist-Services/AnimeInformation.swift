//
//  AnimeInformation.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher

class AnimeInformation: UITableViewController {
    
    var animeID: Int = 0
    var animeData: [String: Any]?
    
    private let coverImageView = UIImageView()
    private let bannerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let ratingView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAnimeData()
    }
    
    private func setupUI() {
        tableView.backgroundColor = UIColor.secondarySystemBackground
        tableView.register(AnimeInfoCell.self, forCellReuseIdentifier: "AnimeInfoCell")
        tableView.register(AnimeCharacterCell.self, forCellReuseIdentifier: "AnimeCharacterCell")
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        
        setupHeaderView()
        setupLoadingIndicator()
    }
    
    private func setupHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 300))
        
        headerView.addSubview(bannerImageView)
        headerView.addSubview(coverImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(ratingView)
        
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 180),
            
            coverImageView.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: -60),
            coverImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            coverImageView.widthAnchor.constraint(equalToConstant: 120),
            coverImageView.heightAnchor.constraint(equalToConstant: 180),
            
            titleLabel.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            ratingView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            ratingView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            ratingView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        coverImageView.layer.cornerRadius = 12
        coverImageView.clipsToBounds = true
        coverImageView.contentMode = .scaleAspectFill
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.numberOfLines = 0
        
        setupRatingView()
        
        tableView.tableHeaderView = headerView
    }
    
    private func setupRatingView() {
        let starSize: CGFloat = 20
        let spacing: CGFloat = 4
        
        for i in 0..<5 {
            let starImageView = UIImageView(image: UIImage(systemName: "star.fill"))
            starImageView.tintColor = .systemYellow
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            ratingView.addSubview(starImageView)
            
            NSLayoutConstraint.activate([
                starImageView.leadingAnchor.constraint(equalTo: ratingView.leadingAnchor, constant: CGFloat(i) * (starSize + spacing)),
                starImageView.centerYAnchor.constraint(equalTo: ratingView.centerYAnchor),
                starImageView.widthAnchor.constraint(equalToConstant: starSize),
                starImageView.heightAnchor.constraint(equalToConstant: starSize)
            ])
        }
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
        
        if let coverImage = (animeData["coverImage"] as? [String: String])?["large"],
           let coverImageUrl = URL(string: coverImage) {
            coverImageView.kf.setImage(with: coverImageUrl)
        }
        
        if let bannerImage = animeData["bannerImage"] as? String,
           let bannerImageUrl = URL(string: bannerImage) {
            bannerImageView.kf.setImage(with: bannerImageUrl)
        }
        
        if let averageScore = animeData["averageScore"] as? Int {
            updateRatingView(score: averageScore)
        }
        
        tableView.reloadData()
    }
    
    private func updateRatingView(score: Int) {
        let starCount = Int((Float(score) / 20.0).rounded())
        for (index, view) in ratingView.subviews.enumerated() {
            if let starImageView = view as? UIImageView {
                starImageView.image = index < starCount ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            }
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return animeData?["characters"] != nil ? 1 : 0
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnimeInfoCell", for: indexPath) as! AnimeInfoCell
            cell.configure(with: animeData)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnimeCharacterCell", for: indexPath) as! AnimeCharacterCell
            if let characters = animeData?["characters"] as? [String: Any],
               let edges = characters["edges"] as? [[String: Any]] {
                cell.configure(with: edges)
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Anime Information" : "Characters"
    }
}

class AnimeInfoCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let genresLabel = UILabel()
    private let scoreLabel = UILabel()
    private let episodesLabel = UILabel()
    private let statusLabel = UILabel()
    private let datesLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel, descriptionLabel, genresLabel,
            scoreLabel, episodesLabel, statusLabel, datesLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = UIColor.secondarySystemBackground
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.numberOfLines = 0
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 0
        
        genresLabel.font = UIFont.systemFont(ofSize: 14)
        genresLabel.textColor = .secondaryLabel
        genresLabel.numberOfLines = 0
        
        scoreLabel.font = UIFont.systemFont(ofSize: 16)
        scoreLabel.textColor = .systemGreen
        
        episodesLabel.font = UIFont.systemFont(ofSize: 16)
        episodesLabel.textColor = .systemBlue
        
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = .systemRed
        
        datesLabel.font = UIFont.systemFont(ofSize: 14)
        datesLabel.textColor = .secondaryLabel
        datesLabel.numberOfLines = 0
    }
    
    func configure(with animeData: [String: Any]?) {
        guard let animeData = animeData else { return }
        
        if let titleDict = animeData["title"] as? [String: String] {
            titleLabel.text = titleDict["romaji"] ?? titleDict["english"]
        }
        
        descriptionLabel.text = animeData["description"] as? String
        
        if let genres = animeData["genres"] as? [String] {
            genresLabel.text = "Genres: " + genres.joined(separator: ", ")
        }
        
        if let averageScore = animeData["averageScore"] as? Int {
            scoreLabel.text = "Score: \(averageScore)"
        }
        
        if let episodes = animeData["episodes"] as? Int {
            episodesLabel.text = "Episodes: \(episodes)"
        }
        
        if let status = animeData["status"] as? String {
            statusLabel.text = "Status: \(status)"
        }
        
        if let startDateDict = animeData["startDate"] as? [String: Int],
           let endDateDict = animeData["endDate"] as? [String: Int] {
            let startDate = "\(startDateDict["year"] ?? 0)-\(startDateDict["month"] ?? 0)-\(startDateDict["day"] ?? 0)"
            let endDate = "\(endDateDict["year"] ?? 0)-\(endDateDict["month"] ?? 0)-\(endDateDict["day"] ?? 0)"
            datesLabel.text = "Aired: \(startDate) to \(endDate)"
        }
    }
}

class AnimeCharacterCell: UITableViewCell {
    private let collectionView: UICollectionView
    private let cellId = "CharacterCollectionViewCell"
    private var characters: [[String: Any]] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.itemSize = CGSize(width: 120, height: 140)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.secondarySystemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(CharacterCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        
        contentView.addSubview(collectionView)
        
        let collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 140)
        collectionViewHeightConstraint.priority = .required
        collectionViewHeightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with characters: [[String: Any]]) {
        self.characters = characters
        collectionView.reloadData()
    }
}

extension AnimeCharacterCell: UICollectionViewDataSource {
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
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        
        characterImageView.contentMode = .scaleAspectFill
        characterImageView.clipsToBounds = true
        characterImageView.layer.cornerRadius = 50
        
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.numberOfLines = 2
    }
    
    func configure(with character: [String: Any]) {
        if let node = character["node"] as? [String: Any],
           let name = node["name"] as? [String: String] {
            nameLabel.text = name["full"]
        }
        
        if let node = character["node"] as? [String: Any],
           let image = node["image"] as? [String: String],
           let imageUrlString = image["large"],
           let imageUrl = URL(string: imageUrlString) {
            characterImageView.kf.setImage(with: imageUrl, placeholder: UIImage(systemName: "person.circle.fill"))
        }
    }
}

class AnimeService {
    static func fetchAnimeDetails(animeID: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let query = """
        query {
          Media(id: \(animeID), type: ANIME) {
            id
            title {
              romaji
              english
              native
            }
            description(asHtml: false)
            coverImage {
              large
            }
            bannerImage
            averageScore
            genres
            episodes
            status
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
            characters {
              edges {
                role
                node {
                  id
                  name {
                    full
                  }
                  image {
                    large
                  }
                }
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
