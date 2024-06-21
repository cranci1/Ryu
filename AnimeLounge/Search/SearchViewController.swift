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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
    }
    
    func searchMedia(query: String) {
        let url = "https://animeworld.so/search"
        let parameters: Parameters = ["keyword": query]
        
        AF.request(url, parameters: parameters).responseString { [weak self] response in
            guard let self = self else { return }
            
            switch response.result {
            case .success(let value):
                let results = self.parseHTML(html: value)
                self.navigateToResults(with: results)
            case .failure(let error):
                print("Error: \(error)")
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error", message: "Failed to fetch data. Please try again later.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func parseHTML(html: String) -> [(title: String, imageUrl: String)] {
        do {
            let document = try SwiftSoup.parse(html)
            let items = try document.select(".film-list .item")
            var results: [(title: String, imageUrl: String)] = []
            for item in items {
                let title = try item.select("a.name").text()
                let imageUrl = try item.select("a.poster img").attr("src")
                results.append((title: title, imageUrl: imageUrl))
            }
            return results
        } catch {
            print("Error parsing HTML: \(error)")
            return []
        }
    }

    func navigateToResults(with results: [(title: String, imageUrl: String)]) {
        guard let resultsVC = storyboard?.instantiateViewController(withIdentifier: "SearchResultsViewController") as? SearchResultsViewController else {
            print("Failed to instantiate SearchResultsViewController from storyboard.")
            return
        }
        resultsVC.searchResults = results
        navigationController?.pushViewController(resultsVC, animated: true)
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
