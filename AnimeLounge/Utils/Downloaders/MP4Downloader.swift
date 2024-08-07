//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import Foundation

class MP4Downloader: NSObject, URLSessionDownloadDelegate {
    private var progressHandler: ((Float) -> Void)?
    private var completion: ((Result<URL, Error>) -> Void)?
    
    private lazy var backgroundSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "me.cranci.animelounge.background")
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    static let shared = MP4Downloader()
    
    private override init() {
        super.init()
    }
    
    func downloadFile(from urlString: String, progressHandler: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        self.progressHandler = progressHandler
        self.completion = completion
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let request = URLRequest(url: url)
        let task = backgroundSession.downloadTask(with: request)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let error = NSError(domain: "Invalid response or no data received", code: 0, userInfo: nil)
            completion?(.failure(error))
            return
        }
        
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let originalFileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "episode.mp4"
        let destinationFileUrl = Self.getUniqueFileURL(for: originalFileName, in: documentsDirectoryURL)
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationFileUrl)
            completion?(.success(destinationFileUrl))
        } catch {
            completion?(.failure(error))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion?(.failure(error))
        }
    }
    
    private static func getUniqueFileURL(for fileName: String, in directory: URL) -> URL {
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
