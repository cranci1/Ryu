//
//  AnimeDetailsMethods.swift
//  Ryu
//
//  Created by Francesco on 19/09/24.
//

import UIKit
import SwiftSoup

extension AnimeDetailViewController {
    func selectAudioCategory(options: [String: [[String: Any]]], preferredAudio: String, completion: @escaping (String) -> Void) {
        if let audioOptions = options[preferredAudio], !audioOptions.isEmpty {
            completion(preferredAudio)
        } else {
            DispatchQueue.main.async {
                self.presentDubSubRawSelection(options: options, preferredType: preferredAudio, completion: completion)
            }
        }
    }
    
    func selectServer(servers: [[String: Any]], preferredServer: String, completion: @escaping (String) -> Void) {
        if let server = servers.first(where: { ($0["serverName"] as? String) == preferredServer }) {
            completion(server["serverName"] as? String ?? "")
        } else {
            DispatchQueue.main.async {
                self.presentServerSelection(servers: servers, completion: completion)
            }
        }
    }
    
    func selectSubtitles(captionURLs: [String: URL]?, completion: @escaping (URL?) -> Void) {
        guard let captionURLs = captionURLs, !captionURLs.isEmpty else {
            completion(nil)
            return
        }
        
        if let preferredSubtitles = UserDefaults.standard.string(forKey: "subtitleHiPrefe"),
           let preferredURL = captionURLs[preferredSubtitles] {
            completion(preferredURL)
        } else {
            DispatchQueue.main.async {
                self.presentSubtitleSelection(captionURLs: captionURLs, completion: completion)
            }
        }
    }
    
