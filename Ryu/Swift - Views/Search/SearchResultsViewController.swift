//
//  SearchResultsViewController.swift
//  Ryu
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Kingfisher
import Alamofire
import SwiftSoup

class SearchResultsViewController: UIViewController {

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let noResultsLabel = UILabel()

    var searchResults: [(title: String, imageUrl: String, href: String)] = []
    var filteredResults: [(title: String, imageUrl: String, href: String)] = []
    var query: String = ""
    var selectedSource: String = ""

    private lazy var sortButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(sortButtonTapped))
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        setupUI()
        fetchResults()
    }

    private func setupUI() {
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .secondarySystemBackground
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "resultCell")
        
        setupLoadingIndicator()
        setupErrorLabel()
        setupNoResultsLabel()
        
        selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
        if ["AnimeWorld", "GoGoAnime", "Kuramanime", "AnimeFire"].contains(selectedSource) {
            navigationItem.rightBarButtonItem = sortButton
        }
    }

    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupErrorLabel() {
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupNoResultsLabel() {
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        noResultsLabel.textAlignment = .center
        noResultsLabel.text = "No results found"
        noResultsLabel.isHidden = true
        view.addSubview(noResultsLabel)
        NSLayoutConstraint.activate([
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func sortButtonTapped() {
        let alertController = UIAlertController(title: "Sort Anime", message: nil, preferredStyle: .actionSheet)
        
        let allAction = UIAlertAction(title: "All", style: .default) { [weak self] _ in
            self?.filterResults(option: .all)
        }
        
        switch selectedSource {
        case "GoGoAnime":
            let dubAction = UIAlertAction(title: "Dub", style: .default) { [weak self] _ in
                self?.filterResults(option: .dub)
            }
            let subAction = UIAlertAction(title: "Sub", style: .default) { [weak self] _ in
                self?.filterResults(option: .sub)
            }
            alertController.addAction(dubAction)
            alertController.addAction(subAction)
        case "AnimeWorld":
            let itaAction = UIAlertAction(title: "Dub", style: .default) { [weak self] _ in
                self?.filterResults(option: .ita)
            }
            alertController.addAction(itaAction)
        case "Kuramanime":
            let dubAction = UIAlertAction(title: "Dub", style: .default) { [weak self] _ in
                self?.filterResults(option: .dub)
            }
            alertController.addAction(dubAction)
        case "AnimeFire":
            let dubAction = UIAlertAction(title: "Dub", style: .default) { [weak self] _ in
                self?.filterResults(option: .dub)
            }
            alertController.addAction(dubAction)
        default:
            break
        }
        
        alertController.addAction(allAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sortButton
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    private enum FilterOption {
        case all, dub, sub, ita
    }
    
    private func filterResults(option: FilterOption) {
        switch option {
        case .all:
            filteredResults = searchResults
        case .dub:
            switch selectedSource {
            case "GoGoAnime":
                filteredResults = searchResults.filter { $0.title.lowercased().contains("(dub)") }
            case "Kuramanime":
                filteredResults = searchResults.filter { $0.title.contains("(Dub ID)") }
            case "AnimeFire":
                filteredResults = searchResults.filter { $0.title.contains("(Dublado)") }
            default:
                filteredResults = searchResults
            }
        case .sub:
            filteredResults = searchResults.filter { !$0.title.lowercased().contains("(dub)") }
        case .ita:
            filteredResults = searchResults.filter { $0.title.contains("ITA") }
        }
        
        tableView.reloadData()
    }
    
    private func showSourceSelector() {
        let alertController = UIAlertController(title: "Select Source", message: "Please select a source to search from.", preferredStyle: .actionSheet)
        
        let sources = ["AnimeWorld", "GoGoAnime", "AnimeHeaven", "AnimeFire", "Kuramanime", "JKanime", "Anime3rb", "HiAnime", "ZoroTv"]
        
        for source in sources {
            let action = UIAlertAction(title: source, style: .default) { [weak self] _ in
                UserDefaults.standard.set(source, forKey: "selectedMediaSource")
                self?.selectedSource = source
                self?.refreshResults()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func refreshResults() {
        fetchResults()
    }
    
    private func fetchResults() {
        loadingIndicator.startAnimating()
        tableView.isHidden = true
        errorLabel.isHidden = true
        noResultsLabel.isHidden = true

        guard let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") else {
            loadingIndicator.stopAnimating()
            showSourceSelector()
            return
        }

        guard let urlParameters = getUrlAndParameters(for: selectedSource) else {
            showError("Unsupported media source.")
            return
        }

        AF.request(urlParameters.url, method: .get, parameters: urlParameters.parameters).responseString { [weak self] response in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()

            switch response.result {
            case .success(let value):
                let results = self.parseHTML(html: value, for: MediaSource(rawValue: selectedSource) ?? .animeWorld)
                self.searchResults = results
                self.filteredResults = results
                if results.isEmpty {
                    self.showNoResults()
                } else {
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                }
            case .failure(let error):
                if let httpStatusCode = response.response?.statusCode {
                    switch httpStatusCode {
                    case 400:
                        self.showError("Bad request. Please check your input and try again.")
                    case 403:
                        self.showError("Access forbidden. You don't have permission to access this resource.")
                    case 404:
                        self.showError("Resource not found. Please try a different search.")
                    case 429:
                        self.showError("Too many requests. Please slow down and try again later.")
                    case 500:
                        self.showError("Internal server error. Please try again later.")
                    case 502:
                        self.showError("Bad gateway. The server is temporarily unable to handle the request.")
                    case 503:
                        self.showError("Service unavailable. Please try again later.")
                    case 504:
                        self.showError("Gateway timeout. The server took too long to respond.")
                    default:
                        self.showError("Unexpected error occurred. Please try again later.")
                    }
                } else if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain {
                    switch nsError.code {
                    case NSURLErrorNotConnectedToInternet:
                        self.showError("No internet connection. Please check your network and try again.")
                    case NSURLErrorTimedOut:
                        self.showError("Request timed out. Please try again later.")
                    default:
                        self.showError("Network error occurred. Please try again later.")
                    }
                } else {
                    self.showError("Failed to fetch data. Please try again later.")
                }
            }
        }
    }

    private func getUrlAndParameters(for source: String) -> (url: String, parameters: Parameters)? {
        let url: String
        var parameters: Parameters = [:]

        switch source {
        case "AnimeWorld":
            url = "https://animeworld.so/search"
            parameters["keyword"] = query
        case "GoGoAnime":
            url = "https://anitaku.pe/search.html"
            parameters["keyword"] = query
        case "AnimeHeaven":
            url = "https://animeheaven.me/search.php"
            parameters["s"] = query
        case "AnimeFire":
            let encodedQuery = query.lowercased().addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
            url = "https://animefire.plus/pesquisar/\(encodedQuery)"
        case "Kuramanime":
            url = "https://kuramanime.boo/anime"
            parameters["search"] = query
        case "JKanime":
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            url = "https://jkanime.net/buscar/\(encodedQuery)"
        case "Anime3rb":
            url = "https://anime3rb.com/search"
            parameters["q"] = query
        case "HiAnime":
            url = "https://aniwatch.cranci.xyz/anime/search"
            parameters["q"] = query
        case "ZoroTv":
            url = "https://zorotv.com.in/"
            parameters["s"] = query
        default:
            return nil
        }
        
        return (url, parameters)
    }

    private func showError(_ message: String) {
        loadingIndicator.stopAnimating()
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private func showNoResults() {
        noResultsLabel.isHidden = false
    }

    func parseHTML(html: String, for source: MediaSource) -> [(title: String, imageUrl: String, href: String)] {
        switch source {
        case .hianime:
            return parseDocument(nil, jsonString: html, for: source)
        default:
            do {
                let document = try SwiftSoup.parse(html)
                return parseDocument(document, jsonString: nil, for: source)
            } catch {
                print("Error parsing HTML: \(error.localizedDescription)")
                return []
            }
        }
    }

    private func parseDocument(_ document: Document?, jsonString: String?, for source: MediaSource) -> [(title: String, imageUrl: String, href: String)] {
        switch source {
        case .animeWorld:
            guard let document = document else { return [] }
            return parseAnimeWorld(document)
        case .gogoanime:
            guard let document = document else { return [] }
            return parseGoGoAnime(document)
        case .animeheaven:
            guard let document = document else { return [] }
            return parseAnimeHeaven(document)
        case .animefire:
            guard let document = document else { return [] }
            return parseAnimeFire(document)
        case .kuramanime:
            guard let document = document else { return [] }
            return parseKuramanime(document)
        case .jkanime:
            guard let document = document else { return [] }
            return parseJKanime(document)
        case .anime3rb:
            guard let document = document else { return [] }
            return parseAnime3rb(document)
        case .hianime:
            guard let jsonString = jsonString else { return [] }
            return parseHiAnime(jsonString)
        case .zorotv:
            guard let document = document else { return [] }
            return parseZoroTv(document)
        }
    }

    private func navigateToAnimeDetail(title: String, imageUrl: String, href: String) {
        let detailVC = AnimeDetailViewController()
        detailVC.configure(title: title, imageUrl: imageUrl, href: href)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension SearchResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as! SearchResultCell
        let result = filteredResults[indexPath.row]
        
        cell.titleLabel.text = result.title
        
        if let url = URL(string: result.imageUrl) {
            cell.animeImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"), options: [.transition(.fade(0.2)), .cacheOriginalImage])
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResult = filteredResults[indexPath.row]
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
            
            let openInBrowserAction = UIAction(title: "Open in Browser", image: UIImage(systemName: "globe")) { [weak self] _ in
                self?.openInBrowser(path: result.href)
            }
            
            let favoriteAction = UIAction(title: self.isFavorite(for: result) ? "Remove from Favorites" : "Add to Favorites", image: UIImage(systemName: self.isFavorite(for: result) ? "star.fill" : "star")) { [weak self] _ in
                self?.toggleFavorite(for: result)
            }
            
            return UIMenu(title: "", children: [openAction, openInBrowserAction, favoriteAction])
        })
    }
    
    private func openInBrowser(path: String) {
        let selectedSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? ""
        let baseUrl: String
        
        switch selectedSource {
        case "AnimeWorld":
            baseUrl = "https://animeworld.so"
        case "GoGoAnime":
            baseUrl = "https://anitaku.pe"
        case "AnimeHeaven":
            baseUrl = "https://animeheaven.me/"
        default:
            baseUrl = ""
        }
        
        let fullUrlString = baseUrl + path
        
        guard let url = URL(string: fullUrlString) else {
            print("Invalid URL string: \(fullUrlString)")
            showAlert(withTitle: "Error", message: "The URL is invalid.")
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                print("Failed to open URL: \(url)")
                self.showAlert(withTitle: "Error", message: "Failed to open the URL.")
            }
        }
    }
    
    private func showAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func isFavorite(for result: (title: String, imageUrl: String, href: String)) -> Bool {
        guard let anime = createFavoriteAnime(from: result) else { return false }
        return FavoritesManager.shared.isFavorite(anime)
    }
    
    private func toggleFavorite(for result: (title: String, imageUrl: String, href: String)) {
        guard let anime = createFavoriteAnime(from: result) else { return }
        
        if FavoritesManager.shared.isFavorite(anime) {
            FavoritesManager.shared.removeFavorite(anime)
        } else {
            FavoritesManager.shared.addFavorite(anime)
        }
        
        if let index = searchResults.firstIndex(where: { $0.href == result.href }) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    private func createFavoriteAnime(from result: (title: String, imageUrl: String, href: String)) -> FavoriteItem? {
        guard let imageURL = URL(string: result.imageUrl),
              let contentURL = URL(string: result.href) else {
            return nil
        }
        let selectedMediaSource = UserDefaults.standard.string(forKey: "selectedMediaSource") ?? "AnimeWorld"
        
        return FavoriteItem(title: result.title, imageURL: imageURL, contentURL: contentURL, source: selectedMediaSource)
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
