//
//  AnimeInformation.swift
//  AnimeLounge
//
//  Created by Francesco on 22/06/24.
//

import UIKit
import Kingfisher
import SwiftSoup

class AnimeInformationViewController: UIViewController {
    private let animeID: Int
    private var animeData: [String: Any]?
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()
    
    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    init(animeID: Int) {
        self.animeID = animeID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAnimeDetails()
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(coverImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(detailsStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            coverImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            coverImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverImageView.heightAnchor.constraint(equalToConstant: 300),
            coverImageView.widthAnchor.constraint(equalToConstant: 200),
            
            descriptionLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func fetchAnimeDetails() {
        let service = UserDefaults.standard.string(forKey: "AnimeListingService") ?? "AniList"
        
        switch service {
        case "AniList":
            AnimeService.fetchAnimeDetails(animeID: animeID) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleResult(result)
                }
            }
        case "MAL":
            MALService.fetchAnimeDetails(animeID: animeID) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleResult(result)
                }
            }
        case "Kitsu":
            KitsuService.fetchAnimeDetails(animeID: animeID) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleResult(result)
                }
            }
        default:
            showError("Unknown service")
        }
    }
    
    private func handleResult(_ result: Result<[String: Any], Error>) {
        switch result {
        case .success(let data):
            self.animeData = data
            updateUI()
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }
    
    private func updateUI() {
        titleLabel.text = title
        descriptionLabel.text = animeDescription
        
        if let coverImageURL = coverImageURL {
            URLSession.shared.dataTask(with: coverImageURL) { [weak self] data, _, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.coverImageView.image = image
                    }
                }
            }.resume()
        }
        
        updateDetailsStackView()
    }
    
    private func updateDetailsStackView() {
        let details = [
            ("Episodes", episodes),
            ("Status", status),
            ("Aired", aired),
            ("Genres", genres)
        ]
        
        for (title, value) in details {
            let label = UILabel()
            label.text = "\(title): \(value)"
            label.font = UIFont.systemFont(ofSize: 14)
            label.numberOfLines = 0
            detailsStackView.addArrangedSubview(label)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override var title: String? {
        get {
            if let title = animeData?["title"] as? [String: String] {
                return title["english"] ?? title["romaji"] ?? "Unknown Title"
            }
            return animeData?["title"] as? String ?? "Unknown Title"
        }
        set {
            super.title = newValue
        }
    }
    
    var animeDescription: String {
        animeData?["description"] as? String ?? "No description available"
    }
    
    private var coverImageURL: URL? {
        if let coverImage = animeData?["coverImage"] as? [String: String],
           let urlString = coverImage["extraLarge"] {
            return URL(string: urlString)
        }
        return nil
    }
    
    private var episodes: String {
        if let episodes = animeData?["episodes"] as? Int {
            return "\(episodes)"
        }
        return "Unknown"
    }
    
    private var status: String {
        animeData?["status"] as? String ?? "Unknown"
    }
    
    private var aired: String {
        if let startDate = animeData?["startDate"] as? [String: Int],
           let year = startDate["year"],
           let month = startDate["month"],
           let day = startDate["day"] {
            return "\(year)-\(month)-\(day)"
        }
        return "Unknown"
    }
    
    private var genres: String {
        if let genres = animeData?["genres"] as? [String] {
            return genres.joined(separator: ", ")
        }
        return "Unknown"
    }
}
