//
//  DownloadManager.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import Foundation

extension Notification.Name {
    static let downloadListUpdated = Notification.Name("DownloadListUpdated")
}

class DownloadManager {
    static let shared = DownloadManager()
    
    private var activeDownloads: [String: Float] = [:]
    
    func fetchDownloadURLs() -> [URL] {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access Documents directory")
            return []
        }
        
        let downloadsURL = documentsURL.appendingPathComponent("Downloads")
        
        do {
            if !fileManager.fileExists(atPath: downloadsURL.path) {
                try fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let fileURLs = try fileManager.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil)
            let downloadURLs = fileURLs.filter { $0.pathExtension.lowercased() == "mp4" }
            
            NotificationCenter.default.post(name: .downloadListUpdated, object: nil)
            
            return downloadURLs
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return []
        }
    }
    
    func startDownload(url: URL, title: String, progress: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        MP4Downloader.downloadFile(from: url.absoluteString, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.activeDownloads.removeValue(forKey: url.absoluteString)
                completion(result)
            }
        }, onProgress: { [weak self] progressValue in
            DispatchQueue.main.async {
                self?.activeDownloads[url.absoluteString] = Float(progressValue)
                progress(Float(progressValue))
            }
        })
    }
    
    func getActiveDownloads() -> [(title: String, progress: Float)] {
        return activeDownloads.map { (title: $0.key, progress: $0.value) }
    }
}
