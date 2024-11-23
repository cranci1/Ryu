//
//  AnimeUnityStreamExtractor.swift
//  Ryu
//
//  Created by Francesco on 23/11/24.
//

import Foundation
import SwiftSoup

class AnimeUnityStreamExtractor {
    static func extractVideoURL(from pageURL: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: URL(string: pageURL)!) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode HTML"])))
                return
            }
            
            do {
                let doc: Document = try SwiftSoup.parse(htmlString)
                guard let iframeElement = try doc.select("iframe").first(),
                      let iframeURL = try iframeElement.attr("src").nilIfEmpty,
                      let sourceURL = URL(string: iframeURL) else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No iframe found"])))
                    return
                }
                
                let iframeTask = URLSession.shared.dataTask(with: sourceURL) { iframeData, iframeResponse, iframeError in
                    if let iframeError = iframeError {
                        completion(.failure(iframeError))
                        return
                    }
                    
                    guard let iframeData = iframeData,
                          let iframeHTML = String(data: iframeData, encoding: .utf8) else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode iframe HTML"])))
                        return
                    }
                    
                    let pattern = "window\\.downloadUrl\\s*=\\s*'([^']+)'"
                    guard let regex = try? NSRegularExpression(pattern: pattern),
                          let match = regex.firstMatch(in: iframeHTML, range: NSRange(iframeHTML.startIndex..., in: iframeHTML)),
                          let urlRange = Range(match.range(at: 1), in: iframeHTML),
                          let videoURL = URL(string: String(iframeHTML[urlRange])) else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No download URL found"])))
                        return
                    }
                    
                    completion(.success(videoURL))
                }
                iframeTask.resume()
                
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