    func presentSubtitleSelection(captionURLs: [String: URL], completion: @escaping (URL?) -> Void) {
        let alert = UIAlertController(title: "Select Subtitle Language", message: nil, preferredStyle: .actionSheet)
        
        for (label, url) in captionURLs {
            alert.addAction(UIAlertAction(title: label, style: .default) { _ in
                completion(url)
            })
        }
        
        alert.addAction(UIAlertAction(title: "No Subtitles", style: .default) { _ in
            completion(nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let topController = scene.windows.first?.rootViewController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                alert.modalPresentationStyle = .popover
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = topController.view
                    popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
            }
            topController.present(alert, animated: true, completion: nil)
        }
    }
    
    func extractEpisodeId(from url: String) -> String? {
        let components = url.components(separatedBy: "?id=")
        guard components.count >= 2 else { return nil }
        let episodeId = components[1].components(separatedBy: "&").first
        guard let ep = components.last else { return nil }
        
        return episodeId.flatMap { "\($0)?\(ep)" }
    }
    
    func fetchEpisodeOptions(episodeId: String, completion: @escaping ([String: [[String: Any]]]) -> Void) {
        let urls = [
            "https://aniwatch-api-dusky.vercel.app/anime/servers?episodeId=",
            "https://aniwatch-api-cranci.vercel.app/anime/servers?episodeId="
        ]
        
        let randomURL = urls.randomElement()!
        let fullURL = URL(string: "\(randomURL)\(episodeId)")!
        
        URLSession.shared.dataTask(with: fullURL) { data, response, error in
            guard let data = data else {
                print("Error fetching episode options: \(error?.localizedDescription ?? "Unknown error")")
                completion([:])
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let raw = json["raw"] as? [[String: Any]],
                   let sub = json["sub"] as? [[String: Any]],
                   let dub = json["dub"] as? [[String: Any]] {
                    completion(["raw": raw, "sub": sub, "dub": dub])
                } else {
                    completion([:])
                }
            } catch {
                print("Error parsing episode options: \(error.localizedDescription)")
                completion([:])
            }
        }.resume()
    }
    
    func presentDubSubRawSelection(options: [String: [[String: Any]]], preferredType: String, completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            let rawOptions = options["raw"]
            let subOptions = options["sub"]
            let dubOptions = options["dub"]
            
            let availableOptions = [
                "raw": rawOptions,
                "sub": subOptions,
                "dub": dubOptions
            ].filter { $0.value != nil && !($0.value!.isEmpty) }
            
            if availableOptions.isEmpty {
                print("No audio options available")
                self.showAlert(title: "Error", message: "No audio options available")
                return
            }
            
            if availableOptions.count == 1, let onlyOption = availableOptions.first {
                completion(onlyOption.key)
                return
            }
            
            if availableOptions[preferredType] != nil {
                
                completion(preferredType)
                return
            }
            
            let alert = UIAlertController(title: "Select Audio", message: nil, preferredStyle: .actionSheet)
            
            for (type, _) in availableOptions {
                let title = type.capitalized
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                    completion(type)
                })
            }
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let topController = scene.windows.first?.rootViewController {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alert.modalPresentationStyle = .popover
                    if let popover = alert.popoverPresentationController {
                        popover.sourceView = topController.view
                        popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                }
                topController.present(alert, animated: true, completion: nil)
            } else {
                print("Could not find top view controller to present alert")
            }
        }
    }
    
    func presentServerSelection(servers: [[String: Any]], completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Select Server", message: nil, preferredStyle: .actionSheet)
        
        for server in servers {
            if let serverName = server["serverName"] as? String,
               serverName != "streamtape" && serverName != "streamsb" {
                alert.addAction(UIAlertAction(title: serverName, style: .default) { _ in
                    completion(serverName)
                })
            }
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let topController = scene.windows.first?.rootViewController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                alert.modalPresentationStyle = .popover
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = topController.view
                    popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
            }
            topController.present(alert, animated: true, completion: nil)
        }
    }
    
    func fetchHiAnimeData(from fullURL: String, completion: @escaping (URL?, [String: URL]?) -> Void) {
        guard let url = URL(string: fullURL) else {
            print("Invalid URL for HiAnime: \(fullURL)")
            completion(nil, nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching HiAnime data: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
            
            guard let data = data else {
                print("Error: No data received from HiAnime")
                completion(nil, nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var captionURLs: [String: URL] = [:]
                    
                    if let tracks = json["tracks"] as? [[String: Any]] {
                        for track in tracks {
                            if let file = track["file"] as? String, let label = track["label"] as? String, track["kind"] as? String == "captions" {
                                captionURLs[label] = URL(string: file)
                            }
                        }
                    }
                    
                    var sourceURL: URL?
                    if let sources = json["sources"] as? [[String: Any]] {
                        if let source = sources.first, let urlString = source["url"] as? String {
                            sourceURL = URL(string: urlString)
                        }
                    }
                    
                    completion(sourceURL, captionURLs)
                }
            } catch {
                print("Error parsing HiAnime JSON: \(error.localizedDescription)")
                completion(nil, nil)
            }
        }.resume()
    }
    
    func fetchHTMLContent(from url: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "Invalid data", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(htmlString))
        }.resume()
    }
    
    func extractVideoSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let videoElement = try doc.select("video").first(),
                  let sourceElement = try videoElement.select("source").first(),
                  let sourceURLString = try sourceElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                      return nil
                  }
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            
            let mp4Pattern = #"<source src="(.*?)" type="video/mp4">"#
            let m3u8Pattern = #"<source src="(.*?)" type="application/x-mpegURL">"#
            
            if let mp4URL = extractURL(from: htmlString, pattern: mp4Pattern) {
                return mp4URL
            } else if let m3u8URL = extractURL(from: htmlString, pattern: m3u8Pattern) {
                return m3u8URL
            }
            return nil
        }
    }
    
    func extractURL(from htmlString: String, pattern: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let urlRange = Range(match.range(at: 1), in: htmlString) else {
                  return nil
              }
        
        let urlString = String(htmlString[urlRange])
        return URL(string: urlString)
    }
    
    func extractIframeSourceURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let iframeElement = try doc.select("iframe").first(),
                  let sourceURLString = try iframeElement.attr("src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                      return nil
                  }
            print("Iframe src URL: \(sourceURL.absoluteString)")
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    func extractDataVideoSrcURL(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let element = try doc.select("[data-video-src]").first(),
                  let sourceURLString = try element.attr("data-video-src").nilIfEmpty,
                  let sourceURL = URL(string: sourceURLString) else {
                      return nil
                  }
            print("Data-video-src URL: \(sourceURL.absoluteString)")
            return sourceURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    func extractDownloadLink(from htmlString: String) -> URL? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            guard let downloadElement = try doc.select("li.dowloads a").first(),
                  let hrefString = try downloadElement.attr("href").nilIfEmpty,
                  let downloadURL = URL(string: hrefString) else {
                      return nil
                  }
            print("Download link URL: \(downloadURL.absoluteString)")
            return downloadURL
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    func fetchVideoDataAndChooseQuality(from urlString: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL string")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(String(describing: error))")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let videoDataArray = json["data"] as? [[String: Any]] {
                    
                    self.availableQualities.removeAll()
                    
                    for videoData in videoDataArray {
                        if let label = videoData["label"] as? String {
                            self.availableQualities.append(label)
                        }
                    }
                    
                    if self.availableQualities.isEmpty {
                        print("No available video qualities found")
                        completion(nil)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.choosePreferredQuality(availableQualities: self.availableQualities, videoDataArray: videoDataArray, completion: completion)
                    }
                    
                } else {
                    print("JSON structure is invalid or data key is missing")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func choosePreferredQuality(availableQualities: [String], videoDataArray: [[String: Any]], completion: @escaping (URL?) -> Void) {
        let preferredQuality = UserDefaults.standard.string(forKey: "preferredQuality") ?? "1080p"
        
        var selectedQuality: String? = nil
        var closestQuality: String? = nil
        
        for quality in availableQualities {
            if quality == preferredQuality {
                selectedQuality = quality
                break
            } else if closestQuality == nil || abs(preferredQuality.compare(quality).rawValue) < abs(preferredQuality.compare(closestQuality!).rawValue) {
                closestQuality = quality
            }
        }
        
        let finalSelectedQuality = selectedQuality ?? closestQuality
        
        if let finalQuality = finalSelectedQuality,
           let selectedVideoData = videoDataArray.first(where: { $0["label"] as? String == finalQuality }),
           let selectedURLString = selectedVideoData["src"] as? String,
           let selectedURL = URL(string: selectedURLString) {
            completion(selectedURL)
        } else {
            print("No suitable quality option found")
            completion(nil)
        }
    }
    
    func showQualityPicker(qualities: [String], completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Choose Video Quality", message: nil, preferredStyle: .actionSheet)
        
        for quality in qualities {
            let action = UIAlertAction(title: quality, style: .default) { _ in
                completion(quality)
            }
            alertController.addAction(action)
        }
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
