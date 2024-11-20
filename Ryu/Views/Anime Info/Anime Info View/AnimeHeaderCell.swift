//
//  AnimeHeaderCell.swift
//  Ryu
//
//  Created by Francesco on 01/08/24.
//

import UIKit

class AnimeHeaderCell: UITableViewCell {
    private let animeImageView = UIImageView()
    private let titleLabel = UILabel()
    private let aliasLabel = UILabel()
    private let bookmarkImageView = UIImageView()
    private let optionsButton = UIImageView()
    private let starLabel = UILabel()
    private let airDateLabel = UILabel()
    private let starIconImageView = UIImageView()
    private let calendarIconImageView = UIImageView()
    private let watchNextButton = UIButton()
    private let playImageView = UIImageView()
    
    var favoriteButtonTapped: (() -> Void)?
    var showOptionsMenu: (() -> Void)?
    var watchNextTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground

        contentView.addSubview(animeImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(aliasLabel)
        contentView.addSubview(bookmarkImageView)
        contentView.addSubview(optionsButton)
        contentView.addSubview(starLabel)
        contentView.addSubview(airDateLabel)
        contentView.addSubview(starIconImageView)
        contentView.addSubview(calendarIconImageView)
        contentView.addSubview(watchNextButton)
        contentView.addSubview(playImageView)

        [animeImageView, titleLabel, aliasLabel, bookmarkImageView, optionsButton, starLabel, airDateLabel, starIconImageView, calendarIconImageView, watchNextButton, playImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        animeImageView.contentMode = .scaleAspectFill
        animeImageView.layer.cornerRadius = 8
        animeImageView.clipsToBounds = true
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 21)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 4
        
        aliasLabel.font = UIFont.systemFont(ofSize: 13)
        aliasLabel.textColor = .secondaryLabel
        aliasLabel.numberOfLines = 2
        
        bookmarkImageView.image = UIImage(systemName: "bookmark")
        bookmarkImageView.tintColor = .systemTeal
        bookmarkImageView.isUserInteractionEnabled = true
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(favoriteButtonPressed))
        bookmarkImageView.addGestureRecognizer(tapGesture2)
        
        optionsButton.image = UIImage(systemName: "ellipsis.circle.fill")
        optionsButton.tintColor = .systemTeal
        optionsButton.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(optionsButtonTapped))
        optionsButton.addGestureRecognizer(tapGesture)
        
        starLabel.font = UIFont.boldSystemFont(ofSize: 15)
        starLabel.textColor = .secondaryLabel
        
        airDateLabel.font = UIFont.boldSystemFont(ofSize: 15)
        airDateLabel.textColor = .secondaryLabel
        
        starIconImageView.image = UIImage(systemName: "star.fill")
        starIconImageView.tintColor = .systemGray
        
        calendarIconImageView.image = UIImage(systemName: "calendar")
        calendarIconImageView.tintColor = .systemGray
        
        watchNextButton.setTitle("Watch Next Episode", for: .normal)
        watchNextButton.setTitleColor(.systemTeal, for: .normal)
        watchNextButton.addTarget(self, action: #selector(watchNextButtonTapped), for: .touchUpInside)
        
        playImageView.image = UIImage(systemName: "play.circle.fill")
        playImageView.tintColor = .systemTeal
        
        NSLayoutConstraint.activate([
            animeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            animeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            animeImageView.widthAnchor.constraint(equalToConstant: 110),
            animeImageView.heightAnchor.constraint(equalToConstant: 160),
            
            titleLabel.topAnchor.constraint(equalTo: animeImageView.topAnchor, constant: -4),
            titleLabel.leadingAnchor.constraint(equalTo: animeImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            aliasLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            aliasLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            aliasLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            bookmarkImageView.centerYAnchor.constraint(equalTo: optionsButton.centerYAnchor),
            bookmarkImageView.trailingAnchor.constraint(equalTo: optionsButton.leadingAnchor, constant: -10),
            bookmarkImageView.widthAnchor.constraint(equalToConstant: 28),
            bookmarkImageView.heightAnchor.constraint(equalToConstant: 28),
            
            optionsButton.bottomAnchor.constraint(equalTo: animeImageView.bottomAnchor),
            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            optionsButton.widthAnchor.constraint(equalToConstant: 30),
            optionsButton.heightAnchor.constraint(equalToConstant: 30),
            
            starIconImageView.topAnchor.constraint(equalTo: animeImageView.bottomAnchor, constant: 16),
            starIconImageView.leadingAnchor.constraint(equalTo: animeImageView.leadingAnchor),
            starIconImageView.widthAnchor.constraint(equalToConstant: 20),
            starIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            starLabel.bottomAnchor.constraint(equalTo: starIconImageView.bottomAnchor),
            starLabel.leadingAnchor.constraint(equalTo: starIconImageView.trailingAnchor, constant: 2),
            
            calendarIconImageView.topAnchor.constraint(equalTo: animeImageView.bottomAnchor, constant: 16),
            calendarIconImageView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            calendarIconImageView.widthAnchor.constraint(equalToConstant: 20),
            calendarIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            airDateLabel.bottomAnchor.constraint(equalTo: calendarIconImageView.bottomAnchor),
            airDateLabel.trailingAnchor.constraint(equalTo: calendarIconImageView.leadingAnchor, constant: -2),
            
            watchNextButton.leadingAnchor.constraint(equalTo: playImageView.trailingAnchor, constant: 2),
            watchNextButton.centerYAnchor.constraint(equalTo: playImageView.centerYAnchor),
            
            playImageView.topAnchor.constraint(equalTo: starIconImageView.bottomAnchor, constant: 15),
            playImageView.leadingAnchor.constraint(equalTo: starIconImageView.leadingAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 35),
            playImageView.heightAnchor.constraint(equalToConstant: 35),
            
            contentView.bottomAnchor.constraint(equalTo: playImageView.bottomAnchor, constant: 10)
        ])
    }
    
    @objc private func favoriteButtonPressed() {
        favoriteButtonTapped?()
    }
    
    @objc private func optionsButtonTapped() {
        showOptionsMenu?()
    }
    
    @objc private func watchNextButtonTapped() {
        watchNextTapped?()
    }
    
    func configure(title: String?, imageUrl: String?, aliases: String, isFavorite: Bool, airdate: String, stars: String, href: String?) {
        titleLabel.text = title
        aliasLabel.text = aliases
        airDateLabel.text = airdate
        
        let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource")
        
        switch selectedSource {
        case "AnimeWorld", "Anime3rb":
            starLabel.text = stars == "?" ? "N/A" : stars + "/10"
            airDateLabel.text = airdate
        case "GoGoAnime", "AnimeFire", "JKanime":
            starLabel.text = "N/A"
        default:
            starLabel.text = stars == "?" ? "N/A" : stars
            airDateLabel.text = airdate
        }
        
        if let url = URL(string: imageUrl ?? "") {
            animeImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        }
        updateFavoriteButtonState(isFavorite: isFavorite)
        
        optionsButton.isUserInteractionEnabled = href != nil
    }
    
    private func updateFavoriteButtonState(isFavorite: Bool) {
        let imageName = isFavorite ? "bookmark.fill" : "bookmark"
        bookmarkImageView.image = UIImage(systemName: imageName)
        bookmarkImageView.tintColor = isFavorite ? .systemYellow : .systemTeal
    }
}
