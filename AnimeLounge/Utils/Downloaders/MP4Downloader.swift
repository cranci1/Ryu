//
//  MP4Downloader.swift
//  AnimeLounge
//
//  Created by Francesco on 17/07/24.
//

import Foundation

class MP4Downloader {
    static func downloadFile(from urlString: String, progressHandler: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempLocalUrl = tempLocalUrl,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "Invalid response or no data received", code: 0, userInfo: nil)))
                return
            }
            
            let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let originalFileName = url.lastPathComponent
            let destinationFileUrl = Self.getUniqueFileURL(for: originalFileName, in: documentsDirectoryURL)
            
            do {
                try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                completion(.success(destinationFileUrl))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
        
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
