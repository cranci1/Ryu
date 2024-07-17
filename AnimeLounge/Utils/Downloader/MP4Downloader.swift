//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import Foundation

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
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
    }
}

extension MP4Downloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        do {
            try fileManager.moveItem(at: location, to: destinationUrl)
            DispatchQueue.main.async {
                self.completionHandler?(.success(destinationUrl))
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
}
