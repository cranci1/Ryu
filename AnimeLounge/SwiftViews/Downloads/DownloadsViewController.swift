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
        let table = UITableView()
        table.backgroundColor = .secondarySystemBackground
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var downloads: [URL] = []
    private let downloadManager = DownloadManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
        setupTableView()
        loadDownloads()
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
    
    private func loadDownloads() {
        downloads = downloadManager.fetchDownloadURLs()
        tableView.reloadData()
    }
    
    private func playDownload(url: URL) {
        guard url.pathExtension.lowercased() == "mp4" else {
            print("Error: File is not an supported yet.")
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
        cell.titleLabel.text = download.lastPathComponent
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: download.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            cell.fileSizeLabel.text = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } catch {
            print("Error getting file size: \(error.localizedDescription)")
            cell.fileSizeLabel.text = "Unknown size"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let download = downloads[indexPath.row]
        playDownload(url: download)
    }
}

class DownloadManager {
    
    func fetchDownloadURLs() -> [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "mpeg" || $0.pathExtension == "mp4" }
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return []
        }
    }
}
