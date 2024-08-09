//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import UIKit
import Foundation
import UserNotifications

class MP4Downloader {
    private static var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    static func downloadFile(from urlString: String, progressHandler: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        requestNotificationAuthorization()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "me.cranci.downloader")
        configuration.waitsForConnectivity = true
        
        let session = URLSession(configuration: configuration, delegate: BackgroundSessionDelegate.shared, delegateQueue: nil)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = session.downloadTask(with: request)
        
        let progressObserver = task.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            DispatchQueue.main.async {
                progressHandler(Float(progress.fractionCompleted))
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
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        BackgroundSessionDelegate.shared.downloadCompletionHandler = { result in
            DispatchQueue.main.async {
                completion(result)
                handleDownloadResult(result)
            }
        }
        
        task.resume()
    }
    
    private static func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            } else if !granted {
                print("Notification authorization not granted")
            }
        }
    }
    
    private static func handleDownloadResult(_ result: Result<URL, Error>) {
        let content = UNMutableNotificationContent()
        switch result {
        case .success:
            content.title = "Download Complete"
            content.body = "The file has been downloaded and saved!"
            content.sound = .default
        case .failure:
            content.title = "Download Failed"
            content.body = "There was an error downloading the episode :("
            content.sound = .default
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }
    
    static func getUniqueFileURL(for fileName: String, in directory: URL) -> URL {
        let fileURL = URL(fileURLWithPath: fileName)
        let fileNameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        var newFileName = fileName
        var counter = 1
        
        var uniqueFileURL = directory.appendingPathComponent(newFileName)
        while FileManager.default.fileExists(atPath: uniqueFileURL.path) {
            counter += 1
            newFileName = "\(fileNameWithoutExtension)-\(counter).\(fileExtension)"
            uniqueFileURL = directory.appendingPathComponent(newFileName)
        }
        
        return uniqueFileURL
    }
}

class BackgroundSessionDelegate: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    static let shared = BackgroundSessionDelegate()
    var downloadCompletionHandler: ((Result<URL, Error>) -> Void)?
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            print("Session became invalid: \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download eror: \(error.localizedDescription)")
            downloadCompletionHandler?(.failure(error))
        } else {
            print("All good yay")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let originalFileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "downloadedFile.mp4"
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationFileUrl = MP4Downloader.getUniqueFileURL(for: originalFileName, in: documentsDirectoryURL)
        
        do {
            try FileManager.default.copyItem(at: location, to: destinationFileUrl)
            print("File copied to: \(destinationFileUrl.path)")
            downloadCompletionHandler?(.success(destinationFileUrl))
        } catch {
            print("Error copying file: \(error.localizedDescription)")
            downloadCompletionHandler?(.failure(error))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Task completed with error: \(error.localizedDescription)")
        }
    }
}
