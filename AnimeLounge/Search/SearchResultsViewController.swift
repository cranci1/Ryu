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
    
    var searchResults: [(title: String, imageUrl: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        // Register the UITableViewCell class for the reuse identifier
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "resultCell")
    }
}

extension SearchResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        let result = searchResults[indexPath.row]
        
        cell.textLabel?.text = result.title
        
        if let url = URL(string: result.imageUrl) {
            // Using Kingfisher to load and cache images
            cell.imageView?.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"), options: [.transition(.fade(0.2)), .cacheOriginalImage])
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle row selection here, e.g., navigate to detail view
        // Example:
        // let selectedResult = searchResults[indexPath.row]
        // print("Selected: \(selectedResult.title)")
    }
}
