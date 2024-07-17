//
//  DownloadManager.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import UIKit

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

