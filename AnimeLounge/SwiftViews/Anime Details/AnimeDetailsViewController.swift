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
    private let startWatchingButton = UIButton()
    private let episodeProgressView = UIProgressView()
    private let episodeNameLabel = UILabel()
    private let episodeProgressLabel = UILabel()
    private let episodeDownloadButton = UIButton()
    private let tableView = UITableView()

    private var animeTitle: String?
    private var imageUrl: String?
    private var href: String?

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
        
        setupScrollView()
        setupImageView()
        setupTitleSection()
        setupRatingSection()
        setupSynopsisSection()
        setupEpisodeSection()
        setupTableView()
    }

    private func updateUI() {
        titleLabel.text = animeTitle
        aliasLabel.text = "Anime Alias 1, Anime Alias 2"

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
            let synopsis = try document.select("div.desc div.long").text()
            
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
        
        synopsisLabel.translatesAutoresizingMaskIntoConstraints = false
        synopsisDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        synopsisLabel.font = UIFont.boldSystemFont(ofSize: 16)
        synopsisLabel.textColor = .label
        synopsisLabel.text = "Synopsis"
        
        synopsisDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        synopsisDescriptionLabel.textColor = .secondaryLabel
        synopsisDescriptionLabel.numberOfLines = 0
        
        NSLayoutConstraint.activate([
            synopsisLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            synopsisLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            
            synopsisDescriptionLabel.topAnchor.constraint(equalTo: synopsisLabel.bottomAnchor, constant: 4),
            synopsisDescriptionLabel.leadingAnchor.constraint(equalTo: synopsisLabel.leadingAnchor)
        ])
    }
    
    private func setupEpisodeSection() {
        // Implement episode section setup
    }
    
    private func setupTableView() {
        // Implement table view setup
    }
}
