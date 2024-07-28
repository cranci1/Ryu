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
            let downloadURLs = fileURLs.filter { $0.pathExtension.lowercased() == "mpeg" || $0.pathExtension.lowercased() == "mp4" }
            
            NotificationCenter.default.post(name: .downloadListUpdated, object: nil)
            
            return downloadURLs
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return []
        }
    }
}
