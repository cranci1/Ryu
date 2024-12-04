//
//  AnimeDetailsMethods.swift
//  Ryu
//
//  Created by Francesco on 19/09/24.
//

import UIKit
import SwiftSoup
import MobileCoreServices
import UniformTypeIdentifiers

extension AnimeDetailViewController {
    func selectAudioCategory(options: [String: [[String: Any]]], preferredAudio: String, completion: @escaping (String) -> Void) {
        if let audioOptions = options[preferredAudio], !audioOptions.isEmpty {
            completion(preferredAudio)
        } else {
            hideLoadingBanner {
                DispatchQueue.main.async {
                    self.presentDubSubRawSelection(options: options, preferredType: preferredAudio) { selectedCategory in
                        self.showLoadingBanner()
                        completion(selectedCategory)
                    }
                }
            }
        }
    }
    
    func selectServer(servers: [[String: Any]], preferredServer: String, completion: @escaping (String) -> Void) {
        if let server = servers.first(where: { ($0["serverName"] as? String) == preferredServer }) {
            completion(server["serverName"] as? String ?? "")
        } else {
            hideLoadingBanner {
                DispatchQueue.main.async {
                    self.presentServerSelection(servers: servers) { selectedServer in
                        self.showLoadingBanner()
                        completion(selectedServer)
                    }
                }
            }
        }
    }
    
    func selectSubtitles(captionURLs: [String: URL]?, completion: @escaping (URL?) -> Void) {
        guard let captionURLs = captionURLs, !captionURLs.isEmpty else {
            completion(nil)
            return
        }
        
        if let preferredSubtitles = UserDefaults.standard.string(forKey: "subtitleHiPrefe") {
            if preferredSubtitles == "No Subtitles" {
                completion(nil)
                return
            }
            if preferredSubtitles == "Always Import" {
                self.hideLoadingBanner {
                    self.importSubtitlesFromURL(completion: completion)
                }
                return
            }
            if let preferredURL = captionURLs[preferredSubtitles] {
                completion(preferredURL)
                return
            }
        }
        
        hideLoadingBanner {
            DispatchQueue.main.async {
                self.presentSubtitleSelection(captionURLs: captionURLs, completion: completion)
            }
        }
    }
    
