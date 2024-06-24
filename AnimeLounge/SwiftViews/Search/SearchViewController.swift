//
//  SearchViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 21/06/24.
//

import UIKit
import Alamofire
import SwiftSoup

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var historyTableView: UITableView!
    
    var searchHistory: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        historyTableView.delegate = self
        historyTableView.dataSource = self
        
        historyTableView.register(HistoryTableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        loadSearchHistory()
    }
    
    func searchMedia(query: String) {
        if let index = searchHistory.firstIndex(of: query) {
            searchHistory.remove(at: index)
        }
        searchHistory.insert(query, at: 0)
        saveSearchHistory()
        historyTableView.reloadData()

        guard let selectedSource = UserDefaults.standard.selectedMediaSource else {
            showAlert(title: "Error", message: "No media source selected.")
            return
        }

        let url: String
        let parameters: Parameters

        switch selectedSource {
        case .animeWorld:
            url = "https://animeworld.so/search"
            parameters = ["keyword": query]
        case .monoschinos:
            url = "https://monoschinos2.com/buscar"
            parameters = ["q": query]
        case .gogoanime:
            url = "https://gogoanime3.co/search.html"
            parameters = ["keyword": query]
        case .animevietsub:
            url = "https://animevietsub.dev/tim-kiem/"
            parameters = [query: query]
        case .tioanime:
            url = "https://tioanime.com/directorio"
            parameters = ["q": query]
        case .animesaikou:
            url = "https://anime-saikou.com/"
            parameters = ["s": query]
        }

        AF.request(url, parameters: parameters).responseString { [weak self] response in
            guard let self = self else { return }

            switch response.result {
            case .success(let value):
                let results = self.parseHTML(html: value, for: selectedSource)
                self.navigateToResults(with: results)
            case .failure(let error):
                self.showAlert(title: "Error", message: "Failed to fetch data. Please try again later.")
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func parseHTML(html: String, for source: MediaSource) -> [(title: String, imageUrl: String, href: String)] {
        do {
            let document = try SwiftSoup.parse(html)
            var results: [(title: String, imageUrl: String, href: String)] = []

            switch source {
            case .animeWorld:
                let items = try document.select(".film-list .item")
                for item in items {
                    let title = try item.select("a.name").text()
                    let imageUrl = try item.select("a.poster img").attr("src")
                    let href = try item.select("a.poster").attr("href")
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .monoschinos:
                let items = try document.select("li.ficha_efecto")
                for item in items {
                    let linkElement = try item.select("a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    let imageUrl = try linkElement?.select("img").attr("data-src") ?? ""
                    let title = try linkElement?.select("h3.title_cap").text() ?? ""
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .gogoanime:
                let items = try document.select("ul.items li")
                for item in items {
                    let linkElement = try item.select("a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    let imageUrl = try linkElement?.select("img").attr("src") ?? ""
                    let title = try linkElement?.attr("title") ?? ""
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .animevietsub:
                let items = try document.select("ul.items li")
                for item in items {
                    let linkElement = try item.select("a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    let imageUrl = try linkElement?.select("img").attr("src") ?? ""
                    let title = try linkElement?.attr("title") ?? ""
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .tioanime:
                let items = try document.select("ul.animes li article.anime")

                for item in items {
                    let linkElement = try item.select("a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    var imageUrl = try linkElement?.select("img").attr("src") ?? ""
                    if !imageUrl.isEmpty && !imageUrl.hasPrefix("http") {
                        imageUrl = "https://tioanime.com\(imageUrl)"
                    }
                    let title = try linkElement?.select("h3.title").text() ?? ""
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .animesaikou:
                let items = try document.select("article.post-entry")
                for item in items {
                    let linkElement = try item.select("h2.post-title a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    let imageElement = try item.select("img").first()
                    let imageUrl = try imageElement?.attr("src") ?? ""
                    let title = try linkElement?.attr("title") ?? ""
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            }
            return results
        } catch {
            print("Error parsing HTML: \(error.localizedDescription)")
            return []
        }
    }

    func navigateToResults(with results: [(title: String, imageUrl: String, href: String)]) {
        guard let resultsVC = storyboard?.instantiateViewController(withIdentifier: "SearchResultsViewController") as? SearchResultsViewController else {
            print("Failed to instantiate SearchResultsViewController from storyboard.")
            return
        }
        resultsVC.searchResults = results
        navigationController?.pushViewController(resultsVC, animated: true)
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? HistoryTableViewCell,
              let indexPath = historyTableView.indexPath(for: cell) else {
            return
        }
        
        searchHistory.remove(at: indexPath.row)
        saveSearchHistory()
        historyTableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "SearchHistory")
    }
    
    func loadSearchHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "SearchHistory") as? [String] {
            searchHistory = savedHistory
            historyTableView.reloadData()
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else {
            return
        }
        searchMedia(query: query)
        searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryTableViewCell
        cell.textLabel?.text = searchHistory[indexPath.row]
        cell.deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedQuery = searchHistory[indexPath.row]
        searchBar.text = selectedQuery
        searchMedia(query: selectedQuery)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

class HistoryTableViewCell: UITableViewCell {
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "trash")
        button.setImage(image, for: .normal)
        button.tintColor = .systemTeal
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = UIColor.secondarySystemBackground
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textLabel!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textLabel!.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textLabel!.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -8),
        ])
    }
}
