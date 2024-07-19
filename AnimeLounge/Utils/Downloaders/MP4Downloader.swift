//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import UIKit
import Foundation
import UserNotifications

class MP4Downloader: NSObject {
    typealias ProgressHandler = (Float) -> Void
    typealias CompletionHandler = (Result<URL, Error>) -> Void
    
    private var url: URL
    private var progressHandler: ProgressHandler?
    private var completionHandler: CompletionHandler?
    private var downloadTask: URLSessionDownloadTask?
    
    init(url: URL) {
        self.url = url
    }
    
    func startDownload(progress: ProgressHandler? = nil, completion: @escaping CompletionHandler) {
        self.progressHandler = progress
        self.completionHandler = completion
        
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: "me.cranci.animelounge.background")
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "Your Episode has been downloaded. You can find it in Library -> Downloads"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
}

extension MP4Downloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        do {
            let tempUrl = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try fileManager.moveItem(at: location, to: tempUrl)
            try fileManager.moveItem(at: tempUrl, to: destinationUrl)
            DispatchQueue.main.async {
                self.completionHandler?(.success(destinationUrl))
                
                if UserDefaults.standard.bool(forKey: "notificationOnDownload") {
                    self.sendNotification()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let backgroundCompletionHandler = appDelegate.backgroundCompletionHandler {
                backgroundCompletionHandler()
                appDelegate.backgroundCompletionHandler = nil
            }
        }
    }
}
