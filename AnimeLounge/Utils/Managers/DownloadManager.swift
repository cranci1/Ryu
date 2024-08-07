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
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let downloadURLs = fileURLs.filter { $0.pathExtension.lowercased() == "mp4" }
            
            NotificationCenter.default.post(name: .downloadListUpdated, object: nil)
            
            return downloadURLs
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return []
        }
    }
    
    func startDownload(url: URL, title: String, progress: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads[url.absoluteString] = 0.0
        }
        
        MP4Downloader.shared.downloadFile(from: url.absoluteString, progressHandler: { [weak self] progressValue in
            DispatchQueue.main.async {
                self?.activeDownloads[url.absoluteString] = progressValue
                progress(progressValue)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.activeDownloads.removeValue(forKey: url.absoluteString)
                completion(result)
            }
        })
    }
    
    func getActiveDownloads() -> [String: Float] {
        return activeDownloads
    }
}
