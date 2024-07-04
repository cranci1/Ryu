//
//  SearchResultsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Kingfisher

class SearchResultsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var searchResults: [(title: String, imageUrl: String, href: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "resultCell")
    }
        
    func navigateToAnimeDetail(title: String, imageUrl: String, href: String) {
        let detailVC = AnimeDetailViewController()
        detailVC.configure(title: title, imageUrl: imageUrl, href: href)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension SearchResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as! SearchResultCell
        let result = searchResults[indexPath.row]
        
        cell.titleLabel.text = result.title
        
        if let url = URL(string: result.imageUrl) {
            cell.animeImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"), options: [.transition(.fade(0.2)), .cacheOriginalImage])
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResult = searchResults[indexPath.row]
        navigateToAnimeDetail(title: selectedResult.title, imageUrl: selectedResult.imageUrl, href: selectedResult.href)
    }
}

extension SearchResultsViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = interaction.view as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else {
            return nil
        }
        
        let result = searchResults[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            let detailVC = AnimeDetailViewController()
            detailVC.configure(title: result.title, imageUrl: result.imageUrl, href: result.href)
            return detailVC
        }, actionProvider: { _ in
            let openAction = UIAction(title: "Open", image: UIImage(systemName: "arrow.up.right.square")) { [weak self] _ in
                self?.navigateToAnimeDetail(title: result.title, imageUrl: result.imageUrl, href: result.href)
            }
            return UIMenu(title: "", children: [openAction])
        })
    }
}

class SearchResultCell: UITableViewCell {
    let animeImageView = UIImageView()
    let titleLabel = UILabel()
    let disclosureIndicatorImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        configureAppearance()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.1) {
            self.contentView.alpha = highlighted ? 0.7 : 1.0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        animeImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        disclosureIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(animeImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(disclosureIndicatorImageView)
        
        NSLayoutConstraint.activate([
            animeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            animeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            animeImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            animeImageView.widthAnchor.constraint(equalToConstant: 100),
            
            titleLabel.leadingAnchor.constraint(equalTo: animeImageView.trailingAnchor, constant: 15),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: disclosureIndicatorImageView.leadingAnchor, constant: -10),
            
            disclosureIndicatorImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            disclosureIndicatorImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            disclosureIndicatorImageView.widthAnchor.constraint(equalToConstant: 10),
            disclosureIndicatorImageView.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        animeImageView.clipsToBounds = true
        animeImageView.contentMode = .scaleAspectFill
        
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        
        disclosureIndicatorImageView.image = UIImage(systemName: "chevron.compact.right")
        disclosureIndicatorImageView.tintColor = .gray
    }
    
    private func configureAppearance() {
        backgroundColor = UIColor.secondarySystemBackground
    }
}