    func presentSubtitleSelection(captionURLs: [String: URL], completion: @escaping (URL?) -> Void) {
        let alert = UIAlertController(title: "Select Subtitle Source", message: nil, preferredStyle: .actionSheet)
        
        
        for (label, url) in captionURLs {
            alert.addAction(UIAlertAction(title: label, style: .default) { _ in
                completion(url)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Import from a URL...", style: .default) { [weak self] _ in
            self?.importSubtitlesFromURL(completion: completion)
        })
        
        alert.addAction(UIAlertAction(title: "No Subtitles", style: .default) { _ in
            completion(nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        presentAlert(alert)
    }
    
    private func importSubtitlesFromURL(completion: @escaping (URL?) -> Void) {
        let alert = UIAlertController(title: "Enter Subtitle URL", message: "Enter the URL of the subtitle file (.srt, .ass, or .vtt)", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "https://example.com/subtitles.srt"
            textField.keyboardType = .URL
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Import", style: .default) { [weak alert] _ in
            guard let urlString = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let url = URL(string: urlString),
                  let fileExtension = url.pathExtension.lowercased() as String?,
                  ["srt", "ass", "vtt"].contains(fileExtension) else {
                      self.showAlert(title: "Error", message: "Invalid subtitle URL. Must end with .srt, .ass, or .vtt")
                      completion(nil)
                      return
                  }
            
            self.downloadSubtitles(from: url, completion: completion)
        })
        
        presentAlert(alert)
    }
    
    private func downloadSubtitles(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL,
                  error == nil,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                      DispatchQueue.main.async {
                          self.showAlert(title: "Error", message: "Failed to download subtitles")
                          completion(nil)
                      }
                      return
                  }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: tempURL)
                DispatchQueue.main.async {
                    completion(tempURL)
                }
            } catch {
                print("Error moving downloaded file: \(error)")
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to save subtitles")
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    private func presentAlert(_ alert: UIAlertController) {
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
            topController.present(alert, animated: true)
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
            let realSourceURL = "https:\(sourceURL)"
            print("Iframe src URL: \(realSourceURL)")
            return URL(string: realSourceURL)
        } catch {
            print("Error parsing HTML with SwiftSoup: \(error)")
            return nil
        }
    }
    
    func extractEmbedUrl(from rawHtml: String, completion: @escaping (URL?) -> Void) {
        if let startIndex = rawHtml.range(of: "<video-player")?.upperBound,
           let endIndex = rawHtml.range(of: "</video-player>")?.lowerBound {
            
            let videoPlayerContent = String(rawHtml[startIndex..<endIndex])
            
            if let embedUrlStart = videoPlayerContent.range(of: "embed_url=\"")?.upperBound,
               let embedUrlEnd = videoPlayerContent[embedUrlStart...].range(of: "\"")?.lowerBound {
                
                var embedUrl = String(videoPlayerContent[embedUrlStart..<embedUrlEnd])
                embedUrl = embedUrl.replacingOccurrences(of: "amp;", with: "")
                
                extractWindowUrl(from: embedUrl) { finalUrl in
                    completion(finalUrl)
                }
                return
            }
        }
        completion(nil)
    }

    private func extractWindowUrl(from urlString: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let pageContent = String(data: data, encoding: .utf8) else {
                      DispatchQueue.main.async {
                          completion(nil)
                      }
                      return
                  }
            
            let downloadUrlPattern = #"window\.downloadUrl\s*=\s*['"]([^'"]+)['"]"#
            
            guard let regex = try? NSRegularExpression(pattern: downloadUrlPattern, options: []) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let range = NSRange(pageContent.startIndex..<pageContent.endIndex, in: pageContent)
            guard let match = regex.firstMatch(in: pageContent, options: [], range: range),
                  let urlRange = Range(match.range(at: 1), in: pageContent) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let downloadUrlString = String(pageContent[urlRange])
            let cleanedUrlString = downloadUrlString.replacingOccurrences(of: "amp;", with: "")
            
            guard let downloadUrl = URL(string: cleanedUrlString) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(downloadUrl)
            }
        }.resume()
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
    
