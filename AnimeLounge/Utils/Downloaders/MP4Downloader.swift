//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import UIKit
import Foundation

class MP4Downloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    private var progressHandler: ((Double) -> Void)?
    private var completionHandler: ((Result<URL, Error>) -> Void)?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    static func downloadFile(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void, onProgress: @escaping (Double) -> Void) {
        let downloader = MP4Downloader()
        downloader.progressHandler = onProgress
        downloader.completionHandler = completion
        downloader.startDownload(from: urlString)
    }
    
    private func startDownload(from urlString: String) {
        guard let url = URL(string: urlString) else {
            completionHandler?(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
        
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: "me.cranci.animelounge.background")
        sessionConfig.isDiscretionary = true
        sessionConfig.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        let downloadTask = session.downloadTask(with: url)
        downloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let response = downloadTask.response,
              let url = response.url else {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
            }
            return
        }
        
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationFileUrl = documentsDirectoryURL.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationFileUrl.path) {
                try FileManager.default.removeItem(at: destinationFileUrl)
            }
            try FileManager.default.copyItem(at: location, to: destinationFileUrl)
            DispatchQueue.main.async {
                self.completionHandler?(.success(destinationFileUrl))
            }
        } catch {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
