//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import UIKit
import Foundation
import UserNotifications

class MP4Downloader: NSObject, URLSessionDownloadDelegate {
    private var downloadTask: URLSessionDownloadTask?
    private var backgroundSession: URLSession!
    private let downloadURL: URL
    private var progressHandler: ((Float) -> Void)?
    private var completionHandler: ((Result<Void, Error>) -> Void)?
    private var sessionCompletionHandler: (() -> Void)?
    
    init(url: URL) {
        self.downloadURL = url
        super.init()
        
        let config = URLSessionConfiguration.background(withIdentifier: "me.cranci.animelounge.background")
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func startDownload(progress: @escaping (Float) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        self.progressHandler = progress
        self.completionHandler = completion
        downloadTask = backgroundSession.downloadTask(with: downloadURL)
        downloadTask?.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try createFile(from: location, for: downloadTask)
            print("File saved successfully")
            sendSuccessNotification()
            completionHandler?(.success(()))
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            sendErrorNotification(error: error)
            completionHandler?(.failure(error))
        }
    }
    
    private func createFile(from location: URL, for task: URLSessionDownloadTask) throws {
        let fileManager = FileManager.default
        
        let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let downloadsURL = documentsURL.appendingPathComponent("Downloads", isDirectory: true)
        
        try fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
        
        let destinationURL = downloadsURL.appendingPathComponent(task.originalRequest?.url?.lastPathComponent ?? "downloadedAnimeVideo.mp4")
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: location, to: destinationURL)
        
        print("File saved successfully at: \(destinationURL.path)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed with error: \(error.localizedDescription)")
            sendErrorNotification(error: error)
            completionHandler?(.failure(error))
        } else {
            print("Download completed successfully")
        }
    }
    
    func sendSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "Your Episode has been downloaded. You can find it in Library -> Downloads"
        content.sound = .default
        
        sendNotification(content: content)
    }
    
    func sendErrorNotification(error: Error) {
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "An error occurred: \(error.localizedDescription)"
        content.sound = .default
        
        sendNotification(content: content)
    }
    
    private func sendNotification(content: UNMutableNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.sessionCompletionHandler = completionHandler
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let completionHandler = sessionCompletionHandler {
            completionHandler()
        }
    }
}