    func extractTokyoVideo(from htmlString: String, completion: @escaping (URL) -> Void) {
        let formats = UserDefaults.standard.bool(forKey: "otherFormats") ? ["mp4", "mkv", "avi"] : ["mp4"]
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let doc = try SwiftSoup.parse(htmlString)
                let combinedSelector = formats.map { "a[href*=media.tokyoinsider.com][href$=.\($0)]" }.joined(separator: ", ")
                
                let downloadElements = try doc.select(combinedSelector)
                
                let foundURLs = downloadElements.compactMap { element -> (URL, String)? in
                    guard let hrefString = try? element.attr("href").nilIfEmpty,
                          let url = URL(string: hrefString) else { return nil }
                    
                    let filename = url.lastPathComponent
                    return (url, filename)
                }
                
                DispatchQueue.main.async {
                    guard !foundURLs.isEmpty else {
                        self.hideLoadingBannerAndShowAlert(title: "Error", message: "No valid video URLs found")
                        return
                    }
                    
                    if foundURLs.count == 1 {
                        completion(foundURLs[0].0)
                        return
                    }
                    let alertController = UIAlertController(title: "Select Video Format", message: "Choose which video to play", preferredStyle: .actionSheet)
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        if let popoverController = alertController.popoverPresentationController {
                            popoverController.sourceView = self.view
                            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                            popoverController.permittedArrowDirections = []
                        }
                    }
                    
                    for (url, filename) in foundURLs {
                        let action = UIAlertAction(title: filename, style: .default) { _ in
                            completion(url)
                        }
                        alertController.addAction(action)
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        self.hideLoadingBanner()
                    }
                    alertController.addAction(cancelAction)
                    
                    self.hideLoadingBanner {
                        self.present(alertController, animated: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error parsing HTML with SwiftSoup: \(error)")
                    self.hideLoadingBannerAndShowAlert(title: "Error", message: "Error extracting video URLs")
                }
            }
        }
    }
    
    func extractAsgoldURL(from documentString: String) -> URL? {
        let pattern = "\"player2\":\"!https://video\\.asgold\\.pp\\.ua/video/[^\"]*\""
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(documentString.startIndex..<documentString.endIndex, in: documentString)
            
            if let match = regex.firstMatch(in: documentString, options: [], range: range),
               let matchRange = Range(match.range, in: documentString) {
                var urlString = String(documentString[matchRange])
                urlString = urlString.replacingOccurrences(of: "\"player2\":\"!", with: "")
                urlString = urlString.replacingOccurrences(of: "\"", with: "")
                return URL(string: urlString)
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func extractAniVibeURL(from htmlContent: String) -> URL? {
        let pattern = #""url":"(.*?\.m3u8)""#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(htmlContent.startIndex..., in: htmlContent)
        guard let match = regex.firstMatch(in: htmlContent, range: range) else {
            return nil
        }
        
        if let urlRange = Range(match.range(at: 1), in: htmlContent) {
            let extractedURLString = String(htmlContent[urlRange])
            let unescapedURLString = extractedURLString.replacingOccurrences(of: "\\/", with: "/")
            return URL(string: unescapedURLString)
        }
        
        return nil
    }
    
    func extractStreamtapeQueryParameters(from htmlString: String, completion: @escaping (URL?) -> Void) {
        let streamtapePattern = #"https?://(?:www\.)?streamtape\.com/[^\s"']+"#
        guard let streamtapeRegex = try? NSRegularExpression(pattern: streamtapePattern, options: []),
              let streamtapeMatch = streamtapeRegex.firstMatch(in: htmlString, options: [], range: NSRange(location: 0, length: htmlString.utf16.count)),
              let streamtapeRange = Range(streamtapeMatch.range, in: htmlString) else {
            print("Streamtape URL not found in HTML.")
            completion(nil)
            return
        }
        
        let streamtapeURLString = String(htmlString[streamtapeRange])
        guard let streamtapeURL = URL(string: streamtapeURLString) else {
            print("Invalid Streamtape URL.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: streamtapeURL)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching Streamtape page: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            let responseHTML = String(data: data, encoding: .utf8) ?? ""
            let queryPattern = #"\?id=[^&]+&expires=\d+&ip=\w+&token=\S+(?=['"])"#
            guard let queryRegex = try? NSRegularExpression(pattern: queryPattern, options: []),
                  let queryMatch = queryRegex.firstMatch(in: responseHTML, options: [], range: NSRange(location: 0, length: responseHTML.utf16.count)),
                  let queryRange = Range(queryMatch.range, in: responseHTML) else {
                print("Query parameters not found.")
                completion(nil)
                return
            }
            
            let queryString = String(responseHTML[queryRange])
            let fullURL = "https://streamtape.com/get_video" + queryString
            
            completion(URL(string: fullURL))
        }.resume()
    }
    
    func anime3rbGetter(from documentString: String, completion: @escaping (URL?) -> Void) {
        guard let videoPlayerURL = extractAnime3rbVideoURL(from: documentString) else {
            completion(nil)
            return
        }
        
        extractAnime3rbMP4VideoURL(from: videoPlayerURL.absoluteString) { urls in
            DispatchQueue.main.async {
                completion(urls)
            }
        }
    }
    
    func extractAnime3rbVideoURL(from documentString: String) -> URL? {
        let pattern = "https://video\\.vid3rb\\.com/player/[\\w-]+\\?token=[\\w]+&(?:amp;)?expires=\\d+"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(documentString.startIndex..<documentString.endIndex, in: documentString)
            
            if let match = regex.firstMatch(in: documentString, options: [], range: range),
               let matchRange = Range(match.range, in: documentString) {
                let urlString = String(documentString[matchRange])
                
                let cleanedURLString = urlString.replacingOccurrences(of: "&amp;", with: "&")
                
                return URL(string: cleanedURLString)
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func extractAnime3rbMP4VideoURL(from urlString: String, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let pageContent = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let mp4Pattern = #"https?://[^\s<>"]+?\.mp4[^\s<>"]*"#
            
            guard let regex = try? NSRegularExpression(pattern: mp4Pattern, options: []) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let range = NSRange(pageContent.startIndex..<pageContent.endIndex, in: pageContent)
            if let match = regex.firstMatch(in: pageContent, options: [], range: range),
               let urlRange = Range(match.range, in: pageContent) {
                let urlString = String(pageContent[urlRange])
                let cleanedUrlString = urlString.replacingOccurrences(of: "amp;", with: "")
                let mp4Url = URL(string: cleanedUrlString)
                
                DispatchQueue.main.async {
                    completion(mp4Url)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(nil)
            }
        }.resume()
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
    
    func extractVidozaVideoURL(from htmlString: String, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let videoLinks = self.extractAllVideoLinks(from: htmlString)
            
            guard !videoLinks.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if videoLinks.count == 1 {
                self.processVideoURL(videoLinks[0], completion: completion)
                return
            }
            
            DispatchQueue.main.async {
                self.hideLoadingBanner {
                    self.showVideoSelectionDialog(for: videoLinks) { selectedLink in
                        if let selectedLink = selectedLink {
                            self.processVideoURL(selectedLink, completion: completion)
                        }
                    }
                }
            }
        }
    }
    
    private func showVideoSelectionDialog(for links: [VideoLink], completion: @escaping (VideoLink?) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topController = windowScene.windows.first?.rootViewController else {
                  completion(nil)
                  return
              }
        
        let alert = UIAlertController(title: "Select Video Source", message: "Choose your preferred host and language:", preferredStyle: .actionSheet)
        
        for link in links {
            let title = "\(link.host.description) - \(link.language.description)"
            let action = UIAlertAction(title: title, style: .default) { _ in
                completion(link)
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        }
        alert.addAction(cancelAction)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popover = alert.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        topController.present(alert, animated: true)
    }
    
    private func extractAllVideoLinks(from htmlString: String) -> [VideoLink] {
        var links: [VideoLink] = []
        
        let vidozaPattern = "<li[^>]*?data-lang-key=\"(\\d)\"[^>]*?>\\s*<div>\\s*<a[^>]*?href=\"(/redirect/[^\"]+)\"[^>]*?>\\s*<i class=\"icon Vidoza\""
        if let vidozaRegex = try? NSRegularExpression(pattern: vidozaPattern, options: [.dotMatchesLineSeparators]) {
            let vidozaMatches = vidozaRegex.matches(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString))
            links += extractLinks(from: vidozaMatches, in: htmlString, host: .vidoza)
        }
        let voePattern = "<li[^>]*?data-lang-key=\"(\\d)\"[^>]*?>\\s*<div>\\s*<a[^>]*?href=\"(/redirect/[^\"]+)\"[^>]*?>\\s*<i class=\"icon VOE\""
        if let voeRegex = try? NSRegularExpression(pattern: voePattern, options: [.dotMatchesLineSeparators]) {
            let voeMatches = voeRegex.matches(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString))
            links += extractLinks(from: voeMatches, in: htmlString, host: .voe)
        }
        
        return links
    }
    
    private func extractLinks(from matches: [NSTextCheckingResult], in htmlString: String, host: VideoHost) -> [VideoLink] {
        return matches.compactMap { match in
            guard let langKeyRange = Range(match.range(at: 1), in: htmlString),
                  let urlRange = Range(match.range(at: 2), in: htmlString),
                  let langKey = Int(htmlString[langKeyRange]),
                  let language = VideoLanguage(rawValue: langKey) else {
                      return nil
                  }
            
            let path = String(htmlString[urlRange])
            let fullURL = "https://aniworld.to\(path)"
            return VideoLink(url: fullURL, language: language, host: host)
        }
    }
    
    private func processVideoURL(_ videoLink: VideoLink, completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: videoLink.url) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let finalURL = (response as? HTTPURLResponse)?.url,
                  error == nil else {
                      DispatchQueue.main.async {
                          completion(nil)
                      }
                      return
                  }
            
            URLSession.shared.dataTask(with: finalURL) { [weak self] data, response, error in
                guard let data = data,
                      let htmlString = String(data: data, encoding: .utf8) else {
                          DispatchQueue.main.async {
                              completion(nil)
                          }
                          return
                      }
                
                switch videoLink.host {
                case .vidoza:
                    self?.extractVidozaDirectURL(from: htmlString, completion: completion)
                case .voe:
                    self?.extractVoeDirectURL(from: htmlString, completion: completion)
                }
            }.resume()
        }.resume()
    }
    
    private func extractVoeDirectURL(from htmlString: String, completion: @escaping (URL?) -> Void) {
        let redirectPattern = "window\\.location\\.href\\s*=\\s*'(https://[^/]+/e/\\w+)';"
        guard let redirectRegex = try? NSRegularExpression(pattern: redirectPattern),
              let redirectMatch = redirectRegex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let redirectURLRange = Range(redirectMatch.range(at: 1), in: htmlString) else {
                  DispatchQueue.main.async {
                      completion(nil)
                  }
                  return
              }
        
        let redirectURLString = String(htmlString[redirectURLRange])
        guard let redirectURL = URL(string: redirectURLString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        var request = URLRequest(url: redirectURL)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let redirectContent = String(data: data, encoding: .utf8) else {
                      DispatchQueue.main.async {
                          completion(nil)
                      }
                      return
                  }
            
            let hlsPattern = "'hls': '(.*?)'"
            guard let hlsRegex = try? NSRegularExpression(pattern: hlsPattern),
                  let hlsMatch = hlsRegex.firstMatch(in: redirectContent, range: NSRange(redirectContent.startIndex..., in: redirectContent)),
                  let hlsRange = Range(hlsMatch.range(at: 1), in: redirectContent) else {
                      DispatchQueue.main.async {
                          completion(nil)
                      }
                      return
                  }
            
            let hlsBase64 = String(redirectContent[hlsRange])
            guard let hlsData = Data(base64Encoded: hlsBase64),
                  let hlsLink = String(data: hlsData, encoding: .utf8),
                  let finalURL = URL(string: hlsLink) else {
                      DispatchQueue.main.async {
                          completion(nil)
                      }
                      return
                  }
            
            DispatchQueue.main.async {
                completion(finalURL)
            }
        }.resume()
    }
    
    private func extractVidozaDirectURL(from htmlString: String, completion: @escaping (URL?) -> Void) {
        let scriptPattern = "sourcesCode:.*?src: \"(.*?)\""
        guard let scriptRegex = try? NSRegularExpression(pattern: scriptPattern),
              let scriptMatch = scriptRegex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let urlRange = Range(scriptMatch.range(at: 1), in: htmlString),
              let videoURL = URL(string: String(htmlString[urlRange])) else {
                  DispatchQueue.main.async {
                      completion(nil)
                  }
                  return
              }
        
        DispatchQueue.main.async {
            completion(videoURL)
            print(videoURL)
        }
    }
}

class SubtitleDocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let completion: (URL?) -> Void
    
    init(completion: @escaping (URL?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion(urls.first)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion(nil)
    }
}
