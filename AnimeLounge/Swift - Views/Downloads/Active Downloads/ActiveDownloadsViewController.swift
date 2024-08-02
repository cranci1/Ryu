//
//  ActiveDownloadsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 01/08/24.
//

import UIKit

class ActiveDownloadsViewController: UIViewController {

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var downloads: [(title: String, progress: Float)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        tableView.backgroundColor = .secondarySystemBackground
        
        setupTableView()
        loadDownloads()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProgressDownloadCell.self, forCellReuseIdentifier: "ProgressDownloadCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadDownloads() {
        downloads = DownloadManager.shared.getActiveDownloads()
        tableView.reloadData()
    }
    
    func addProgressCell(_ cell: ProgressDownloadCell) {
    }
    
    func removeProgressCell(_ cell: ProgressDownloadCell) {
        loadDownloads()
    }
}

extension ActiveDownloadsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressDownloadCell", for: indexPath) as? ProgressDownloadCell else {
            return UITableViewCell()
        }
        
        let download = downloads[indexPath.row]
        let progressText = String(format: "%.0f%%", download.progress * 100)
        cell.configure(with: download.title, progress: download.progress, progressText: progressText)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}
