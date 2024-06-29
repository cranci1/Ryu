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
        var parameters: Parameters = [:]

        switch selectedSource {
        case .animeWorld:
            url = "https://animeworld.so/search"
            parameters = ["keyword": query]
        case .gogoanime:
            url = "https://anitaku.pe/search.html"
            parameters = ["keyword": query]
        case .animeheaven:
            url = "https://animeheaven.me/search.php"
            parameters = ["s": query]
        case .animefire:
            let lowercaseQuery = query.lowercased()
            let encodedQuery = lowercaseQuery.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? lowercaseQuery
            url = "https://animefire.plus/pesquisar/\(encodedQuery)"
        case .kuramanime:
            url = "https://kuramanime.boo/anime"
            parameters = ["search": query]
        case .latanime:
            url = "https://latanime.org/buscar"
            parameters = ["q": query]
        }

        print("Completed URL: \(url)")

        AF.request(url, method: .get, parameters: parameters).responseString { [weak self] response in
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
            case .gogoanime:
                let items = try document.select("ul.items li")
                for item in items {
                    let linkElement = try item.select("a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    let imageUrl = try linkElement?.select("img").attr("src") ?? ""
                    let title = try linkElement?.attr("title") ?? ""
                    print("\(href)")
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .animeheaven:
                let items = try document.select("div.info3.bc1 div.similarimg")
                for item in items {
                    let linkElement = try item.select("a").first()
                    let href = try linkElement?.attr("href") ?? ""
                    var imageUrl = try linkElement?.select("img").attr("src") ?? ""
                    if !imageUrl.isEmpty && !imageUrl.hasPrefix("http") {
                        imageUrl = "https://animeheaven.me/\(imageUrl)"
                    }
                    let title = try item.select("div.similarname a.c").text()
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .animefire:
                let items = try document.select("div.card-group div.row div.divCardUltimosEps")
                for item in items {
                    let title = try item.select("div.text-block h3.animeTitle").first()?.text() ?? ""
                    let imageUrl = try item.select("article.card a img").first()?.attr("data-src") ?? ""
                    let href = try item.select("article.card a").first()?.attr("href") ?? ""
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .kuramanime:
                let items = try document.select("div#animeList div.col-lg-4")
                for item in items {
                    let title = try item.select("div.product__item__text h5 a").text()
                    let imageUrl = try item.select("div.product__item__pic").attr("data-setbg")
                    let href = try item.select("div.product__item a").attr("href")
                    results.append((title: title, imageUrl: imageUrl, href: href))
                }
            case .latanime:
                let items = try document.select("div.row div.col-md-4")
                for item in items {
                    let title = try item.select("div.series div.seriedetails h3.my-1").text()
                    let imageUrl = try item.select("div.series div.serieimg img").attr("src")
                    let href = try item.select("a").attr("href")
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
    
    @IBAction func selectSourceButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Select Source", message: "Choose your preferred source for AnimeLounge.", preferredStyle: .actionSheet)
        
        let worldAction = UIAlertAction(title: "AnimeWorld", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animeWorld
        }
        setUntintedImage(for: worldAction, named: "AnimeWorld")
        
        let gogoAction = UIAlertAction(title: "GoGoAnime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .gogoanime
        }
        setUntintedImage(for: gogoAction, named: "GoGoAnime")
        
        let heavenAction = UIAlertAction(title: "AnimeHeaven", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animeheaven
        }
        setUntintedImage(for: heavenAction, named: "AnimeHeaven")
        
        let fireAction = UIAlertAction(title: "AnimeFire", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .animefire
        }
        setUntintedImage(for: fireAction, named: "AnimeFire")
        
        let kuraAction = UIAlertAction(title: "Kuramanime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .kuramanime
        }
        setUntintedImage(for: kuraAction, named: "Kuramanime")
        
        let latAction = UIAlertAction(title: "Latanime", style: .default) { _ in
            UserDefaults.standard.selectedMediaSource = .latanime
        }
        setUntintedImage(for: latAction, named: "Latanime")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(worldAction)
        alertController.addAction(gogoAction)
        alertController.addAction(heavenAction)
        alertController.addAction(fireAction)
        alertController.addAction(kuraAction)
        alertController.addAction(latAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func setUntintedImage(for action: UIAlertAction, named imageName: String) {
        if let originalImage = UIImage(named: imageName) {
            let resizedImage = resizeImage(originalImage, targetSize: CGSize(width: 35, height: 35))
            if let untintedImage = resizedImage?.withRenderingMode(.alwaysOriginal) {
                action.setValue(untintedImage, forKey: "image")
            }
        }
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
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
