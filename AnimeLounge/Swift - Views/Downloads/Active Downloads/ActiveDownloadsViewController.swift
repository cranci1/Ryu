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
        table.backgroundColor = .secondarySystemBackground
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var downloads: [(title: String, progress: Float)] = []
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No active downloads, you can start one if you click the button on the right of each episode."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        setupTableView()
        setupEmptyStateLabel()
        loadDownloads()
        startProgressUpdateTimer()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.backgroundColor = .secondarySystemBackground
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
    
    private func setupEmptyStateLabel() {
        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadDownloads() {
        downloads = DownloadManager.shared.getActiveDownloads()
        tableView.reloadData()
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !downloads.isEmpty
        tableView.isHidden = downloads.isEmpty
    }
    
    private func startProgressUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        downloads = DownloadManager.shared.getActiveDownloads()
        for (index, download) in downloads.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProgressDownloadCell {
                let progressText = String(format: "%.0f%%", download.progress * 100)
                cell.configure(with: download.title, progress: download.progress, progressText: progressText)
            }
        }
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}
