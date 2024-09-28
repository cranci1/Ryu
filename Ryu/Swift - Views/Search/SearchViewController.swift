//
//  SearchViewController.swift
//  Ryu
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSearchHistory()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func searchMedia(query: String) {
        if let index = searchHistory.firstIndex(of: query) {
            searchHistory.remove(at: index)
        }
        searchHistory.insert(query, at: 0)
        saveSearchHistory()
        historyTableView.reloadData()
        
        let resultsVC = SearchResultsViewController()
        resultsVC.query = query
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
        } else {
            searchHistory = []
        }
        historyTableView.reloadData()
    }
    
    @IBAction func selectSourceButtonTapped(_ sender: UIButton) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let alertController = UIAlertController(title: "Change Source",  message: "Please change the source via Settings.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            SourceMenu.showSourceSelector(from: self, sourceView: sender)
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
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
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
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
        
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
