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
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let downloadURLs = fileURLs.filter { $0.pathExtension == "mpeg" || $0.pathExtension == "mp4" }
            
            NotificationCenter.default.post(name: .downloadListUpdated, object: nil)
            
            return downloadURLs
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return []
        }
    }
}
