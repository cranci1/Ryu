//
//  DownloadManager.swift
//  Ryu
//
//  Created by Francesco on 17/07/24.
//

import UIKit
import Foundation

class DownloadManager {
    static let shared = DownloadManager()
    
    private var activeDownloads: [String: Float] = [:]
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
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
        MP4Downloader.requestNotificationAuthorization()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "me.cranci.downloader.\(UUID().uuidString)")
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration, delegate: BackgroundSessionDelegate.shared, delegateQueue: nil)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = session.downloadTask(with: request)
        
        downloadTasks[url.absoluteString] = task
        
        let progressObserver = task.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] taskProgress, _ in
            DispatchQueue.main.async {
                self?.activeDownloads[url.absoluteString] = Float(taskProgress.fractionCompleted)
                progress(Float(taskProgress.fractionCompleted))
            }
        }
        
        var stateObserver: NSKeyValueObservation?
        stateObserver = task.observe(\.state, options: [.new]) { task, _ in
            if task.state == .completed || task.state == .canceling {
                progressObserver.invalidate()
                stateObserver?.invalidate()
            }
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
        
        BackgroundSessionDelegate.shared.downloadCompletionHandler = { [weak self] result in
            DispatchQueue.main.async {
                self?.downloadTasks.removeValue(forKey: url.absoluteString)
                self?.activeDownloads.removeValue(forKey: url.absoluteString)
                completion(result)
                MP4Downloader.handleDownloadResult(result)
            }
        }
        task.resume()
    }
    
    func cancelDownload(for title: String) {
        guard let task = downloadTasks[title] else { return }
        task.cancel()
        downloadTasks.removeValue(forKey: title)
        activeDownloads.removeValue(forKey: title)
    }
    
    func getActiveDownloads() -> [String: Float] {
        return activeDownloads
    }
}
