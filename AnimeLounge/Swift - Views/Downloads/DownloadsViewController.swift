//
//  DownloadsViewController.swift
//  AnimeLounge
//
//  Created by Francesco on 16/07/24.
//

import UIKit
import AVKit
import AVFoundation

class DownloadListViewController: UIViewController {
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .singleLine
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var downloads: [URL] = []
    private let downloadManager = DownloadManager()
    private let refreshControl = UIRefreshControl()
    
    private let emptyMessages = [
        "Looks like a black hole has been here! No downloads found. Maybe they've been sucked into oblivion?",
        "Nothing to see here! All downloads have mysteriously vanished.",
        "The download list is emptier than space itself.",
        "No downloads available. Did Thanos snap them away?",
        "Oops, it's all gone! Like a magician's trick, the downloads disappeared!",
        "No downloads. Perhaps they're hiding from us?",
        "Looks like the downloads took a vacation. Check back later!",
        "Downloads? What downloads? It's all an illusion!",
        "Looks like the downloads decided to play hide and seek!",
        "No downloads available. It’s like they’ve gone off to a secret party.",
        "Nothing here. Maybe the downloads are waiting for a dramatic entrance."
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        setupTableView()
        setupEmptyStateLabel()
        loadDownloads()
        setupNavigationBar()
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        loadDownloads()
        refreshControl.endRefreshing()
    }
    
    private func setupNavigationBar() {
        let filesButton = UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: self, action: #selector(openInFilesApp))
        navigationItem.rightBarButtonItem = filesButton
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .secondarySystemBackground
        tableView.register(DownloadCell.self, forCellReuseIdentifier: "DownloadCell")
        
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
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: -150)
        ])
    }
    
    @objc private func openInFilesApp() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access Documents directory")
            return
        }
        
        let downloadsURL = documentsURL.appendingPathComponent("Downloads")
        let urlString = downloadsURL.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Failed to open Files app")
                }
            }
        } else {
            print("Cannot open Files app")
        }
    }
    
    private func loadDownloads() {
        downloads = downloadManager.fetchDownloadURLs().sorted { (url1, url2) -> Bool in
            return url1.lastPathComponent.localizedStandardCompare(url2.lastPathComponent) == .orderedAscending
        }
        tableView.reloadData()
        emptyStateLabel.isHidden = !downloads.isEmpty
        
        if downloads.isEmpty {
            emptyStateLabel.text = emptyMessages.randomElement()
        }
    }
    
    private func playDownload(url: URL) {
        guard url.pathExtension.lowercased() == "mp4" else {
            print("Error: File is not supported yet.")
            return
        }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let player = AVPlayer(playerItem: playerItem)
        print("\(url)")
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    private func deleteDownload(at indexPath: IndexPath) {
        let download = downloads[indexPath.row]
        do {
            try FileManager.default.removeItem(at: download)
            downloads.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            loadDownloads()
            
            NotificationCenter.default.post(name: .downloadListUpdated, object: nil)
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
    }
}

extension DownloadListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell", for: indexPath) as? DownloadCell else {
            return UITableViewCell()
        }
        
        let download = downloads[indexPath.row]
        cell.titleLabel.text = (download.lastPathComponent as NSString).deletingPathExtension
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: download.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            cell.fileSizeLabel.text = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } catch {
            print("Error getting file size: \(error.localizedDescription)")
            cell.fileSizeLabel.text = "Unknown size"
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let download = downloads[indexPath.row]
        playDownload(url: download)
    }
}

extension DownloadListViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let locationInTableView = interaction.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: locationInTableView) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteDownload(at: indexPath)
            }
            
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                self.renameDownload(at: indexPath)
            }
            
            return UIMenu(title: "", children: [renameAction, deleteAction])
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        return UITargetedPreview(view: cell)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        return UITargetedPreview(view: cell)
    }
    
    private func renameDownload(at indexPath: IndexPath) {
        let download = downloads[indexPath.row]
        let alertController = UIAlertController(title: "Rename File", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = (download.lastPathComponent as NSString).deletingPathExtension
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newName = alertController.textFields?.first?.text,
                  !newName.isEmpty,
                  let self = self else { return }
            
            let fileExtension = download.pathExtension
            let newURL = download.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(fileExtension)
            
            do {
                try FileManager.default.moveItem(at: download, to: newURL)
                self.downloads[indexPath.row] = newURL
                self.loadDownloads()
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            } catch {
                print("Error renaming file: \(error.localizedDescription)")
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(renameAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
